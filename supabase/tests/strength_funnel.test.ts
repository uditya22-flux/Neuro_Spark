import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  initialActiveSectors,
  isEliminationLayer,
  LAYER_SECTOR_TARGETS,
  selectAdvancingSectors,
  sectorsAdvancingAfterLayer,
  sectorsAtLayerStart,
  TOTAL_SECTORS,
} from "../functions/_shared/strength_funnel.ts";

Deno.test("strength funnel — layer 1 starts with 30 sectors", () => {
  assertEquals(sectorsAtLayerStart(1), TOTAL_SECTORS);
  assertEquals(initialActiveSectors().length, 30);
});

Deno.test("strength funnel — 60% progression matches cursorrules targets", () => {
  assertEquals(sectorsAdvancingAfterLayer(1), 18);
  assertEquals(sectorsAdvancingAfterLayer(2), 11);
  assertEquals(sectorsAdvancingAfterLayer(3), 7);
  assertEquals(sectorsAdvancingAfterLayer(4), 4);
  assertEquals(LAYER_SECTOR_TARGETS[5], 4);
});

Deno.test("strength funnel — layers 6-10 are deep-dive not elimination", () => {
  assertEquals(isEliminationLayer(5), true);
  assertEquals(isEliminationLayer(6), false);
});

Deno.test("strength funnel — selects top engagement sectors", () => {
  const advancing = selectAdvancingSectors(
    [
      { sectorId: "a", engagementScore: 0.2 },
      { sectorId: "b", engagementScore: 0.9 },
      { sectorId: "c", engagementScore: 0.5 },
    ],
    2,
  );
  assertEquals(advancing, ["b", "c"]);
});
