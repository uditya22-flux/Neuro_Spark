import {
  badRequest,
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
  generateSectorTask,
} from "../_shared/strength_funnel_generator.ts";
import {
  normalizeIsaaProfile,
  routeModalityFromIsaa,
  type IsaaProfile,
} from "../_shared/modality_router.ts";
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
    const sectorId = String(body.sector_id ?? body.sectorId ?? "");
    const layer = Number(body.layer_number ?? body.layerNumber ?? 1);

    if (!sectorId) {
      return badRequest("sector_id is required.");
    }
    if (!Number.isInteger(layer) || layer < 1 || layer > 10) {
      return badRequest("layer_number must be between 1 and 10.");
    }

    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const { data: sector } = await svc.from("riasec_sectors")
      .select("id, riasec_type, display_name, play_theme")
      .eq("id", sectorId)
      .eq("active", true)
      .maybeSingle();

    if (!sector) return badRequest("Unknown or inactive sector_id.");

    const { data: templateRow } = await svc.from("riasec_sector_templates")
      .select("template_json")
      .eq("sector_id", sectorId)
      .eq("active", true)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const isaa = normalizeIsaaProfile(parseIsaa(body));
    const constraints = routeModalityFromIsaa(isaa);
    const templateJson = (templateRow?.template_json as Record<string, unknown>) ??
      catalogTemplateForSector(sectorId);

    const result = await generateSectorTask({
      sector: sector as SectorRow,
      templateJson,
      isaa,
      modalityConstraints: constraints,
      layer,
    });

    await writeAudit({
      action: "strength_funnel.task_generated",
      guardianId,
      childId,
      meta: {
        sector_id: sectorId,
        layer,
        source: result.source,
        deep_dive: result.deep_dive,
      },
    });

    return ok({
      task: result.task,
      source: result.source,
      layer_number: result.layer,
      deep_dive: result.deep_dive,
      modality_constraints: constraints,
    }, 200);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error("[strength-funnel-generate-task] unexpected:", (err as Error).message);
    return internalError();
  }
});
