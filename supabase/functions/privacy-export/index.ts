import {
  badRequest,
  corsHeaders,
  internalError,
  ok,
  requireAuth,
} from "../_shared/auth.ts";
import { writeAudit } from "../_shared/audit.ts";
import {
  optionalUuid,
  requireOwnership,
  ValidationError,
} from "../_shared/validate.ts";

// Fields that must never appear in an export payload
const EXCLUDED_INTERNAL_FIELDS = [
  "raw_text",
  "fcm_token",
  "fcm_token_updated_at",
];

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db } = auth;

  let body: Record<string, unknown>;
  try {
    body = await req.json().catch(() => ({}));
  } catch {
    body = {};
  }

  try {
    const childId = optionalUuid(body.childId, "childId");
    if (childId) await requireOwnership(db, guardianId, childId);

    // ---- Collect authorized records ----------------------------------------

    const [
      profileRes,
      consentsRes,
      verificationsRes,
      childrenRes,
    ] = await Promise.all([
      db.from("profiles").select(
        "id, role, preferred_name, created_at, updated_at",
      ).eq("id", guardianId).single(),
      db.from("guardian_consents").select(
        "id, consent_version_id, status, accepted_at, revoked_at",
      ).eq("guardian_id", guardianId),
      db.from("parent_verifications").select(
        "id, method, status, verified_at, created_at",
      ).eq("guardian_id", guardianId),
      childId
        ? db.from("children").select(
          "id, preferred_name, birth_year, created_at",
        ).eq("id", childId).eq("guardian_id", guardianId)
        : db.from("children").select(
          "id, preferred_name, birth_year, created_at",
        ).eq("guardian_id", guardianId),
    ]);

    const resolvedChildIds: string[] = childId
      ? [childId]
      : (childrenRes.data ?? []).map((c: { id: string }) => c.id);

    let sessions: unknown[] = [];
    let intakes: unknown[] = [];
    let sensoryConfigs: unknown[] = [];
    let purgeRequests: unknown[] = [];
    let engine2: Record<string, unknown[]> = {
      layer1Sessions: [],
      stage2Handoffs: [],
      sublayerTelemetry: [],
      progression: [],
      taskExecutions: [],
      supportLadder: [],
      consistencyWindows: [],
      deepeningProfiles: [],
    };

    if (resolvedChildIds.length > 0) {
      const [
        sessRes,
        intakeRes,
        sensoryRes,
        layer1Res,
        handoffRes,
        telemetryRes,
        progressionRes,
        executionRes,
        supportRes,
        consistencyRes,
        profileRes,
      ] = await Promise.all([
        db.from("sessions").select(
          "id, child_id, expires_at, revoked_at, created_at",
        ).in("child_id", resolvedChildIds),
        // Return redacted_text only — raw_text is explicitly excluded
        db.from("discovery_intakes").select(
          "id, child_id, redacted_text, expires_at, created_at",
        ).in("child_id", resolvedChildIds),
        db.from("sensory_configurations").select(
          "id, child_id, config_version, key, proposed_value, status, reviewed_at, active",
        ).in("child_id", resolvedChildIds),
        db.from("layer1_sessions").select(
          "id, child_id, status, created_at, completed_at, expires_at",
        ).in("child_id", resolvedChildIds),
        db.from("stage2_handoffs").select(
          "id, session_id, child_id, vertical_id, isolation_score, accuracy, recovery, engagement, speed, telemetry_reference, created_at",
        ).in("child_id", resolvedChildIds),
        db.from("sublayer_telemetry").select(
          "id, response_id, session_id, child_id, task_id, vertical_id, source_type, accuracy, latency_ms, recovery, engagement, speed, source_confidence, isolation_score, telemetry_reference, expires_at, created_at",
        ).in("child_id", resolvedChildIds),
        db.from("layer_progression_state").select(
          "id, session_id, child_id, vertical_id, current_layer, path_type, path_layers, completed_layers, status, support_level, updated_at",
        ).in("child_id", resolvedChildIds),
        db.from("layer_task_execution").select(
          "id, response_id, task_id, session_id, child_id, vertical_id, layer_number, source_type, modality, support_level, accuracy, latency_ms, recovery, engagement, retry_count, hint_usage, answer_changes, skipped, metric_values, expires_at, created_at",
        ).in("child_id", resolvedChildIds),
        db.from("support_ladder_log").select(
          "id, session_id, task_id, child_id, vertical_id, support_level, trigger_reason, outcome, created_at",
        ).in("child_id", resolvedChildIds),
        db.from("consistency_window").select(
          "id, session_id, child_id, vertical_id, window_index, accuracy_stability_score, fatigue_score, created_at",
        ).in("child_id", resolvedChildIds),
        db.from("deepening_profiles").select(
          "id, session_id, child_id, vertical_id, profile, telemetry_reference, created_at",
        ).in("child_id", resolvedChildIds),
      ]);
      sessions = sessRes.data ?? [];
      intakes = intakeRes.data ?? [];
      sensoryConfigs = sensoryRes.data ?? [];
      engine2 = {
        layer1Sessions: layer1Res.data ?? [],
        stage2Handoffs: handoffRes.data ?? [],
        sublayerTelemetry: telemetryRes.data ?? [],
        progression: progressionRes.data ?? [],
        taskExecutions: executionRes.data ?? [],
        supportLadder: supportRes.data ?? [],
        consistencyWindows: consistencyRes.data ?? [],
        deepeningProfiles: profileRes.data ?? [],
      };
    }

    const purgeRes = await db
      .from("purge_requests")
      .select("id, child_id, status, requested_at, completed_at")
      .eq("guardian_id", guardianId);
    purgeRequests = purgeRes.data ?? [];

    // ---- Build export — adult_exploratory_note is intentionally excluded -----
    const exportPayload = {
      exportedAt: new Date().toISOString(),
      guardian: profileRes.data,
      consents: consentsRes.data ?? [],
      parentVerifications: verificationsRes.data ?? [],
      children: childrenRes.data ?? [],
      sessions,
      // Only redacted intake text is included
      discoveryIntakes: intakes,
      sensoryConfigurations: sensoryConfigs,
      engine2,
      purgeRequests,
      // adult_exploratory_note: intentionally omitted from export for child-safety compliance
    };

    // Audit: log that an export was requested, NOT what was exported
    await writeAudit({
      action: "privacy_export_requested",
      guardianId,
      childId,
      meta: {
        scoped_to_child: !!childId,
        record_counts: {
          children: (childrenRes.data ?? []).length,
          sessions: sessions.length,
          intakes: intakes.length,
        },
      },
    });

    return ok(exportPayload);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error("[privacy-export] unexpected:", (err as Error).message);
    return internalError();
  }
});
