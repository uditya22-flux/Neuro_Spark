import {
  badRequest,
  conflict,
  corsHeaders,
  internalError,
  ok,
  requireAuth,
} from "../_shared/auth.ts";
import { writeAudit } from "../_shared/audit.ts";
import {
  requireActiveConsent,
  requireOwnership,
  requireUuid,
  ValidationError,
} from "../_shared/validate.ts";
import {
  computeTrackAffinity,
  confidenceFor,
  evaluateAnswer,
  scoreResponse,
  SECTORS,
  type SectorId,
  type SourceType,
  survivingSectorsForLayer,
} from "../_shared/engine2.ts";

function numberField(value: unknown, field: string, fallback = 0): number {
  if (value === undefined || value === null) return fallback;
  const n = Number(value);
  if (!Number.isFinite(n)) {
    throw new ValidationError(`${field} must be numeric.`);
  }
  return n;
}

async function finalizeLayer1(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  sessionId: string,
  childId: string,
): Promise<{ complete: boolean }> {
  const { data: sessionTasks, error: taskError } = await svc
    .from("vertical_task_bank")
    .select("id, vertical_id")
    .eq("session_id", sessionId)
    .eq("child_id", childId)
    .eq("layer_number", 1)
    .eq("active", true);
  if (taskError) throw new Error("Layer 1 tasks could not be read.");

  const taskIds = new Set(
    (sessionTasks ?? []).map((row: { id: string }) => row.id),
  );
  const { data: telemetryRows, error: telemetryReadError } = await svc
    .from("sublayer_telemetry")
    .select(
      "task_id, vertical_id, isolation_score, accuracy, recovery, engagement, speed, telemetry_reference",
    )
    .eq("session_id", sessionId)
    .eq("child_id", childId);
  if (telemetryReadError) {
    throw new Error("Layer 1 telemetry could not be read.");
  }

  const answeredTaskIds = new Set(
    (telemetryRows ?? []).map((row: { task_id: string }) => row.task_id),
  );
  const complete = taskIds.size > 0 &&
    [...taskIds].every((id) => answeredTaskIds.has(id));
  if (!complete) return { complete };

  // Calculate sector scores across the 10 cognitive sectors
  const sectorScoreAccumulator: Record<string, number[]> = {};
  for (const row of telemetryRows ?? []) {
    const sec = row.vertical_id;
    if (!sectorScoreAccumulator[sec]) sectorScoreAccumulator[sec] = [];
    sectorScoreAccumulator[sec].push(Number(row.isolation_score));
  }

  const sectorScores: Record<string, number> = {};
  for (const sector of SECTORS) {
    const scores = sectorScoreAccumulator[sector] ?? [0.5];
    sectorScores[sector] = scores.reduce((a, b) => a + b, 0) / scores.length;
  }

  // Compute aggregate track affinity scores via mapping table
  const trackAffinity = computeTrackAffinity(sectorScores);

  // Rank sectors by score descending
  const rankedSectors = ([...SECTORS] as SectorId[]).sort(
    (a, b) => (sectorScores[b] ?? 0) - (sectorScores[a] ?? 0),
  );

  // Eliminate bottom 4 sectors for Layer 2 handoff (10 -> 6)
  const top6Sectors = survivingSectorsForLayer(2, rankedSectors);
  const droppedLayer2 = rankedSectors.filter((sec) => !top6Sectors.includes(sec));

  const eliminationTrail = [
    {
      layer: 1,
      surviving: SECTORS.length,
      active_sectors: [...SECTORS],
      dropped_sectors: [],
      track_affinity: trackAffinity,
    },
    {
      layer: 2,
      surviving: top6Sectors.length,
      active_sectors: top6Sectors,
      dropped_sectors: droppedLayer2,
      track_affinity: trackAffinity,
    },
  ];

  // Record Stage 2 handoff summary
  for (const sector of SECTORS) {
    await svc.from("stage2_handoffs").upsert({
      session_id: sessionId,
      child_id: childId,
      vertical_id: sector,
      isolation_score: sectorScores[sector] ?? 0.5,
      accuracy: sectorScores[sector] ?? 0.5,
      recovery: sectorScores[sector] ?? 0.5,
      engagement: sectorScores[sector] ?? 0.5,
      speed: sectorScores[sector] ?? 0.5,
      telemetry_reference: `layer1:${sessionId}:${sector}`,
    }, { onConflict: "session_id,vertical_id" });
  }

  // Initialize Layer Progression State for Engine 2.b Elimination Funnel
  const { error: stateError } = await svc.from("layer_progression_state").upsert({
    session_id: sessionId,
    child_id: childId,
    vertical_id: trackAffinity.leader,
    current_layer: 2,
    path_type: "standard",
    path_layers: [2, 3, 4, 5, 6, 7, 8, 9, 10],
    completed_layers: [1],
    status: "in_progress",
    support_level: 0,
    active_sectors: top6Sectors,
    sector_scores: sectorScores,
    track_affinity: trackAffinity,
    elimination_trail: eliminationTrail,
    winning_track: null,
    decider_required: false,
  }, { onConflict: "session_id,vertical_id" });

  if (stateError) {
    console.error("[finalizeLayer1] state error:", stateError.message);
  }

  const { error: sessionError } = await svc
    .from("layer1_sessions")
    .update({ status: "complete", completed_at: new Date().toISOString() })
    .eq("id", sessionId)
    .eq("child_id", childId);
  if (sessionError) throw new Error("Layer 1 session could not be completed.");
  return { complete };
}

