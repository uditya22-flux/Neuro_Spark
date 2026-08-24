import {
  buildFallbackPrompt,
  buildTaskFromTemplate,
  type SectorRow,
} from "../functions/_shared/strength_funnel_tasks.ts";
import { routeModalityFromIsaa } from "../functions/_shared/modality_router.ts";

const buildFixSector: SectorRow = {
  id: "r_build_fix",
  riasec_type: "realistic",
  display_name: "Build & Fix",
  play_theme: "building blocks and fixing things",
};

Deno.test("strength funnel tasks — fallback prompt uses present-moment framing", () => {
  const prompt = buildFallbackPrompt(buildFixSector);
  if (!prompt.includes("right now")) {
    throw new Error("Fallback prompt must reference present moment.");
  }
  if (/career|job|employ/i.test(prompt)) {
    throw new Error("Fallback prompt must not reference careers.");
  }
});

Deno.test("strength funnel tasks — template sample overrides fallback", () => {
  const constraints = routeModalityFromIsaa({ speechCommunication: 5 });
  const template = {
    sample_generated_task: {
      present_moment_prompt: "Is stacking blocks fun for you right now?",
      activity_scene: {
        activity_label: "Tower building",
        simple_picture_description: "Blocks only. No faces.",
      },
      enjoyment_scale: {
        min_label: "Not fun right now",
        max_label: "Really fun right now",
      },
    },
  };
  const task = buildTaskFromTemplate(buildFixSector, template, constraints);
  if (task.present_moment_prompt !== "Is stacking blocks fun for you right now?") {
    throw new Error("Template sample prompt was not applied.");
  }
  if (task.renderer_modality !== "picture") {
    throw new Error("Low-verbal profile should route to picture modality.");
  }
});
