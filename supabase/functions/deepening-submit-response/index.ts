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
  evaluateAnswer,
  type LayerScore,
  modalityForExecution,
  pathLayers,
  reEvaluatePath,
  requiredExecutions,
  scoreResponse,
  type SourceType,
  supportTransition,
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
  verticalId: string,
): Promise<Record<string, unknown>> {
  const [
    executionsResult,
    stateResult,
    handoffResult,
    supportResult,
    consistencyResult,
  ] = await Promise.all([
    svc.from("layer_task_execution").select("*").eq("session_id", sessionId).eq(
      "vertical_id",
      verticalId,
    ).order("layer_number", { ascending: true }).order("execution_index", {
      ascending: true,
    }),
    svc.from("layer_progression_state").select(
      "path_type, path_history, completed_layers, support_level",
    ).eq("session_id", sessionId).eq("vertical_id", verticalId).maybeSingle(),
    svc.from("stage2_handoffs").select(
      "isolation_score, accuracy, recovery, engagement, speed, telemetry_reference",
    ).eq("session_id", sessionId).eq("vertical_id", verticalId).maybeSingle(),
    svc.from("support_ladder_log").select(
      "support_level, trigger_reason, outcome, created_at",
    ).eq("session_id", sessionId).eq("vertical_id", verticalId).order(
      "created_at",
    ),
    svc.from("consistency_window").select(
      "window_index, accuracy_stability_score, fatigue_score",
    ).eq("session_id", sessionId).eq("vertical_id", verticalId).order(
      "window_index",
    ),
  ]);
  const rows = (executionsResult.data ?? []) as Record<string, unknown>[];
  const layerScores: Record<string, unknown> = {};
  for (let layer = 2; layer <= 10; layer++) {
    const layerRows = rows.filter((row) => Number(row.layer_number) === layer);
    if (!layerRows.length) continue;
    const score = toLayerScore(layerRows);
    layerScores[`layer_${layer}`] = {
      ...score,
      composite_score: compositeScore(score),
      executions: layerRows.length,
      metric_values: layerRows.map((row) => row.metric_values),
    };
  }
  const supportEvents = (supportResult.data ?? []) as Record<string, unknown>[];
  const consistencyWindows = consistencyResult.data ?? [];
  const layerSeven = rows.filter((row) => Number(row.layer_number) === 7);
  const profile = {
    vertical_id: verticalId,
    layer1_isolation: handoffResult.data
      ? {
        isolation_score: Number(handoffResult.data.isolation_score),
        components: {
          accuracy: Number(handoffResult.data.accuracy),
          recovery: Number(handoffResult.data.recovery),
          engagement: Number(handoffResult.data.engagement),
          speed: Number(handoffResult.data.speed),
        },
      }
      : null,
    layer_scores: layerScores,
    path_history: stateResult.data?.path_history ?? [],
    final_path: stateResult.data?.path_type ?? null,
    completed_layers: stateResult.data?.completed_layers ?? [],
    support_ladder: {
      final_level: Number(stateResult.data?.support_level ?? 0),
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
    telemetry_reference: `deepening:${sessionId}:${verticalId}`,
  };
  const record = {
    session_id: sessionId,
    child_id: childId,
    vertical_id: verticalId,
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
      vertical_id: verticalId,
      deepening_profile: profile,
      telemetry_reference: profile.telemetry_reference,
    }, { onConflict: "session_id,vertical_id" }),
  ]);
  if (profileWrite.error || handoffWrite.error) {
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
    const verticalId = body.vertical_id ?? body.verticalId;
    if (
      typeof verticalId !== "string" ||
      !VERTICALS.includes(verticalId as VerticalId)
    ) {
      throw new ValidationError("vertical_id is required.");
    }
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
      .eq("session_id", sessionId).eq("child_id", childId).eq(
        "vertical_id",
        verticalId,
      ).maybeSingle();
    if (!state || state.status !== "in_progress") {
      return conflict("This vertical is not active.");
    }
    const { data: task } = await svc.from("vertical_task_bank").select("*")
      .eq("id", taskId).eq("session_id", sessionId).eq("child_id", childId).eq(
        "vertical_id",
        verticalId,
      ).maybeSingle();
    if (
      !task || task.id !== state.current_task_id ||
      Number(task.layer_number) !== Number(state.current_layer)
    ) {
      return conflict("This task is not active for the vertical.");
    }
    if (responseId) {
      const { data: replay } = await svc.from("layer_task_execution").select(
        "task_id",
      )
        .eq("session_id", sessionId).eq("response_id", responseId)
        .maybeSingle();
      if (replay) {
        if (replay.task_id !== taskId) {
          return conflict("response_id has already been used.");
        }
        return ok({
          session_id: sessionId,
          vertical_id: verticalId,
          idempotent: true,
          funnel_complete: false,
        });
      }
    }

    const { data: priorRows, error: priorError } = await svc.from(
      "layer_task_execution",
    ).select("*")
      .eq("session_id", sessionId).eq("task_id", taskId).order(
        "execution_index",
      );
    if (priorError) throw new Error("Task attempts could not be read.");
    const required = requiredExecutions(Number(task.layer_number));
    const executionIndex = (priorRows?.length ?? 0) + 1;
    if (executionIndex > required) {
      return conflict("All required presentations for this task are complete.");
    }

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
    const fullPayload = task.item_payload as Record<string, unknown>;
    const publicPayload = (fullPayload.public_payload ?? {}) as Record<
      string,
      unknown
    >;
    const protocol = (publicPayload.layer_protocol ?? {}) as Record<
      string,
      unknown
    >;
    const modality = modalityForExecution(
      Number(task.layer_number),
      executionIndex,
    );
    const metricValues = {
      objective: publicPayload.objective ?? null,
      instrumentation_only: publicPayload.instrumentation_only === true,
      strategy_shifts: Math.max(
        0,
        Math.floor(numberField(behavior.strategy_shifts, "strategy_shifts")),
      ),
      execution_index: executionIndex,
      required_executions: required,
      timing_budget_ms: Array.isArray(protocol.timing_budgets_ms)
        ? protocol.timing_budgets_ms[executionIndex - 1] ?? null
        : null,
      modality,
    };
    const storedResponse = boundedResponse(response);
    const insertPayload: Record<string, unknown> = {
      task_id: taskId,
      session_id: sessionId,
      child_id: childId,
      vertical_id: verticalId,
      layer_number: task.layer_number,
      source_type: task.source_type,
      modality,
      support_level: Number(state.support_level),
      execution_index: executionIndex,
      presentation_metadata: { modality, execution_index: executionIndex },
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
      metric_values: metricValues,
      response: typeof storedResponse === "object" && storedResponse !== null
        ? storedResponse
        : { value: storedResponse },
    };
    if (responseId) insertPayload.response_id = responseId;
    const { error: insertError } = await svc.from("layer_task_execution")
      .insert(insertPayload);
    if (insertError) return internalError("Response could not be recorded.");

    const transition = supportTransition(Number(state.support_level), {
      accuracy: scored.accuracy,
      latencyMs: scored.latencyMs,
      retryCount,
      skipped,
      path: state.path_type as "accelerated" | "standard" | "supported",
    });
    if (transition.reason && transition.outcome) {
      const { error: supportError } = await svc.from("support_ladder_log")
        .insert({
          session_id: sessionId,
          task_id: taskId,
          child_id: childId,
          vertical_id: verticalId,
          support_level: transition.level,
          trigger_reason: transition.reason,
          outcome: transition.outcome,
        });
      if (supportError) {
        throw new Error("Support ladder transition could not be saved.");
      }
    } else if (skipped && Number(state.support_level) === 5) {
      await svc.from("support_ladder_log").insert({
        session_id: sessionId,
        task_id: taskId,
        child_id: childId,
        vertical_id: verticalId,
        support_level: 5,
        trigger_reason: "support ladder exhausted before response",
        outcome: "abandoned",
      });
    }

    const allRows = [...((priorRows ?? []) as Record<string, unknown>[]), {
      accuracy: scored.accuracy,
      recovery: scored.recovery,
      engagement: scored.engagement,
      latency_ms: scored.latencyMs,
    }];
    const layerComplete = allRows.length >= required;
    let verticalComplete = false;
    if (layerComplete) {
      const { data: handoff } = await svc.from("stage2_handoffs")
        .select("isolation_score, recovery").eq("session_id", sessionId).eq(
          "vertical_id",
          verticalId,
        ).maybeSingle();
      if (!handoff) throw new Error("Layer 1 handoff could not be read.");
      if (Number(task.layer_number) === 9) {
        await saveConsistencyWindow(
          svc,
          sessionId,
          childId,
          verticalId,
          allRows,
        );
      }
      const latestScore = toLayerScore(allRows);
      const reroute = reEvaluatePath({
        isolationScore: Number(handoff.isolation_score),
        recovery: Number(handoff.recovery),
      }, latestScore);
      const completed = new Set<number>(
        Array.isArray(state.completed_layers)
          ? state.completed_layers.map((value: unknown) => Number(value))
          : [],
      );
      completed.add(Number(task.layer_number));
      const nextLayers = pathLayers(reroute.path);
      const nextLayer = nextLayers.find((layer) =>
        layer > Number(task.layer_number) && !completed.has(layer)
      );
      const history = Array.isArray(state.path_history)
        ? state.path_history
        : [];
      history.push({
        layer: Number(task.layer_number),
        path: reroute.path,
        previous_path: state.path_type,
        routing_signal: reroute.routingSignal,
        reason: reroute.reason,
        created_at: new Date().toISOString(),
      });
      verticalComplete = nextLayer === undefined;
      const { error: stateWriteError } = await svc.from(
        "layer_progression_state",
      ).update({
        current_layer: verticalComplete ? Number(task.layer_number) : nextLayer,
        path_type: reroute.path,
        path_layers: nextLayers,
        path_history: history,
        completed_layers: [...completed].sort((a, b) => a - b),
        support_level: transition.level,
        current_task_id: null,
        status: verticalComplete ? "funnel_complete" : "in_progress",
        updated_at: new Date().toISOString(),
      }).eq("id", state.id);
      if (stateWriteError) {
        throw new Error("Deepening progression could not be updated.");
      }
      if (verticalComplete) {
        await createDeepeningProfile(svc, sessionId, childId, verticalId);
      }
    } else {
      const { error: stateWriteError } = await svc.from(
        "layer_progression_state",
      ).update({
        support_level: transition.level,
        updated_at: new Date().toISOString(),
      }).eq("id", state.id);
      if (stateWriteError) {
        throw new Error("Support state could not be updated.");
      }
    }

    const { count: remaining } = await svc.from("layer_progression_state")
      .select("id", { count: "exact", head: true })
      .eq("session_id", sessionId).eq("child_id", childId).eq(
        "status",
        "in_progress",
      );
    const funnelComplete = (remaining ?? 0) === 0;
    await writeAudit({
      action: "engine2.deepening_response_recorded",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        vertical_id: verticalId,
        layer: task.layer_number,
        execution_index: executionIndex,
        layer_complete: layerComplete,
      },
    });
    return ok({
      session_id: sessionId,
      vertical_id: verticalId,
      layer_complete: layerComplete,
      vertical_complete: verticalComplete,
      funnel_complete: funnelComplete,
      support_level: transition.level,
      required_executions: required,
      execution_index: executionIndex,
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
