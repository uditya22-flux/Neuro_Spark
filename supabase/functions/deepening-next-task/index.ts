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
  createTask,
  loadEngine1Config,
  orchestrateLayer,
  publicTask,
  VERTICALS,
  type VerticalId,
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
      return conflict(
        "Complete an active Layer 1 session before starting deepening.",
      );
    }
    
    const config = await loadEngine1Config(db, guardianId, childId);
    
    let { data: state } = await svc.from("global_progression_state").select("*")
      .eq("session_id", sessionId).eq("child_id", childId).maybeSingle();
      
    if (!state) {
      const { data: created, error } = await svc.from("global_progression_state")
        .insert({
          session_id: sessionId,
          child_id: childId,
          current_layer: 2,
        }).select("*").single();
      if (created) {
        state = created;
      } else {
        const { data: concurrentState } = await svc
          .from("global_progression_state")
          .select("*").eq("session_id", sessionId).eq("child_id", childId).maybeSingle();
        if (!concurrentState) {
          console.error("[deepening-next-task] progression insert:", error?.message);
          throw new Error("Global deepening progression could not be initialized.");
        }
        state = concurrentState;
      }
    }
    
    if (state.status === "funnel_complete") {
      return ok({
        status: "funnel_complete",
        session_id: sessionId,
      });
    }

    let plan = state.orchestration_plan as Record<string, any>;
    if (Object.keys(plan).length === 0) {
      // Orchestrate the layer!
      // Fetch previous layer scores
      const { data: execs } = await svc.from("layer_task_execution")
        .select("vertical_id, accuracy, latency_ms, recovery")
        .eq("session_id", sessionId)
        .eq("layer_number", state.current_layer - 1);
        
      const previousScores: Record<string, any> = {};
      for (const ex of (execs ?? [])) {
        previousScores[ex.vertical_id] = {
           accuracy: ex.accuracy,
           speed: Math.max(0, 1 - (ex.latency_ms / 60000)),
           isolationScore: ex.accuracy // fallback approximation
        };
      }
      
      plan = await orchestrateLayer(state.current_layer, config.activeVerticals, previousScores);
      
      const { error: planErr } = await svc.from("global_progression_state")
        .update({ orchestration_plan: plan })
        .eq("id", state.id);
      if (planErr) throw new Error("Could not save orchestration plan.");
    }
    
    const activeTasks = (state.active_tasks as string[] ?? []);
    const completedTasks = (state.completed_tasks as string[] ?? []);
    const generatedTasks: Record<string, unknown>[] = [];
    
    // For each subject in the plan, ensure a task is generated
    for (const [vId, pConfig] of Object.entries(plan)) {
      const verticalId = vId as VerticalId;
      if (!VERTICALS.includes(verticalId)) continue;
      
      let { data: taskRow } = await svc.from("vertical_task_bank").select("*")
        .eq("session_id", sessionId).eq("vertical_id", verticalId)
        .eq("layer_number", state.current_layer).maybeSingle();
        
      if (!taskRow) {
        const task = await createTask(
          verticalId,
          state.current_layer,
          `${sessionId}:${verticalId}:${state.current_layer}:${Date.now()}`,
          config,
          pConfig.modality,
          pConfig.difficulty,
          previousScores[verticalId],
        );
        const hash = await contentHash({
          verticalId,
          layer: state.current_layer,
          payload: task.payload,
          answer: task.answerKey,
        });
        const { data: inserted, error: insertErr } = await svc.from("vertical_task_bank").insert({
          child_id: childId,
          session_id: sessionId,
          vertical_id: verticalId,
          layer_number: state.current_layer,
          source_type: task.sourceType,
          difficulty_tier: task.difficultyTier,
          item_payload: {
            public_payload: task.payload,
            answer_key: task.answerKey,
          },
          content_hash: hash,
          rule_version: task.ruleVersion,
        }).select("*").single();
        if (insertErr || !inserted) {
           const { data: concurrent } = await svc.from("vertical_task_bank").select("*")
            .eq("session_id", sessionId).eq("vertical_id", verticalId)
            .eq("layer_number", state.current_layer).maybeSingle();
           if (!concurrent) throw new Error("Could not create task.");
           taskRow = concurrent;
        } else {
           taskRow = inserted;
        }
      }
      
      if (!completedTasks.includes(taskRow.id)) {
        generatedTasks.push(taskRow);
        if (!activeTasks.includes(taskRow.id)) {
           activeTasks.push(taskRow.id);
        }
      }
    }
    
    // Update active tasks
    await svc.from("global_progression_state").update({ active_tasks: activeTasks }).eq("id", state.id);

    if (generatedTasks.length === 0) {
      // This layer is complete, but we didn't advance it in submit-response yet?
      // Just a fallback
      return ok({
        status: "funnel_complete",
        session_id: sessionId,
      });
    }

    await writeAudit({
      action: "engine2.deepening_layer_issued",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        layer: state.current_layer,
      },
    });
    
    return ok({
      status: "in_progress",
      session_id: sessionId,
      verticals: generatedTasks.map(publicTask),
    });
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error("[deepening-next-task] unexpected:", (err as Error).message);
    return internalError();
  }
});
