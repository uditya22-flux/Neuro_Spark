// This test intentionally reads the Edge Function source instead of importing
// it: importing an Edge entrypoint would register Deno.serve during a unit
// test. It guards the fixed Layer 1 catalogue that Flutter renders.

type ExpectedTask = {
  sector: string;
  sceneType: string;
  rule: string;
  interaction: string;
  stimulusTemplate: string;
};

const expectedTasks: readonly ExpectedTask[] = [
  {
    sector: "mentalRotation",
    sceneType: "rotate",
    rule: "matchMentalRotation",
    interaction: "tap_rotated_match",
    stimulusTemplate: "rotating_shape_match",
  },
  {
    sector: "visualPatternCompletion",
    sceneType: "pattern",
    rule: "completeVisualPattern",
    interaction: "tap_pattern_piece",
    stimulusTemplate: "pattern_grid_gap",
  },
  {
    sector: "pointCloudAnomalyDetection",
    sceneType: "search",
    rule: "detectPointCloudAnomaly",
    interaction: "tap_outlier_point",
    stimulusTemplate: "point_cloud_odd_one_out",
  },
  {
    sector: "mapRouteNavigation",
    sceneType: "route",
    rule: "navigateMapRoute",
    interaction: "drag_map_route",
    stimulusTemplate: "animated_maze_path",
  },
  {
    sector: "visualSpatialConstruction",
    sceneType: "connect",
    rule: "reconstructSpatialTarget",
    interaction: "drag_target_pieces",
    stimulusTemplate: "target_picture_rebuild",
  },
  {
    sector: "chronologicalSequencing",
    sceneType: "sequence",
    rule: "orderPictureCycle",
    interaction: "drag_cycle_order",
    stimulusTemplate: "picture_growth_cycle",
  },
  {
    sector: "narrativeEventOrdering",
    sceneType: "sequence",
    rule: "orderStoryPanels",
    interaction: "drag_story_order",
    stimulusTemplate: "wordless_comic_order",
  },
  {
    sector: "causeAndEffectChains",
    sceneType: "repair",
    rule: "chooseEffect",
    interaction: "tap_effect_choice",
    stimulusTemplate: "action_effect_scene",
  },
  {
    sector: "rhythmicMotorSequencing",
    sceneType: "rhythm",
    rule: "repeatRhythm",
    interaction: "tap_rhythm_replay",
    stimulusTemplate: "light_pulse_pattern",
  },
  {
    sector: "proceduralSequencing",
    sceneType: "sequence",
    rule: "orderProcedureIcons",
    interaction: "drag_procedure_order",
    stimulusTemplate: "procedure_icon_order",
  },
  {
    sector: "numberPatternRecognition",
    sceneType: "pattern",
    rule: "completeQuantityPattern",
    interaction: "tap_quantity_next",
    stimulusTemplate: "dot_quantity_pattern",
  },
  {
    sector: "ruleDiscovery",
    sceneType: "sort",
    rule: "discoverVisualRule",
    interaction: "drag_rule_sort",
    stimulusTemplate: "demonstrated_visual_rule",
  },
  {
    sector: "multiAttributeSorting",
    sceneType: "sort",
    rule: "sortMultipleAttributes",
    interaction: "drag_attribute_bins",
    stimulusTemplate: "multi_attribute_bins",
  },
  {
    sector: "systemizing",
    sceneType: "search",
    rule: "findSharedProperty",
    interaction: "tap_shared_property",
    stimulusTemplate: "shared_property_scatter",
  },
  {
    sector: "quantitativeEstimation",
    sceneType: "quantity",
    rule: "chooseLargerDotCloud",
    interaction: "tap_larger_cloud",
    stimulusTemplate: "brief_dot_cloud_compare",
  },
  {
    sector: "pictureAssociation",
    sceneType: "match",
    rule: "matchPictureAssociation",
    interaction: "tap_related_picture",
    stimulusTemplate: "picture_concept_match",
  },
  {
    sector: "phonologicalPatternRecognition",
    sceneType: "rhythm",
    rule: "matchPhonologicalPattern",
    interaction: "tap_sound_pair",
    stimulusTemplate: "nonword_sound_pair",
  },
  {
    sector: "wordlessInference",
    sceneType: "sequence",
    rule: "chooseStoryNext",
    interaction: "tap_story_outcome",
    stimulusTemplate: "picture_story_next",
  },
  {
    sector: "analogyMapping",
    sceneType: "match",
    rule: "completePictureAnalogy",
    interaction: "tap_analogy_piece",
    stimulusTemplate: "picture_analogy_grid",
  },
  {
    sector: "creativeStorytelling",
    sceneType: "connect",
    rule: "arrangeStoryPanels",
    interaction: "drag_story_build",
    stimulusTemplate: "wordless_story_builder",
  },
  {
    sector: "workingMemorySpan",
    sceneType: "memory",
    rule: "replayCellSequence",
    interaction: "tap_memory_cells",
    stimulusTemplate: "lit_cell_replay",
  },
  {
    sector: "visualSceneMemory",
    sceneType: "memory",
    rule: "findSceneChange",
    interaction: "tap_scene_difference",
    stimulusTemplate: "scene_change_pair",
  },
  {
    sector: "sustainedAttention",
    sceneType: "search",
    rule: "identifyTargetStream",
    interaction: "tap_stream_target",
    stimulusTemplate: "target_shape_stream",
  },
  {
    sector: "auditorySequenceRecall",
    sceneType: "rhythm",
    rule: "replayToneSequence",
    interaction: "tap_tone_replay",
    stimulusTemplate: "tone_icon_replay",
  },
  {
    sector: "selectiveAttention",
    sceneType: "search",
    rule: "findSelectiveTarget",
    interaction: "tap_hidden_target",
    stimulusTemplate: "hidden_target_field",
  },
  {
    sector: "emotionRecognition",
    sceneType: "match",
    rule: "matchEmotionIcon",
    interaction: "tap_emotion_icon",
    stimulusTemplate: "emotion_icon_scene",
  },
  {
    sector: "perspectiveTaking",
    sceneType: "sequence",
    rule: "choosePerspectiveOutcome",
    interaction: "tap_perspective_outcome",
    stimulusTemplate: "perspective_scene_outcome",
  },
  {
    sector: "turnTakingStrategy",
    sceneType: "switch",
    rule: "chooseTurnStrategy",
    interaction: "tap_turn_strategy",
    stimulusTemplate: "turn_strategy_board",
  },
  {
    sector: "musicalPatternRecognition",
    sceneType: "rhythm",
    rule: "matchMelodyPattern",
    interaction: "tap_melody_match",
    stimulusTemplate: "melody_pattern_icons",
  },
  {
    sector: "visualArtisticComposition",
    sceneType: "shape",
    rule: "completeVisualComposition",
    interaction: "drag_symmetry_piece",
    stimulusTemplate: "symmetry_composition",
  },
];

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function readSectorBlock(catalogue: string, sector: string): string {
  const match = new RegExp(
    `^  ${sector}: \\{([\\s\\S]*?)^  \\},`,
    "m",
  ).exec(catalogue);
  assert(match, `Missing Layer 1 task definition for ${sector}.`);
  return match[1];
}

