import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  computeAdvanceCap,
  initialActiveSectors,
  isEliminationLayer,
  LAYER_SECTOR_TARGETS,
  selectAdvancingSectors,
  sectorsAtLayerStart,
  TOTAL_SECTORS,
  ENGAGEMENT_ADVANCE_THRESHOLD,
} from "../functions/_shared/strength_funnel.ts";

Deno.test("strength funnel — layer 1 starts with 30 sectors", () => {
  assertEquals(sectorsAtLayerStart(1), TOTAL_SECTORS);
  assertEquals(initialActiveSectors().length, 30);
});

Deno.test("strength funnel — reference targets when full funnel qualifies", () => {
  assertEquals(computeAdvanceCap(30), 18);
  assertEquals(computeAdvanceCap(18), 11);
  assertEquals(computeAdvanceCap(6), 4);
  assertEquals(LAYER_SECTOR_TARGETS[5], 4);
});

Deno.test("strength funnel — layers 6-10 are deep-dive not elimination", () => {
  assertEquals(isEliminationLayer(5), true);
  assertEquals(isEliminationLayer(6), false);
});

Deno.test("strength funnel — advances sectors scored at or above 60%", () => {
  const advancing = selectAdvancingSectors(
    [
      { sectorId: "a", engagementScore: 0.2 },
      { sectorId: "b", engagementScore: 0.9 },
      { sectorId: "c", engagementScore: 0.5 },
      { sectorId: "d", engagementScore: 0.65 },
    ],
    1,
  );
  assertEquals(advancing, ["b", "d"]);
});

Deno.test("strength funnel — demo 6 sectors with 2 high scores advances 2 not fixed 18", () => {
  const advancing = selectAdvancingSectors(
    [
      { sectorId: "r_build_fix", engagementScore: 0.9 },
      { sectorId: "i_puzzles_logic", engagementScore: 0.8 },
      { sectorId: "a_drawing_color", engagementScore: 0.3 },
      { sectorId: "s_helping_caring", engagementScore: 0.2 },
      { sectorId: "e_leading_groups", engagementScore: 0.4 },
      { sectorId: "c_sorting_organizing", engagementScore: 0.1 },
    ],
    1,
  );
  assertEquals(advancing.length, 2);
  assertEquals(advancing, ["r_build_fix", "i_puzzles_logic"]);
});

Deno.test("strength funnel — threshold constant is 60%", () => {
  assertEquals(ENGAGEMENT_ADVANCE_THRESHOLD, 0.6);
});
