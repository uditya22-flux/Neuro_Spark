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
  evaluateAnswer,
  normalizeModality,
  pathLayers,
  type PathType,
  requiredExecutions,
  scoreResponse,
  type SourceType,
  supportTransition,
} from "../_shared/engine2.ts";

function numberField(value: unknown, field: string, fallback = 0): number {
  if (value === undefined || value === null) return fallback;
  const n = Number(value);
  if (!Number.isFinite(n)) {
    throw new ValidationError(`${field} must be numeric.`);
  }
  return n;
}

function average(values: number[]): number {
  return values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0;
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

async function createProfile(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  sessionId: string,
  childId: string,
  verticalId: string,
): Promise<Record<string, unknown>> {
  const { data: executions } = await svc.from("layer_task_execution").select(
    "*",
  ).eq("session_id", sessionId).eq("vertical_id", verticalId).order(
    "layer_number",
    { ascending: true },
  );
  const rows = executions ?? [];
  const layerScores: Record<string, unknown> = {};
  for (let layer = 2; layer <= 10; layer++) {
    const layerRows = rows.filter((row: Record<string, unknown>) =>
      row.layer_number === layer
    );
    if (layerRows.length) {
      layerScores[`layer_${layer}`] = {
        accuracy: average(
          layerRows.map((r: Record<string, unknown>) => Number(r.accuracy)),
        ),
        recovery: average(
          layerRows.map((r: Record<string, unknown>) => Number(r.recovery)),
        ),
        engagement: average(
          layerRows.map((r: Record<string, unknown>) => Number(r.engagement)),
        ),
        speed: average(
          layerRows.map((r: Record<string, unknown>) =>
            1 - Math.min(Number(r.latency_ms), 60_000) / 60_000
          ),
        ),
        metric_values: layerRows.map((r: Record<string, unknown>) =>
          r.metric_values
        ),
      };
    }
  }
  const modalityCounts = new Map<string, number>();
  for (const row of rows) {
    modalityCounts.set(
      row.modality,
      (modalityCounts.get(row.modality) ?? 0) + 1,
    );
  }
  const modalityPreference =
    [...modalityCounts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ??
      "visual";
  const supportLevels = rows.map((r: Record<string, unknown>) =>
    Number(r.support_level)
  );
  const profile = {
    vertical_id: verticalId,
    path_type: "dynamic",
    layer_scores: layerScores,
    support_ladder_summary: {
      avg_support_level: average(supportLevels),
      modality_preference: modalityPreference,
    },
    telemetry_reference: `deepening:${sessionId}:${verticalId}`,
  };
  await svc.from("deepening_profiles").upsert({
    session_id: sessionId,
    child_id: childId,
    vertical_id: verticalId,
    profile,
    telemetry_reference: profile.telemetry_reference,
  }, { onConflict: "session_id,vertical_id" });
  return profile;
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
      verticalId !== "calendar_genius" && verticalId !== "constellation_mapper"
    ) throw new ValidationError("vertical_id is required.");
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data: layer1Session } = await svc
      .from("layer1_sessions")
      .select("status, expires_at")
      .eq("id", sessionId)
      .eq("child_id", childId)
      .maybeSingle();
    if (
      !layer1Session || layer1Session.status !== "complete" ||
      new Date(String(layer1Session.expires_at)) <= new Date()
    ) {
      return conflict("The orchestration session is no longer active.");
    }
    const { data: state } = await svc.from("global_progression_state").select(
      "*",
    ).eq("session_id", sessionId).eq("child_id", childId).maybeSingle();
    
    if (!state) return conflict("Deepening progression is not initialized.");
    
    const { data: task } = await svc.from("vertical_task_bank").select("*").eq(
      "id",
      taskId,
    ).eq("session_id", sessionId).eq("child_id", childId).eq(
      "vertical_id",
      verticalId,
    ).maybeSingle();
    if (!task) return conflict("This task is not available.");

    if (responseId) {
      const { data: existingResponse } = await svc
        .from("layer_task_execution")
        .select("task_id, layer_number, accuracy, support_level")
        .eq("session_id", sessionId)
        .eq("child_id", childId)
        .eq("response_id", responseId)
        .maybeSingle();
      if (existingResponse) {
        if (existingResponse.task_id !== taskId) {
          return conflict("response_id has already been used.");
        }
        return ok({
          session_id: sessionId,
          layer_complete: true,
          funnel_complete: state.status === "funnel_complete",
          idempotent: true,
        }, 200);
      }
    }
    
    const activeTasks = (state.active_tasks as string[]) ?? [];
    if (!activeTasks.includes(taskId)) {
      return conflict("This task is not an active task for the current layer.");
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
    const storedResponse = boundedResponse(response);
    const accuracy = evaluateAnswer(
      task.item_payload as Record<string, unknown>,
      response,
    );
    const scored = scoreResponse(
      accuracy,
      numberField(timing.latency_ms ?? body.latency_ms, "latency_ms"),
      retryCount,
      hintUsage,
      skipped,
      task.source_type as SourceType,
    );
    
    const suppliedSupport = Math.max(
      0,
      Math.min(
        5,
        Math.floor(
          numberField(
            body.support_level_used ?? body.supportLevel,
            "support_level_used",
            0,
          ),
        ),
      ),
    );
    
    const metricValues: Record<string, unknown> = {
      objective: (task.item_payload as Record<string, unknown>).public_payload
        ? ((task.item_payload as Record<string, unknown>)
          .public_payload as Record<string, unknown>).objective
        : null,
    };
    
    const modality = normalizeModality(body.modality);
    
    const executionPayload: Record<string, unknown> = {
      task_id: taskId,
      session_id: sessionId,
      child_id: childId,
      vertical_id: verticalId,
      layer_number: task.layer_number,
      source_type: task.source_type,
      modality,
      support_level: suppliedSupport,
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
    if (responseId) executionPayload.response_id = responseId;
    const { error: executionError } = await svc.from("layer_task_execution")
      .insert(executionPayload);
    if (executionError) {
      return internalError("Response could not be recorded.");
    }
    
    const completedTasks = new Set((state.completed_tasks as string[]) ?? []);
    completedTasks.add(taskId);
    
    const allCompleted = activeTasks.every(id => completedTasks.has(id));
    let funnelComplete = false;
    
    if (allCompleted) {
      const nextLayer = state.current_layer + 1;
      funnelComplete = nextLayer > 10;
      
      const { error: progressionError } = await svc.from(
        "global_progression_state",
      ).update({
        current_layer: funnelComplete ? state.current_layer : nextLayer,
        status: funnelComplete ? "funnel_complete" : "in_progress",
        active_tasks: [],
        completed_tasks: [],
        orchestration_plan: {},
        updated_at: new Date().toISOString(),
      }).eq("id", state.id);
      
      if (progressionError) {
        return internalError("Global deepening progression could not be updated.");
      }
      
      if (funnelComplete) {
         // Create profiles for all involved verticals
         const { data: verticals } = await svc.from("layer_task_execution").select("vertical_id").eq("session_id", sessionId);
         const distinctVerticals = [...new Set((verticals ?? []).map(v => v.vertical_id))];
         for (const v of distinctVerticals) {
           await createProfile(svc, sessionId, childId, String(v));
         }
      }
    } else {
      await svc.from("global_progression_state").update({
        completed_tasks: Array.from(completedTasks),
        updated_at: new Date().toISOString(),
      }).eq("id", state.id);
    }
    
    await writeAudit({
      action: "engine2.deepening_response_recorded",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        vertical_id: verticalId,
        layer: task.layer_number,
        layer_complete: allCompleted,
      },
    });
    
    return ok({
      session_id: sessionId,
      funnel_complete: funnelComplete,
    }, 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error(
      "[deepening-submit-response] unexpected:",
      (err as Error).message,
    );
    return internalError();
  }
});
