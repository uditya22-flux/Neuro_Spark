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
  selectAdvancingSectors,
  isEliminationLayer,
  type SectorEngagement,
} from "../_shared/strength_funnel.ts";

function numberField(value: unknown, field: string): number {
  if (value === undefined || value === null) {
    throw new ValidationError(`${field} is required.`);
  }
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0 || n > 1) {
    throw new ValidationError(`${field} must be between 0 and 1.`);
  }
  return n;
}

function modalityField(value: unknown): string {
  const modality = String(value ?? "picture");
  if (!["picture", "video", "text", "haptic"].includes(modality)) {
    throw new ValidationError("modality_used must be picture, video, text, or haptic.");
  }
  return modality;
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
    const sessionId = requireUuid(body.session_id ?? body.sessionId, "session_id");
    const layerRunId = requireUuid(
      body.layer_run_id ?? body.layerRunId,
      "layer_run_id",
    );
    const sectorId = String(body.sector_id ?? body.sectorId ?? "");
    if (!sectorId) {
      return badRequest("sector_id is required.");
    }

    const engagementScore = numberField(
      body.engagement_score ?? body.engagementScore,
      "engagement_score",
    );
    const modalityUsed = modalityField(body.modality_used ?? body.modalityUsed);
    const latencyMs = body.latency_ms ?? body.latencyMs;

    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const { data: session } = await svc.from("strength_funnel_sessions")
      .select("id, status, expires_at, current_layer, active_sector_ids")
      .eq("id", sessionId)
      .eq("child_id", childId)
      .eq("guardian_id", guardianId)
      .maybeSingle();
    if (!session) return conflict("Strength funnel session is not available.");

    if (
      session.status !== "in_progress" ||
      new Date(String(session.expires_at)) <= new Date()
    ) {
      return conflict("Strength funnel session is no longer active.");
    }

    const activeSectorIds = session.active_sector_ids as string[];
    if (!activeSectorIds.includes(sectorId)) {
      return badRequest("sector_id is not active in this session.");
    }

    const { data: layerRun } = await svc.from("strength_funnel_layer_runs")
      .select("id, layer_number, completed_at")
      .eq("id", layerRunId)
      .eq("session_id", sessionId)
      .maybeSingle();
    if (!layerRun) return conflict("Layer run is not available.");

    const { data: existing } = await svc.from("strength_funnel_sector_scores")
      .select("engagement_score, modality_used")
      .eq("layer_run_id", layerRunId)
      .eq("sector_id", sectorId)
      .maybeSingle();

    if (!existing) {
      const { error: insertError } = await svc.from("strength_funnel_sector_scores")
        .insert({
          session_id: sessionId,
          layer_run_id: layerRunId,
          sector_id: sectorId,
          engagement_score: engagementScore,
          modality_used: modalityUsed,
          response_payload: {
            enjoyment_slider: engagementScore,
          },
          latency_ms: latencyMs != null ? Number(latencyMs) : null,
        });
      if (insertError) {
        console.error(
          "[strength-funnel-submit-score] insert:",
          insertError.message,
        );
        return internalError("Sector score could not be recorded.");
      }
    }

    const { data: allScores, error: scoresError } = await svc
      .from("strength_funnel_sector_scores")
      .select("sector_id, engagement_score")
      .eq("layer_run_id", layerRunId);
    if (scoresError) {
      return internalError("Layer scores could not be read.");
    }

    const scoredIds = new Set(
      (allScores ?? []).map((row: { sector_id: string }) => row.sector_id),
    );
    const layerComplete = activeSectorIds.every((id) => scoredIds.has(id));

    let advancingSectorIds: string[] | null = null;
    let nextLayer: number | null = null;

    if (layerComplete && !layerRun.completed_at) {
      const engagements: SectorEngagement[] = (allScores ?? []).map(
        (row: { sector_id: string; engagement_score: number }) => ({
          sectorId: row.sector_id,
          engagementScore: Number(row.engagement_score),
        }),
      );
      advancingSectorIds = selectAdvancingSectors(engagements, layerRun.layer_number);
      nextLayer = layerRun.layer_number + 1;

      await svc.from("strength_funnel_layer_runs").update({
        completed_at: new Date().toISOString(),
      }).eq("id", layerRunId);

      const sessionUpdate: Record<string, unknown> = {
        active_sector_ids: advancingSectorIds,
      };

      if (layerRun.layer_number >= 10) {
        sessionUpdate.current_layer = 10;
        sessionUpdate.status = "completed";
        sessionUpdate.completed_at = new Date().toISOString();
      } else {
        sessionUpdate.current_layer = nextLayer;
      }

      await svc.from("strength_funnel_sessions").update(sessionUpdate)
        .eq("id", sessionId);
    }

    await writeAudit({
      action: "strength_funnel.sector_scored",
      guardianId,
      childId,
      meta: {
        session_id: sessionId,
        sector_id: sectorId,
        engagement_score: engagementScore,
        layer_complete: layerComplete,
      },
    });

    return ok({
      session_id: sessionId,
      sector_id: sectorId,
      engagement_score: engagementScore,
      scored_count: scoredIds.size,
      total_sectors: activeSectorIds.length,
      layer_complete: layerComplete,
      advancing_sector_ids: advancingSectorIds,
      next_layer: nextLayer,
      deep_dive: !isEliminationLayer(layerRun.layer_number),
      idempotent: existing != null,
    }, existing ? 200 : 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error(
      "[strength-funnel-submit-score] unexpected:",
      (err as Error).message,
    );
    return internalError();
  }
});
