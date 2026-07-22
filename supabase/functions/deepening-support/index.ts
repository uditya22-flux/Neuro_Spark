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
  supportGuidance,
  type VerticalId,
  VERTICALS,
} from "../_shared/engine2.ts";

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
    const verticalId = body.vertical_id ?? body.verticalId;
    if (
      typeof verticalId !== "string" ||
      !VERTICALS.includes(verticalId as VerticalId)
    ) {
      throw new ValidationError("vertical_id is required.");
    }
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data: state } = await svc.from("layer_progression_state").select(
      "id, current_task_id, support_level, status",
    )
      .eq("session_id", sessionId).eq("child_id", childId).eq(
        "vertical_id",
        verticalId,
      ).maybeSingle();
    if (
      !state || state.status !== "in_progress" ||
      state.current_task_id !== taskId
    ) {
      return conflict("Support is not available for this task.");
    }
    const nextLevel = Math.min(5, Number(state.support_level) + 1);
    if (nextLevel === Number(state.support_level)) {
      await svc.from("support_ladder_log").insert({
        session_id: sessionId,
        task_id: taskId,
        child_id: childId,
        vertical_id: verticalId,
        support_level: nextLevel,
        trigger_reason:
          "child requested additional help after interactive help",
        outcome: "abandoned",
      });
    } else {
      const { error: stateError } = await svc.from("layer_progression_state")
        .update({
          support_level: nextLevel,
          updated_at: new Date().toISOString(),
        })
        .eq("id", state.id);
      if (stateError) throw new Error("Support state could not be updated.");
      const { error: logError } = await svc.from("support_ladder_log").insert({
        session_id: sessionId,
        task_id: taskId,
        child_id: childId,
        vertical_id: verticalId,
        support_level: nextLevel,
        trigger_reason: "child requested help",
        outcome: "escalated_further",
      });
      if (logError) {
        throw new Error("Support transition could not be recorded.");
      }
    }
    await writeAudit({
      action: "engine2.support_requested",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        vertical_id: verticalId,
        support_level: nextLevel,
      },
    });
    return ok({
      support_level: nextLevel,
      support: supportGuidance(nextLevel),
    });
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    console.error("[deepening-support] unexpected:", (error as Error).message);
    return internalError();
  }
});