function responseFor(
  sessionId: string,
  task: Record<string, unknown>,
  telemetry: Record<string, unknown>,
  complete: boolean,
  status = 201,
): Response {
  return ok({
    session_id: sessionId,
    vertical_id: task.vertical_id,
    accuracy: telemetry.accuracy,
    isolation_score: telemetry.isolation_score,
    layer1_complete: complete,
    next_phase: complete ? "deepening" : "layer1",
    idempotent: status === 200,
  }, status);
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db, serviceClient: svc } = auth;
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return badRequest("Request body must be valid JSON.");
  }

  try {
    const childId = requireUuid(body.child_id ?? body.childId, "child_id");
    const sessionId = requireUuid(
      body.session_id ?? body.sessionId,
      "session_id",
    );
    const taskId = requireUuid(body.task_id ?? body.taskId, "task_id");
    const responseId =
      body.response_id === undefined || body.response_id === null
        ? null
        : requireUuid(body.response_id, "response_id");
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const { data: session } = await svc
      .from("layer1_sessions")
      .select("id, status, expires_at")
      .eq("id", sessionId)
      .eq("child_id", childId)
      .eq("guardian_id", guardianId)
      .maybeSingle();
    if (!session) return conflict("Layer 1 session is not available.");

    const { data: task } = await svc
      .from("vertical_task_bank")
      .select(
        "id, child_id, session_id, vertical_id, source_type, item_payload",
      )
      .eq("id", taskId)
      .eq("session_id", sessionId)
      .eq("child_id", childId)
      .eq("layer_number", 1)
      .maybeSingle();
    if (!task) return conflict("Layer 1 task is not available.");

    const { data: existing, error: existingError } = await svc
      .from("sublayer_telemetry")
      .select("accuracy, isolation_score")
      .eq("session_id", sessionId)
      .eq("task_id", taskId)
      .maybeSingle();
    if (existingError) {
      return internalError("Layer 1 response could not be read.");
    }
    if (existing) {
      const { complete } = await finalizeLayer1(svc, sessionId, childId);
      return responseFor(
        sessionId,
        task as Record<string, unknown>,
        existing as Record<string, unknown>,
        complete,
        200,
      );
    }

    if (
      session.status !== "in_progress" ||
      new Date(String(session.expires_at)) <= new Date()
    ) {
      return conflict("Layer 1 session is no longer active.");
    }

    const response = body.response ?? body.user_response;
    const answerAccuracy = evaluateAnswer(
      task.item_payload as Record<string, unknown>,
      response,
    );
    const timing = (body.timing ?? {}) as Record<string, unknown>;
    const behavior = (body.behavior ?? {}) as Record<string, unknown>;
    const retryCount = Math.max(
      0,
      Math.floor(
        numberField(behavior.retry_count ?? body.recovery_count, "retry_count"),
      ),
    );
    const hintUsage = Math.max(
      0,
      Math.floor(
        numberField(
          behavior.hint_usage ?? (body.used_hint ? 1 : 0),
          "hint_usage",
        ),
      ),
    );
    const scored = scoreResponse(
      answerAccuracy,
      numberField(timing.latency_ms ?? body.latency_ms, "latency_ms"),
      retryCount,
      hintUsage,
      behavior.skipped === true || body.skipped === true,
      task.source_type as SourceType,
    );
    const telemetryReference =
      `layer1:${sessionId}:${task.vertical_id}:${Date.now()}`;
    const insertPayload: Record<string, unknown> = {
      session_id: sessionId,
      child_id: childId,
      task_id: taskId,
      vertical_id: task.vertical_id,
      source_type: task.source_type,
      accuracy: scored.accuracy,
      latency_ms: scored.latencyMs,
      recovery: scored.recovery,
      engagement: scored.engagement,
      speed: scored.speed,
      source_confidence: confidenceFor(task.source_type as SourceType),
      isolation_score: scored.isolationScore,
      telemetry_reference: telemetryReference,
    };
    if (responseId) insertPayload.response_id = responseId;
    const { data: inserted, error: telemetryError } = await svc.from(
      "sublayer_telemetry",
    ).insert(insertPayload).select("accuracy, isolation_score").maybeSingle();
    if (telemetryError || !inserted) {
      const { data: raceWinner } = await svc
        .from("sublayer_telemetry")
        .select("accuracy, isolation_score")
        .eq("session_id", sessionId)
        .eq("task_id", taskId)
        .maybeSingle();
      if (!raceWinner) {
        console.error(
          "[layer1-submit-response] telemetry:",
          telemetryError?.message,
        );
        return internalError("Layer 1 response could not be recorded.");
      }
      const { complete } = await finalizeLayer1(svc, sessionId, childId);
      return responseFor(
        sessionId,
        task as Record<string, unknown>,
        raceWinner as Record<string, unknown>,
        complete,
        200,
      );
    }

    const { complete } = await finalizeLayer1(svc, sessionId, childId);
    await writeAudit({
      action: "engine2.layer1_response_recorded",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        task_id: taskId,
        vertical_id: task.vertical_id,
        isolation_score: scored.isolationScore,
      },
    });
    return responseFor(
      sessionId,
      task as Record<string, unknown>,
      inserted as Record<string, unknown>,
      complete,
    );
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error(
      "[layer1-submit-response] unexpected:",
      (err as Error).message,
    );
    return internalError();
  }
});
