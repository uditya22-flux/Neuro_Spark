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
  constraintsToJson,
  normalizeIsaaProfile,
  routeModalityFromIsaa,
  type IsaaProfile,
} from "../_shared/modality_router.ts";
import {
  initialActiveSectors,
  computeAdvanceCap,
} from "../_shared/strength_funnel.ts";
import {
  generateSectorTask,
  generateTaskFromTemplate,
} from "../_shared/strength_funnel_generator.ts";
import { catalogTemplateForSector } from "../_shared/sector_template_catalog.ts";
import type { SectorRow } from "../_shared/strength_funnel_tasks.ts";

function parseIsaa(body: Record<string, unknown>): Partial<IsaaProfile> {
  const raw = (body.isaa ?? body.isaa_profile ?? {}) as Record<string, unknown>;
  return {
    socialRelationship: Number(raw.social_relationship ?? raw.socialRelationship),
    emotionalResponsiveness: Number(
      raw.emotional_responsiveness ?? raw.emotionalResponsiveness,
    ),
    speechCommunication: Number(
      raw.speech_communication ?? raw.speechCommunication,
    ),
    behaviorPatterns: Number(raw.behavior_patterns ?? raw.behaviorPatterns),
    sensoryAspects: Number(raw.sensory_aspects ?? raw.sensoryAspects),
    cognitiveComponent: Number(raw.cognitive_component ?? raw.cognitiveComponent),
    soundTriggers: (raw.sound_triggers ?? raw.soundTriggers ?? []) as string[],
    visualTriggers: (raw.visual_triggers ?? raw.visualTriggers ?? []) as string[],
    tactilePreference: (raw.tactile_preference ?? raw.tactilePreference ??
      "neutral") as IsaaProfile["tactilePreference"],
  };
}

