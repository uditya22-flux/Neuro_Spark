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
  layerProtocol,
  loadEngine1Config,
  pathForIsolation,
  pathLayers,
  type PathType,
  publicTask,
  requiredExecutions,
  type VerticalId,
  VERTICALS,
} from "../_shared/engine2.ts";

type ProgressState = Record<string, unknown>;

const asNumber = (value: unknown): number => {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
};

const asStringArray = (value: unknown): string[] =>
  Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];

async function ensureProgressionStates(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  sessionId: string,
  childId: string,
  activeVerticals: VerticalId[],
): Promise<void> {
  const [
    { data: existing, error: stateError },
    { data: handoffs, error: handoffError },
  ] = await Promise.all([
    svc.from("layer_progression_state").select("vertical_id").eq(
      "session_id",
      sessionId,
    ).eq("child_id", childId),
    svc.from("stage2_handoffs").select("vertical_id, isolation_score, recovery")
      .eq("session_id", sessionId).eq("child_id", childId),
  ]);
  if (stateError || handoffError) {
    throw new Error("Deepening state could not be read.");
  }

  const existingVerticals = new Set(
    (existing ?? []).map((row: { vertical_id: string }) => row.vertical_id),
  );
  const handoffByVertical = new Map(
    (handoffs ?? []).map((
      row: Record<string, unknown>,
    ) => [row.vertical_id as string, row]),
  );

  for (const verticalId of activeVerticals) {
    if (existingVerticals.has(verticalId)) continue;
    const handoff = handoffByVertical.get(verticalId);
    if (!handoff) {
      throw new Error("Layer 1 handoff is required for every active vertical.");
    }
    const isolationScore = asNumber(handoff.isolation_score);
    const recovery = asNumber(handoff.recovery);
    const path = pathForIsolation(isolationScore, recovery);
    const layers = pathLayers(path);
    const pathHistory = [{
      layer: 1,
      path,
      reason: "Layer 1 isolation score selected the initial route.",
      isolation_score: isolationScore,
      created_at: new Date().toISOString(),
    }];
    const { error } = await svc.from("layer_progression_state").insert({
      session_id: sessionId,
      child_id: childId,
      vertical_id: verticalId,
      current_layer: layers[0],
      path_type: path,
      path_layers: layers,
      path_history: pathHistory,
      completed_layers: [],
      status: "in_progress",
      support_level: 0,
    });
    if (error && !String(error.message).includes("duplicate")) {
      throw new Error("Deepening state could not be initialized.");
    }
  }
}