Deno.test("synthetic Engine 2 Layer 1 has one distinct word-free plan for all 30 sectors", async () => {
  const source = await Deno.readTextFile(
    new URL(
      "../functions/synthetic-engine2-next-task/index.ts",
      import.meta.url,
    ),
  );
  const start = source.indexOf("const sectorPuzzleBlueprints:");
  const end = source.indexOf("\n};", start);
  assert(
    start >= 0 && end > start,
    "Could not find the Layer 1 task catalogue.",
  );
  const catalogue = source.slice(start, end + 3);

  assert(
    expectedTasks.length === 30,
    "The expected Layer 1 catalogue must contain 30 sectors.",
  );
  assert(
    new Set(expectedTasks.map((task) => task.sector)).size === 30,
    "Layer 1 sectors must be unique.",
  );
  assert(
    new Set(expectedTasks.map((task) => task.rule)).size === 30,
    "Layer 1 rules must be unique.",
  );
  assert(
    new Set(expectedTasks.map((task) => task.interaction)).size === 30,
    "Every Layer 1 sector must retain its own interaction plan.",
  );
  assert(
    new Set(expectedTasks.map((task) => task.stimulusTemplate)).size === 30,
    "Every Layer 1 sector must retain its own visual stimulus template.",
  );

  for (const task of expectedTasks) {
    const block = readSectorBlock(catalogue, task.sector);
    assert(
      block.includes(`sceneType: '${task.sceneType}'`),
      `${task.sector} scene type changed.`,
    );
    assert(
      block.includes(`rule: '${task.rule}'`),
      `${task.sector} rule changed.`,
    );
    assert(
      block.includes(`interaction: '${task.interaction}'`),
      `${task.sector} interaction changed.`,
    );
    assert(
      block.includes(`stimulusTemplate: '${task.stimulusTemplate}'`),
      `${task.sector} stimulus template changed.`,
    );
  }
});
