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
  publicTask,
  requiredExecutions,
  SECTORS,
  type SectorId,
  survivingSectorsForLayer,
  TRACKS,
  type TrackId,
  type VerticalId,
} from "../_shared/engine2.ts";

type ProgressState = Record<string, unknown>;

const asNumber = (value: unknown): number => {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
};

async function createOrLoadTaskForDomain(
  svc: ReturnType<typeof import("../_shared/auth.ts").buildServiceClient>,
  sessionId: string,
  childId: string,
  domainId: VerticalId,
  layer: number,
  state: ProgressState,
  config: Awaited<ReturnType<typeof loadEngine1Config>>,
): Promise<Record<string, unknown>> {
  const { data: existing, error: existingError } = await svc
    .from("vertical_task_bank")
    .select("*")
    .eq("session_id", sessionId)
    .eq("child_id", childId)
    .eq("vertical_id", domainId)
    .eq("layer_number", layer)
    .eq("active", true)
    .maybeSingle();

  if (existingError) throw new Error("Deepening task could not be read.");
  if (existing) {
    return existing as Record<string, unknown>;
  }

  const { data: previousExecutions } = await svc
    .from("layer_task_execution")
    .select("accuracy, recovery, engagement, latency_ms")
    .eq("session_id", sessionId)
    .eq("vertical_id", domainId)
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
    domainId,
    layer,
    `${sessionId}:${domainId}:${layer}`,
    config,
    "visual",
    undefined,
    previousScore,
  );

  // Layer 8 deliberate signal collector reuse
  if (layer === 8) {
    const { data: priorTask } = await svc.from("vertical_task_bank")
      .select("item_payload, rule_version")
      .eq("session_id", sessionId)
      .eq("vertical_id", domainId)
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
        objective: "strategy signals instrumentation",
        instrumentation_only: true,
        layer_protocol: layerProtocol(domainId, 8),
        reused_from_layer: 7,
      };
      task.answerKey = (oldPayload.answer_key ?? {}) as Record<string, unknown>;
      task.ruleVersion = `${String(priorTask.rule_version)}:instrumentation-v1`;
    }
  }

  const hash = await contentHash({
    verticalId: domainId,
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
    vertical_id: domainId,
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
    return inserted as Record<string, unknown>;
  }

  const { data: concurrent } = await svc.from("vertical_task_bank")
    .select("*")
    .eq("session_id", sessionId)
    .eq("vertical_id", domainId)
    .eq("layer_number", layer)
    .eq("active", true)
    .maybeSingle();

  if (!concurrent) {
    console.error("[deepening-next-task] task insert error:", insertError?.message);
    throw new Error("Deepening task could not be created.");
  }
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

    const { data: state, error: stateError } = await svc.from(
      "layer_progression_state",
    )
      .select("*")
      .eq("session_id", sessionId)
      .eq("child_id", childId)
      .eq("status", "in_progress")
      .maybeSingle();

    if (stateError) throw new Error("Deepening state could not be read.");
    if (!state) {
      return ok({
        status: "funnel_complete",
        session_id: sessionId,
        verticals: [],
      });
    }

    const currentLayer = asNumber(state.current_layer);
    const trackAffinity = (state.track_affinity ?? {}) as Record<string, unknown>;
    const gap = asNumber(trackAffinity.gap ?? 1.0);
    const isAmbiguous = trackAffinity.isAmbiguous === true || gap <= 0.15;
    const leaderTrack = (trackAffinity.leader as TrackId) ?? "calendar_genius";

    let targetDomains: VerticalId[] = [];

    if (currentLayer >= 10) {
      if (isAmbiguous) {
        // Layer 10 explicit decider round: side-by-side tasks from both production tracks
        targetDomains = ["calendar_genius", "constellation_mapper"];
        if (!state.decider_required) {
          await svc.from("layer_progression_state").update({ decider_required: true }).eq("id", state.id);
        }
      } else {
        // Clear lead: run real-world confirmation task for winning track
        targetDomains = [leaderTrack];
      }
    } else {
      // Layers 2–9: issue tasks for active surviving sectors
      const activeSectors = Array.isArray(state.active_sectors)
        ? (state.active_sectors as SectorId[])
        : survivingSectorsForLayer(currentLayer, [...SECTORS] as SectorId[]);
      targetDomains = activeSectors;
    }

    const verticals: Record<string, unknown>[] = [];
    for (const domain of targetDomains) {
      const task = await createOrLoadTaskForDomain(
        svc,
        sessionId,
        childId,
        domain,
        currentLayer,
        state as ProgressState,
        config,
      );
      const { count } = await svc.from("layer_task_execution")
        .select("id", { count: "exact", head: true })
        .eq("session_id", sessionId)
        .eq("task_id", task.id);

      const executionIndex = Math.min(
        requiredExecutions(currentLayer),
        (count ?? 0) + 1,
      );

      verticals.push(publicTask(task, {
        supportLevel: asNumber(state.support_level),
        executionIndex,
        requiredExecutions: requiredExecutions(currentLayer),
      }));
    }

    await writeAudit({
      action: "engine2.deepening_tasks_issued",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        layer: currentLayer,
        target_domains: targetDomains,
      },
    });

    return ok({
      status: "in_progress",
      session_id: sessionId,
      current_layer: currentLayer,
      verticals,
    });
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    console.error(
      "[deepening-next-task] unexpected:",
      (error as Error).message,
    );
    return internalError();
  }
});
