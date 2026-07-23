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
  compositeScore,
  computeTrackAffinity,
  evaluateAnswer,
  type LayerScore,
  modalityForExecution,
  pathLayers,
  reEvaluatePath,
  requiredExecutions,
  scoreResponse,
  SECTORS,
  type SectorId,
  type SourceType,
  supportTransition,
  survivingSectorsForLayer,
  TrackId,
  type VerticalId,
  VERTICALS,
} from "../_shared/engine2.ts";

const clamp = (value: number, min = 0, max = 1): number =>
  Math.max(min, Math.min(max, value));

function numberField(value: unknown, field: string, fallback = 0): number {
  if (value === undefined || value === null) return fallback;
  const number = Number(value);
  if (!Number.isFinite(number)) {
    throw new ValidationError(`${field} must be numeric.`);
  }
  return number;
}

function boundedResponse(value: unknown): unknown {
  if (
    value === undefined || value === null || typeof value === "string" ||
    typeof value === "number" || typeof value === "boolean"
  ) {
    if (typeof value === "string" && value.length > 2_000) {
      throw new ValidationError("response must be at most 2000 characters.");
    }
    return value;
  }
  const serialized = JSON.stringify(value);
  if (serialized.length > 4_000) {
    throw new ValidationError("response is too large.");
  }
  return value;
}

const average = (values: number[]): number =>
  values.length
    ? values.reduce((total, value) => total + value, 0) / values.length
    : 0;

function toLayerScore(rows: Record<string, unknown>[]): LayerScore {
  return {
    accuracy: average(rows.map((row) => Number(row.accuracy))),
    recovery: average(rows.map((row) => Number(row.recovery))),
    engagement: average(rows.map((row) => Number(row.engagement))),
    speed: average(
      rows.map((row) => 1 - Math.min(Number(row.latency_ms), 60_000) / 60_000),
    ),
  };
}

async function createDeepeningProfile(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  sessionId: string,
  childId: string,
  winningTrack: string,
  state: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const [
    executionsResult,
    supportResult,
    consistencyResult,
  ] = await Promise.all([
    svc.from("layer_task_execution").select("*").eq("session_id", sessionId).order("layer_number", { ascending: true }).order("execution_index", {
      ascending: true,
    }),
    svc.from("support_ladder_log").select(
      "support_level, trigger_reason, outcome, created_at",
    ).eq("session_id", sessionId).order("created_at"),
    svc.from("consistency_window").select(
      "window_index, accuracy_stability_score, fatigue_score",
    ).eq("session_id", sessionId).order("window_index"),
  ]);

  const rows = (executionsResult.data ?? []) as Record<string, unknown>[];
  const layerScores: Record<string, unknown> = {};
  for (let layer = 1; layer <= 10; layer++) {
    const layerRows = rows.filter((row) => Number(row.layer_number) === layer);
    if (!layerRows.length) continue;
    const score = toLayerScore(layerRows);
    layerScores[`layer_${layer}`] = {
      ...score,
      composite_score: compositeScore(score),
      executions: layerRows.length,
    };
  }

  const supportEvents = (supportResult.data ?? []) as Record<string, unknown>[];
  const consistencyWindows = consistencyResult.data ?? [];
  const layerSeven = rows.filter((row) => Number(row.layer_number) === 7);

  const profile = {
    winning_track: winningTrack,
    vertical_id: winningTrack,
    sector_scores: state.sector_scores ?? {},
    track_affinity_final: state.track_affinity ?? {},
    elimination_trail: state.elimination_trail ?? [],
    decider_required: state.decider_required ?? false,
    layer_scores: layerScores,
    path_history: state.path_history ?? [],
    completed_layers: state.completed_layers ?? [],
    support_ladder: {
      final_level: Number(state.support_level ?? 0),
      transitions: supportEvents,
      average_level: average(rows.map((row) => Number(row.support_level))),
    },
    behavioral_signals: {
      retries: rows.map((row) => Number(row.retry_count)),
      hint_use_count: rows.reduce(
        (total, row) => total + Number(row.hint_usage),
        0,
      ),
      answer_changes: rows.reduce(
        (total, row) => total + Number(row.answer_changes),
        0,
      ),
      skipped_count: rows.filter((row) => row.skipped === true).length,
    },
    transfer_score: layerSeven.length
      ? compositeScore(toLayerScore(layerSeven))
      : null,
    consistency: consistencyWindows,
    telemetry_reference: `deepening:${sessionId}:${winningTrack}`,
  };

  const record = {
    session_id: sessionId,
    child_id: childId,
    vertical_id: winningTrack,
    profile,
    telemetry_reference: profile.telemetry_reference,
  };

  const [profileWrite, handoffWrite] = await Promise.all([
    svc.from("deepening_profiles").upsert(record, {
      onConflict: "session_id,vertical_id",
    }),
    svc.from("stage3_handoffs").upsert({
      session_id: sessionId,
      child_id: childId,
      vertical_id: winningTrack,
      deepening_profile: profile,
      telemetry_reference: profile.telemetry_reference,
    }, { onConflict: "session_id,vertical_id" }),
  ]);

  if (profileWrite.error || handoffWrite.error) {
    console.error("[createDeepeningProfile] write error:", profileWrite.error?.message, handoffWrite.error?.message);
    throw new Error("Deepening profile could not be saved.");
  }
  return profile;
}