function parseLayerNumber(body: Record<string, unknown>, sessionLayer: number): number {
  const raw = body.layer_number ?? body.layerNumber;
  if (raw === undefined || raw === null) return sessionLayer;
  const layer = Number(raw);
  if (!Number.isInteger(layer) || layer < 1 || layer > 10) {
    throw new ValidationError("layer_number must be an integer between 1 and 10.");
  }
  return layer;
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
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const isaa = normalizeIsaaProfile(parseIsaa(body));
    const constraints = routeModalityFromIsaa(isaa);
    const modalityJson = constraintsToJson(constraints);

    const { data: isaaRow, error: isaaError } = await svc
      .from("child_isaa_profiles")
      .upsert({
        child_id: childId,
        guardian_id: guardianId,
        social_relationship: isaa.socialRelationship,
        emotional_responsiveness: isaa.emotionalResponsiveness,
        speech_communication: isaa.speechCommunication,
        behavior_patterns: isaa.behaviorPatterns,
        sensory_aspects: isaa.sensoryAspects,
        cognitive_component: isaa.cognitiveComponent,
        sound_triggers: isaa.soundTriggers ?? [],
        visual_triggers: isaa.visualTriggers ?? [],
        tactile_preference: isaa.tactilePreference ?? "neutral",
        recorded_at: new Date().toISOString(),
      }, { onConflict: "child_id" })
      .select("id")
      .single();
    if (isaaError || !isaaRow) {
      console.error("[strength-funnel-start] isaa upsert:", isaaError?.message);
      return internalError("ISAA profile could not be saved.");
    }

    let session: Record<string, unknown> | null = null;
    const requestedSession = body.session_id ?? body.sessionId;
    if (requestedSession) {
      const sessionId = requireUuid(requestedSession, "session_id");
      const { data } = await svc.from("strength_funnel_sessions").select("*")
        .eq("id", sessionId).eq("child_id", childId).eq("guardian_id", guardianId)
        .maybeSingle();
      session = data;
    } else {
      const { data: reusable } = await svc.from("strength_funnel_sessions")
        .select("*")
        .eq("child_id", childId)
        .eq("guardian_id", guardianId)
        .eq("status", "in_progress")
        .gt("expires_at", new Date().toISOString())
        .order("started_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      session = reusable;
    }

    if (!session) {
      const activeSectors = initialActiveSectors();
      const { data, error } = await svc.from("strength_funnel_sessions").insert({
        child_id: childId,
        guardian_id: guardianId,
        isaa_profile_id: isaaRow.id,
        status: "in_progress",
        current_layer: 1,
        active_sector_ids: activeSectors,
        modality_constraints: modalityJson,
      }).select("*").single();
      if (error || !data) {
        console.error("[strength-funnel-start] session insert:", error?.message);
        return internalError("Strength funnel session could not be created.");
      }
      session = data;
    }

    if (
      session.status !== "in_progress" ||
      new Date(String(session.expires_at)) <= new Date()
    ) {
      return conflict("Strength funnel session is no longer active.");
    }

    const sessionId = String(session.id);
    const sessionLayer = Number(session.current_layer ?? 1);
    const layerNumber = parseLayerNumber(body, sessionLayer);

    const useLlm = layerNumber >= 6 &&
      Deno.env.get("STRENGTH_FUNNEL_LLM_ENABLED") === "true";

    if (layerNumber > sessionLayer) {
      return badRequest(
        `Layer ${layerNumber} is not unlocked yet. Complete layer ${sessionLayer} first.`,
      );
    }

    let layerRun: Record<string, unknown> | null = null;
    const { data: existingRun } = await svc.from("strength_funnel_layer_runs")
      .select("*")
      .eq("session_id", sessionId)
      .eq("layer_number", layerNumber)
      .maybeSingle();

    const activeSectorIds = (session.active_sector_ids as string[] | null) ??
      initialActiveSectors();
    const sectorsAssessed = activeSectorIds.length;
    const sectorsAdvancing = computeAdvanceCap(sectorsAssessed);

    if (existingRun) {
      layerRun = existingRun;
    } else {
      const { data, error } = await svc.from("strength_funnel_layer_runs").insert({
        session_id: sessionId,
        layer_number: layerNumber,
        sectors_assessed: sectorsAssessed,
        sectors_advancing: sectorsAdvancing,
        filter_ratio: 0.6,
      }).select("*").single();
      if (error || !data) {
        console.error("[strength-funnel-start] layer run:", error?.message);
        return internalError(`Layer ${layerNumber} run could not be created.`);
      }
      layerRun = data;
    }

    const { data: sectors, error: sectorError } = await svc.from("riasec_sectors")
      .select("id, riasec_type, display_name, play_theme")
      .in("id", activeSectorIds)
      .eq("active", true);
    if (sectorError || !sectors) {
      return internalError("RIASEC sectors could not be loaded.");
    }

    const { data: templates } = await svc.from("riasec_sector_templates")
      .select("sector_id, template_json")
      .in("sector_id", activeSectorIds)
      .eq("active", true);

    const templateBySector = new Map<string, Record<string, unknown>>();
    for (const row of templates ?? []) {
      templateBySector.set(
        row.sector_id as string,
        row.template_json as Record<string, unknown>,
      );
    }

    const orderedSectors = activeSectorIds
      .map((id) => (sectors as SectorRow[]).find((s) => s.id === id))
      .filter((s): s is SectorRow => s != null);

    const tasks = [];
    for (const sector of orderedSectors) {
      const templateJson = templateBySector.get(sector.id) ??
        catalogTemplateForSector(sector.id);
      const generated = useLlm
        ? await generateSectorTask({
          sector,
          templateJson,
          isaa,
          modalityConstraints: constraints,
          layer: layerNumber,
        })
        : generateTaskFromTemplate({
          sector,
          templateJson,
          isaa,
          modalityConstraints: constraints,
          layer: layerNumber,
        });
      tasks.push(generated.task);
    }

    const { data: existingScores } = await svc.from("strength_funnel_sector_scores")
      .select("sector_id, engagement_score")
      .eq("layer_run_id", layerRun!.id);

    await writeAudit({
      action: `strength_funnel.layer${layerNumber}_started`,
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        layer_run_id: layerRun!.id,
        layer_number: layerNumber,
        sector_count: tasks.length,
      },
    });

    return ok({
      session_id: sessionId,
      layer_run_id: layerRun!.id,
      layer_number: layerNumber,
      total_sectors: tasks.length,
      sectors_assessed: sectorsAssessed,
      sectors_advancing: sectorsAdvancing,
      modality_constraints: session.modality_constraints ?? modalityJson,
      tasks,
      completed_sector_ids: (existingScores ?? []).map(
        (row: { sector_id: string }) => row.sector_id,
      ),
    }, 200);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error("[strength-funnel-start] unexpected:", (err as Error).message);
    return internalError();
  }
});
