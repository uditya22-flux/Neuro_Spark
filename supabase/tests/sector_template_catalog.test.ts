import {
  buildTaskFromTemplate,
  type SectorRow,
} from "../functions/_shared/strength_funnel_tasks.ts";
import { routeModalityFromIsaa } from "../functions/_shared/modality_router.ts";
import {
  layerAdjustedPrompt,
  sampleBySectorId,
} from "../functions/_shared/sector_template_catalog.ts";

const sector: SectorRow = {
  id: "a_drawing_color",
  riasec_type: "artistic",
  display_name: "Drawing & Color",
  play_theme: "drawing, coloring, and visual art",
};

Deno.test("sector catalog — layer 2 prompt stays present-moment", () => {
  const sample = sampleBySectorId("a_drawing_color");
  if (!sample) throw new Error("Missing catalog sample.");
  const layer2 = layerAdjustedPrompt(sample, 2);
  if (!layer2.includes("right now")) {
    throw new Error("Layer 2 prompt must retain present-moment framing.");
  }
  if (/career|job/i.test(layer2)) {
    throw new Error("Layer 2 prompt must not reference careers.");
  }
});

Deno.test("sector catalog — enriches fallback task from catalog", () => {
  const constraints = routeModalityFromIsaa({ speechCommunication: 2 });
  const task = buildTaskFromTemplate(sector, null, constraints, 1);
  if (!task.present_moment_prompt.includes("bright colors")) {
    throw new Error("Catalog fallback should enrich generic sectors.");
  }
});
