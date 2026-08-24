/**
 * Assembles Layer 1 sector prompts from RIASEC templates or play-theme fallbacks.
 * Charter: present-moment enjoyment only — validated before return.
 */

import {
  assertPresentMomentFraming,
  type ModalityConstraints,
} from "./modality_router.ts";
import {
  layerAdjustedPrompt,
  sampleBySectorId,
} from "./sector_template_catalog.ts";

export interface SectorRow {
  id: string;
  riasec_type: string;
  display_name: string;
  play_theme: string;
}

export interface Layer1TaskPayload {
  sector_id: string;
  display_name: string;
  present_moment_prompt: string;
  activity_label: string;
  picture_description: string;
  video_description?: string;
  renderer_modality: string;
  min_enjoyment_label: string;
  max_enjoyment_label: string;
}

const DEFAULT_ENJOYMENT = {
  min_label: "Not fun right now",
  max_label: "Really fun right now",
};

function resolveModality(constraints: ModalityConstraints): string {
  if (constraints.primaryModality === "text" && constraints.allowText) {
    return "text";
  }
  if (constraints.primaryModality === "video" && constraints.allowVideo) {
    return "video";
  }
  if (constraints.primaryModality === "haptic" && constraints.allowHaptics) {
    return "haptic";
  }
  return "picture";
}

function capitalizeFirst(value: string): string {
  if (!value) return value;
  return value.charAt(0).toUpperCase() + value.slice(1);
}

/** Builds a present-moment prompt from play theme when no template sample exists. */
export function buildFallbackPrompt(sector: SectorRow): string {
  return `Is ${sector.play_theme} fun for you right now?`;
}

export function buildTaskFromTemplate(
  sector: SectorRow,
  templateJson: Record<string, unknown> | null,
  constraints: ModalityConstraints,
  layer = 1,
): Layer1TaskPayload {
  const modality = resolveModality(constraints);
  const sample = (templateJson?.sample_generated_task ??
    templateJson?.generation_schema) as Record<string, unknown> | undefined;

  let presentMomentPrompt = buildFallbackPrompt(sector);
  let activityLabel = sector.display_name;
  let pictureDescription =
    `Simple drawing related to ${sector.play_theme}. No faces. Neutral colors.`;
  let videoDescription: string | undefined;

  if (sample && typeof sample === "object") {
    if (typeof sample.present_moment_prompt === "string") {
      presentMomentPrompt = sample.present_moment_prompt;
    }
    const scene = sample.activity_scene as Record<string, unknown> | undefined;
    if (scene) {
      if (typeof scene.activity_label === "string") {
        activityLabel = scene.activity_label;
      }
      if (typeof scene.simple_picture_description === "string") {
        pictureDescription = scene.simple_picture_description;
      }
      if (typeof scene.optional_video_loop_description === "string") {
        videoDescription = scene.optional_video_loop_description;
      }
    }
  } else {
    presentMomentPrompt = buildFallbackPrompt(sector);
    activityLabel = capitalizeFirst(sector.play_theme.split(" and ")[0] ?? sector.display_name);
  }

  const catalogSample = sampleBySectorId(sector.id);
  if (catalogSample && layer > 1) {
    presentMomentPrompt = layerAdjustedPrompt(catalogSample, layer);
  } else if (catalogSample && presentMomentPrompt === buildFallbackPrompt(sector)) {
    presentMomentPrompt = catalogSample.presentMomentPrompt;
    activityLabel = catalogSample.activityLabel;
    pictureDescription = catalogSample.pictureDescription;
    videoDescription = catalogSample.videoDescription;
  }

  const enjoyment = (sample?.enjoyment_scale as Record<string, unknown> | undefined) ??
    DEFAULT_ENJOYMENT;

  const task: Layer1TaskPayload = {
    sector_id: sector.id,
    display_name: sector.display_name,
    present_moment_prompt: presentMomentPrompt,
    activity_label: activityLabel,
    picture_description: pictureDescription,
    video_description: videoDescription,
    renderer_modality: modality,
    min_enjoyment_label: String(enjoyment.min_label ?? DEFAULT_ENJOYMENT.min_label),
    max_enjoyment_label: String(enjoyment.max_label ?? DEFAULT_ENJOYMENT.max_label),
  };

  assertPresentMomentFraming(task as unknown as Record<string, unknown>);
  return task;
}