async function saveConsistencyWindow(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  sessionId: string,
  childId: string,
  verticalId: string,
  rows: Record<string, unknown>[],
): Promise<void> {
  const accuracy = rows.map((row) => Number(row.accuracy));
  const mean = average(accuracy);
  const variance = average(accuracy.map((value) => (value - mean) ** 2));
  const stability = clamp(1 - Math.sqrt(variance));
  const fatigue = clamp(
    accuracy.length > 1 ? accuracy[0] - accuracy[accuracy.length - 1] : 0,
  );
  const { error } = await svc.from("consistency_window").upsert({
    session_id: sessionId,
    child_id: childId,
    vertical_id: verticalId,
    window_index: 0,
    accuracy_stability_score: stability,
    fatigue_score: fatigue,
  }, { onConflict: "session_id,vertical_id,window_index" });
  if (error) throw new Error("Consistency window could not be saved.");
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
    const verticalId = (body.vertical_id ?? body.verticalId ?? "pattern_recognition") as VerticalId;

    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const { data: session } = await svc.from("layer1_sessions")
      .select("status, expires_at").eq("id", sessionId).eq("child_id", childId)
      .maybeSingle();
    if (
      !session || session.status !== "complete" ||
      new Date(String(session.expires_at)) <= new Date()
    ) {
      return conflict("The deepening session is no longer active.");
    }

    const { data: state } = await svc.from("layer_progression_state").select(
      "*",
    )
      .eq("session_id", sessionId).eq("child_id", childId)
      .maybeSingle();

    if (!state || state.status !== "in_progress") {
      return conflict("This session state is not active.");
    }

    const { data: task } = await svc.from("vertical_task_bank").select("*")
      .eq("id", taskId).eq("session_id", sessionId).eq("child_id", childId)
      .maybeSingle();

    if (!task) {
      return conflict("This task is not active.");
    }

    if (responseId) {
      const { data: replay } = await svc.from("layer_task_execution").select(
        "task_id",
      )
        .eq("session_id", sessionId).eq("response_id", responseId)
        .maybeSingle();
      if (replay) {
        return ok({
          session_id: sessionId,
          vertical_id: verticalId,
          idempotent: true,
          funnel_complete: false,
        });
      }
    }

    const currentLayer = Number(task.layer_number);
    const required = requiredExecutions(currentLayer);

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
    const skipped = behavior.skipped === true || body.skipped === true;
    const response = body.response ?? body.user_response;
    const scored = scoreResponse(
      evaluateAnswer(task.item_payload as Record<string, unknown>, response),
      numberField(timing.latency_ms ?? body.latency_ms, "latency_ms"),
      retryCount,
      hintUsage,
      skipped,
      task.source_type as SourceType,
    );

    const storedResponse = boundedResponse(response);
    const insertPayload: Record<string, unknown> = {
      task_id: taskId,
      session_id: sessionId,
      child_id: childId,
      vertical_id: verticalId,
      layer_number: currentLayer,
      source_type: task.sourceType ?? "created",
      modality: task.modality ?? "visual",
      support_level: Number(state.support_level),
      execution_index: 1,
      presentation_metadata: { modality: task.modality ?? "visual" },
      accuracy: scored.accuracy,
      latency_ms: scored.latencyMs,
      recovery: scored.recovery,
      engagement: scored.engagement,
      retry_count: retryCount,
      hint_usage: hintUsage,
      answer_changes: Math.max(
        0,
        Math.floor(numberField(behavior.answer_changes, "answer_changes")),
      ),
      skipped,
      metric_values: { score: scored.isolationScore },
      response: typeof storedResponse === "object" && storedResponse !== null
        ? storedResponse
        : { value: storedResponse },
    };

    if (responseId) insertPayload.response_id = responseId;
    const { error: insertError } = await svc.from("layer_task_execution")
      .insert(insertPayload);
    if (insertError) {
      console.error("[deepening-submit-response] insertError:", insertError.message);
      return internalError("Response could not be recorded.");
    }

    const transition = supportTransition(Number(state.support_level), {
      accuracy: scored.accuracy,
      latencyMs: scored.latencyMs,
      retryCount,
      skipped,
      path: state.path_type as "accelerated" | "standard" | "supported",
    });

    // Update sector scores if this was a sector probe
    const sectorScores: Record<string, number> = {
      ...(state.sector_scores as Record<string, number> ?? {}),
    };
    if (SECTORS.includes(verticalId as SectorId)) {
      sectorScores[verticalId] = scored.isolationScore;
    }
    const updatedAffinity = computeTrackAffinity(sectorScores);

    // Check layer completion
    const { data: layerExecutions } = await svc.from("layer_task_execution")
      .select("id, vertical_id, accuracy")
      .eq("session_id", sessionId)
      .eq("layer_number", currentLayer);

    const layerComplete = (layerExecutions?.length ?? 0) >= required || (currentLayer >= 2 && (layerExecutions?.length ?? 0) >= (state.active_sectors?.length ?? 1));

    let funnelComplete = false;
    let winningTrack: TrackId | null = null;

    if (layerComplete) {
      if (currentLayer === 9) {
        await saveConsistencyWindow(
          svc,
          sessionId,
          childId,
          verticalId,
          (layerExecutions ?? []) as Record<string, unknown>[],
        );
      }

      if (currentLayer >= 10) {
        // Resolve Layer 10 Decision
        funnelComplete = true;
        if (state.decider_required) {
          // Compare decider performance between side-by-side tracks
          const calExec = layerExecutions?.find((row) => row.vertical_id === "calendar_genius");
          const constExec = layerExecutions?.find((row) => row.vertical_id === "constellation_mapper");

          const calAcc = Number(calExec?.accuracy ?? 0);
          const constAcc = Number(constExec?.accuracy ?? 0);
          winningTrack = calAcc >= constAcc ? "calendar_genius" : "constellation_mapper";
        } else {
          winningTrack = updatedAffinity.leader;
        }

        const completed = [...(state.completed_layers ?? []), currentLayer];
        await svc.from("layer_progression_state").update({
          status: "funnel_complete",
          completed_layers: completed,
          winning_track: winningTrack,
          sector_scores: sectorScores,
          track_affinity: updatedAffinity,
          updated_at: new Date().toISOString(),
        }).eq("id", state.id);

        // Hand off Stage 3 Deepening Profile with full elimination trail to Engine 3
        await createDeepeningProfile(svc, sessionId, childId, winningTrack, {
          ...state,
          winning_track: winningTrack,
          sector_scores: sectorScores,
          track_affinity: updatedAffinity,
        });
      } else {
        // Advance layer and apply sector elimination schedule
        const nextLayer = currentLayer + 1;
        const currentActive = (state.active_sectors ?? [...SECTORS]) as SectorId[];
        const rankedCurrent = [...currentActive].sort(
          (a, b) => (sectorScores[b] ?? 0) - (sectorScores[a] ?? 0),
        );

        const nextSurviving = survivingSectorsForLayer(nextLayer, rankedCurrent);
        const droppedSectors = currentActive.filter((sec) => !nextSurviving.includes(sec));

        const eliminationTrail = Array.isArray(state.elimination_trail)
          ? [...state.elimination_trail]
          : [];
        eliminationTrail.push({
          layer: nextLayer,
          surviving: nextSurviving.length,
          active_sectors: nextSurviving,
          dropped_sectors: droppedSectors,
          track_affinity: updatedAffinity,
        });

        const completed = [...(state.completed_layers ?? []), currentLayer];
        await svc.from("layer_progression_state").update({
          current_layer: nextLayer,
          active_sectors: nextSurviving,
          sector_scores: sectorScores,
          track_affinity: updatedAffinity,
          elimination_trail: eliminationTrail,
          completed_layers: completed,
          support_level: transition.level,
          updated_at: new Date().toISOString(),
        }).eq("id", state.id);
      }
    }

    await writeAudit({
      action: "engine2.deepening_response_recorded",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        vertical_id: verticalId,
        layer: currentLayer,
        layer_complete: layerComplete,
        funnel_complete: funnelComplete,
        winning_track: winningTrack,
      },
    });

    return ok({
      session_id: sessionId,
      vertical_id: verticalId,
      layer_complete: layerComplete,
      funnel_complete: funnelComplete,
      winning_track: winningTrack,
      support_level: transition.level,
    }, 201);
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    console.error(
      "[deepening-submit-response] unexpected:",
      (error as Error).message,
    );
    return internalError();
  }
});
