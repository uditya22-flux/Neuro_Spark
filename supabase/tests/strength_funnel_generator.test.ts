import {
  generateTaskFromTemplate,
} from "../functions/_shared/strength_funnel_generator.ts";
import { deepDivePrompt, sampleBySectorId } from "../functions/_shared/sector_template_catalog.ts";
import { routeModalityFromIsaa } from "../functions/_shared/modality_router.ts";

Deno.test("strength funnel generator — template synthesis for layer 1", () => {
  const sample = sampleBySectorId("r_build_fix");
  if (!sample) throw new Error("Missing sample");
  const result = generateTaskFromTemplate({
    sector: {
      id: sample.sectorId,
      riasec_type: sample.riasecType,
      display_name: sample.displayName,
      play_theme: sample.playTheme,
    },
    templateJson: null,
    isaa: { speechCommunication: 5 },
    layer: 1,
  });
  if (result.source !== "template") throw new Error("Expected template source");
  if (!result.task.present_moment_prompt.includes("right now")) {
    throw new Error("Prompt must be present-moment.");
  }
});

Deno.test("strength funnel generator — deep dive layer 8 enriches prompt", () => {
  const sample = sampleBySectorId("a_drawing_color");
  if (!sample) throw new Error("Missing sample");
  const prompt = deepDivePrompt(sample, 9);
  if (!prompt.includes("absorbed")) {
    throw new Error("Layer 8 deep dive cue missing.");
  }
  const constraints = routeModalityFromIsaa({ speechCommunication: 3 });
  const result = generateTaskFromTemplate({
    sector: {
      id: sample.sectorId,
      riasec_type: sample.riasecType,
      display_name: sample.displayName,
      play_theme: sample.playTheme,
    },
    templateJson: null,
    modalityConstraints: constraints,
    layer: 9,
  });
  if (!result.deep_dive) throw new Error("Layer 9 must flag deep_dive.");
});
