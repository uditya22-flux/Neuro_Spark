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
  confidenceFor,
  evaluateAnswer,
  scoreResponse,
  type SourceType,
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
    .select("vertical_id")
    .eq("session_id", sessionId)
    .eq("child_id", childId)
    .eq("layer_number", 1)
    .eq("active", true);
  if (taskError) throw new Error("Layer 1 tasks could not be read.");

  const expectedVerticals = new Set(
    (sessionTasks ?? []).map((row: { vertical_id: string }) => row.vertical_id),
  );
  const { data: allVerticals, error: telemetryReadError } = await svc
    .from("sublayer_telemetry")
    .select(
      "vertical_id, isolation_score, accuracy, recovery, engagement, speed, telemetry_reference",
    )
    .eq("session_id", sessionId)
    .eq("child_id", childId);
  if (telemetryReadError) {
    throw new Error("Layer 1 telemetry could not be read.");
  }

  const latest = new Map<string, Record<string, unknown>>();
  for (const row of allVerticals ?? []) {
    latest.set(row.vertical_id, row as Record<string, unknown>);
  }
  const complete = expectedVerticals.size > 0 &&
    [...expectedVerticals].every((vertical) => latest.has(vertical));
  if (!complete) return { complete };

  for (const row of latest.values()) {
    const { error } = await svc.from("stage2_handoffs").upsert({
      session_id: sessionId,
      child_id: childId,
      vertical_id: row.vertical_id,
      isolation_score: row.isolation_score,
      accuracy: row.accuracy,
      recovery: row.recovery,
      engagement: row.engagement,
      speed: row.speed,
      telemetry_reference: row.telemetry_reference,
    }, { onConflict: "session_id,vertical_id" });
    if (error) throw new Error("Layer 1 handoff could not be recorded.");
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

    // Layer 1 is one bounded isolation response per vertical. Replays return
    // the recorded result instead of creating a second handoff signal.
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
      // A concurrent request may have won the task-once constraint. Treat it
      // as a replay and return the authoritative stored score.
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