async function createOrLoadTask(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  state: ProgressState,
  config: Awaited<ReturnType<typeof loadEngine1Config>>,
): Promise<Record<string, unknown>> {
  const sessionId = String(state.session_id);
  const childId = String(state.child_id);
  const verticalId = state.vertical_id as VerticalId;
  const layer = asNumber(state.current_layer);
  const { data: existing, error: existingError } = await svc
    .from("vertical_task_bank")
    .select("*")
    .eq("session_id", sessionId)
    .eq("child_id", childId)
    .eq("vertical_id", verticalId)
    .eq("layer_number", layer)
    .eq("active", true)
    .maybeSingle();
  if (existingError) throw new Error("Deepening task could not be read.");
  if (existing) {
    if (state.current_task_id !== existing.id) {
      await svc.from("layer_progression_state").update({
        current_task_id: existing.id,
      }).eq("id", state.id);
    }
    return existing as Record<string, unknown>;
  }

  const { data: previousExecutions } = await svc
    .from("layer_task_execution")
    .select("accuracy, recovery, engagement, latency_ms")
    .eq("session_id", sessionId)
    .eq("vertical_id", verticalId)
    .order("created_at", { ascending: false })
    .limit(3);
  const recent = previousExecutions?.[0] as Record<string, unknown> | undefined;
  const previousScore = recent
    ? {
      accuracy: asNumber(recent.accuracy),
      recovery: asNumber(recent.recovery),
      engagement: asNumber(recent.engagement),
      speed: Math.max(0, 1 - asNumber(recent.latency_ms) / 60_000),
    }
    : undefined;
  const task = await createTask(
    verticalId,
    layer,
    `${sessionId}:${verticalId}:${layer}`,
    config,
    "visual",
    undefined,
    previousScore,
  );

  // Layer 8 deliberately reuses the previous activity rather than introducing
  // a new task type. Only instrumentation metadata changes.
  if (layer === 8) {
    const { data: priorTask } = await svc.from("vertical_task_bank")
      .select("item_payload, rule_version")
      .eq("session_id", sessionId)
      .eq("vertical_id", verticalId)
      .lt("layer_number", 8)
      .order("layer_number", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (priorTask) {
      const oldPayload = priorTask.item_payload as Record<string, unknown>;
      const oldPublic = (oldPayload.public_payload ?? {}) as Record<
        string,
        unknown
      >;
      task.payload = {
        ...oldPublic,
        objective: "strategy signals",
        instrumentation_only: true,
        layer_protocol: layerProtocol(verticalId, 8),
        reused_from_layer: 7,
      };
      task.answerKey = (oldPayload.answer_key ?? {}) as Record<string, unknown>;
      task.ruleVersion = `${String(priorTask.rule_version)}:instrumentation-v1`;
    }
  }

  const hash = await contentHash({
    verticalId,
    layer,
    public: task.payload,
    answer: task.answerKey,
    composition: task.composition,
  });
  const { data: inserted, error: insertError } = await svc.from(
    "vertical_task_bank",
  ).insert({
    child_id: childId,
    session_id: sessionId,
    vertical_id: verticalId,
    layer_number: layer,
    source_type: task.sourceType,
    difficulty_tier: task.difficultyTier,
    item_payload: {
      public_payload: task.payload,
      answer_key: task.answerKey,
      composition: task.composition,
    },
    content_hash: hash,
    rule_version: task.ruleVersion,
  }).select("*").maybeSingle();
  if (inserted) {
    await svc.from("layer_progression_state").update({
      current_task_id: inserted.id,
    }).eq("id", state.id);
    return inserted as Record<string, unknown>;
  }
  const { data: concurrent } = await svc.from("vertical_task_bank")
    .select("*")
    .eq("session_id", sessionId)
    .eq("vertical_id", verticalId)
    .eq("layer_number", layer)
    .eq("active", true)
    .maybeSingle();
  if (!concurrent) {
    console.error("[deepening-next-task] task insert:", insertError?.message);
    throw new Error("Deepening task could not be created.");
  }
  await svc.from("layer_progression_state").update({
    current_task_id: concurrent.id,
  }).eq("id", state.id);
  return concurrent as Record<string, unknown>;
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
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data: session } = await svc.from("layer1_sessions")
      .select("status, expires_at")
      .eq("id", sessionId).eq("child_id", childId).maybeSingle();
    if (
      !session || session.status !== "complete" ||
      new Date(String(session.expires_at)) <= new Date()
    ) {
      return conflict("Complete an active Layer 1 session before deepening.");
    }

    const config = await loadEngine1Config(db, guardianId, childId);
    await ensureProgressionStates(
      svc,
      sessionId,
      childId,
      config.activeVerticals,
    );
    const { data: states, error: stateError } = await svc.from(
      "layer_progression_state",
    )
      .select("*")
      .eq("session_id", sessionId)
      .eq("child_id", childId)
      .eq("status", "in_progress")
      .order("vertical_id");
    if (stateError) throw new Error("Deepening state could not be read.");
    if (!states || states.length === 0) {
      return ok({
        status: "funnel_complete",
        session_id: sessionId,
        verticals: [],
      });
    }

    const verticals: Record<string, unknown>[] = [];
    for (const state of states as ProgressState[]) {
      const task = await createOrLoadTask(svc, state, config);
      const { count, error: countError } = await svc.from(
        "layer_task_execution",
      )
        .select("id", { count: "exact", head: true })
        .eq("session_id", sessionId)
        .eq("task_id", task.id);
      if (countError) throw new Error("Task progress could not be read.");
      const executionIndex = Math.min(
        requiredExecutions(asNumber(task.layer_number)),
        (count ?? 0) + 1,
      );
      verticals.push(publicTask(task, {
        supportLevel: asNumber(state.support_level),
        executionIndex,
        requiredExecutions: requiredExecutions(asNumber(task.layer_number)),
      }));
    }

    await writeAudit({
      action: "engine2.deepening_tasks_issued",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        verticals: verticals.map((task) => task.vertical_id),
      },
    });
    return ok({ status: "in_progress", session_id: sessionId, verticals });
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    console.error(
      "[deepening-next-task] unexpected:",
      (error as Error).message,
    );
    return internalError();
  }
});
