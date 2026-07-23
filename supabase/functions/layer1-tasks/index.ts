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
  contentHash,
  createLayer1SectorTasks,
  loadEngine1Config,
  publicTask,
  SECTORS,
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
    const requestedSession = body.session_id ?? body.sessionId;
    const sessionId = requestedSession
      ? requireUuid(requestedSession, "session_id")
      : null;
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const config = await loadEngine1Config(db, guardianId, childId);

    let session: Record<string, unknown> | null = null;
    if (sessionId) {
      const { data } = await svc.from("layer1_sessions").select(
        "id, child_id, guardian_id, status, expires_at",
      ).eq("id", sessionId).eq("child_id", childId).eq(
        "guardian_id",
        guardianId,
      ).maybeSingle();
      if (!data) {
        return conflict(
          "The requested orchestration session is not available.",
        );
      }
      session = data;
    } else {
      const { data: reusable, error: reusableError } = await svc
        .from("layer1_sessions")
        .select("id, child_id, guardian_id, status, expires_at")
        .eq("child_id", childId)
        .eq("guardian_id", guardianId)
        .eq("status", "in_progress")
        .gt("expires_at", new Date().toISOString())
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (reusableError) {
        return internalError("Layer 1 session could not be read.");
      }
      if (reusable) {
        session = reusable;
      } else {
        const { data, error } = await svc.from("layer1_sessions").insert({
          child_id: childId,
          guardian_id: guardianId,
        }).select("id, child_id, guardian_id, status, expires_at").single();
        if (error || !data) {
          console.error("[layer1-tasks] session insert:", error?.message);
          return internalError("Layer 1 session could not be created.");
        }
        session = data;
      }
    }

    if (
      session.status !== "in_progress" ||
      new Date(String(session.expires_at)) <= new Date()
    ) {
      return conflict("Layer 1 session is no longer active.");
    }

    const existing = await svc.from("vertical_task_bank")
      .select(
        "id, vertical_id, layer_number, source_type, difficulty_tier, item_payload",
      )
      .eq("session_id", session.id).eq("layer_number", 1).eq("active", true);
    if (existing.error) {
      return internalError("Layer 1 tasks could not be read.");
    }

    const existingTasks = (existing.data ?? []) as Record<string, unknown>[];
    const taskRows: Record<string, unknown>[] = [...existingTasks];

    if (existingTasks.length < 30) {
      const sectorTasks = createLayer1SectorTasks(
        String(session.id),
        String(session.id),
        config,
      );

      for (const task of sectorTasks) {
        const hash = await contentHash({
          vertical: task.verticalId,
          layer: 1,
          payload: task.payload,
          answer: task.answerKey,
        });

        const { data, error } = await svc.from("vertical_task_bank").insert({
          child_id: childId,
          session_id: session.id,
          vertical_id: task.verticalId,
          layer_number: 1,
          source_type: task.sourceType,
          difficulty_tier: task.difficultyTier,
          item_payload: {
            public_payload: task.payload,
            answer_key: task.answerKey,
          },
          content_hash: hash,
          rule_version: task.ruleVersion,
        }).select(
          "id, vertical_id, layer_number, source_type, difficulty_tier, item_payload",
        ).maybeSingle();

        if (data) {
          taskRows.push(data);
        }
      }
    }

    await writeAudit({
      action: "engine2.layer1_tasks_issued",
      guardianId,
      childId,
      meta: { session_id: session.id, sector_count: SECTORS.length, total_probes: taskRows.length },
    });
    return ok({
      session_id: session.id,
      phase: "layer1",
      verticals: taskRows.map((taskRow) => publicTask(taskRow)),
      active_sectors: [...SECTORS],
      total_questions: taskRows.length,
    }, 200);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error("[layer1-tasks] unexpected:", (err as Error).message);
    return internalError();
  }
});
