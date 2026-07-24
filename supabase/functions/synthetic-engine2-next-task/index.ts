import {
  badRequest,
  conflict,
  corsHeaders,
  forbidden,
  internalError,
  ok,
  requireAuth,
} from '../_shared/auth.ts';
import { ValidationError } from '../_shared/validate.ts';
import {
  selectSyntheticSurvivors,
  type SyntheticLayerSignal,
} from '../_shared/synthetic_engine2_funnel.ts';

// This endpoint is intentionally a synthetic-cloud-showcase boundary. It is
// never given a child ID, guardian ID, name, intake text, theme text, or a
// production session ID. The anonymous Auth user is only a short-lived bucket
// for a fictional builder-run demonstration.

// Layer 1 visits this exact 30-sector breadth catalogue once. The sector ID
// describes the interaction mechanic, never a child-facing label or a
// conclusion about a person. All stages remain word-free visual play.
const sectors = [
  // Spatial / visual
  'mentalRotation',
  'visualPatternCompletion',
  'pointCloudAnomalyDetection',
  'mapRouteNavigation',
  'visualSpatialConstruction',
  // Temporal / sequential
  'chronologicalSequencing',
  'narrativeEventOrdering',
  'causeAndEffectChains',
  'rhythmicMotorSequencing',
  'proceduralSequencing',
  // Numeric / logical
  'numberPatternRecognition',
  'ruleDiscovery',
  'multiAttributeSorting',
  'systemizing',
  'quantitativeEstimation',
  // Non-verbal language proxies
  'pictureAssociation',
  'phonologicalPatternRecognition',
  'wordlessInference',
  'analogyMapping',
  'creativeStorytelling',
  // Memory / attention
  'workingMemorySpan',
  'visualSceneMemory',
  'sustainedAttention',
  'auditorySequenceRecall',
  'selectiveAttention',
  // Social / creative
  'emotionRecognition',
  'perspectiveTaking',
  'turnTakingStrategy',
  'musicalPatternRecognition',
  'visualArtisticComposition',
] as const;
type Sector = typeof sectors[number];

const sectorGroups = [
  'spatialVisual',
  'temporalSequential',
  'numericLogical',
  'nonVerbalLanguage',
  'memoryAttention',
  'socialCreative',
] as const;
type SectorGroup = typeof sectorGroups[number];

const worlds = ['vehicles', 'rail', 'space', 'pipes', 'animals', 'garden'] as const;
type World = typeof worlds[number];
const colors = ['red', 'orange', 'yellow', 'green', 'blue', 'purple', 'pink', 'silver'] as const;
const objectStyles = ['simpleShapes', 'illustratedObjects', 'realWorldObjects'] as const;
const interactions = ['tapping', 'swiping', 'dragging'] as const;
// These are Flutter's allowlisted stage vocabulary. `puzzle_plan.kind` is
// the exact 30-sector mechanic; `scene_type` chooses the broad visual stage
// that renders that mechanic without any child-facing text.
const sceneTypes = [
  'match',
  'sort',
  'connect',
  'sequence',
  'route',
  'rotate',
  'distance',
  'pattern',
  'quantity',
  'shape',
  'search',
  'memory',
  'repair',
  'precision',
  'rhythm',
  'switch',
] as const;
type SceneType = typeof sceneTypes[number];

// A scene type only chooses Flutter's broad stage. These two vocabularies
// make the actual word-free activity unambiguous. They are fixed enum values,
// never model text or guardian input, so Flutter can safely render a distinct
// visual treatment for every Layer 1 sector.
const interactionPlans = [
  'tap_rotated_match',
  'tap_pattern_piece',
  'tap_outlier_point',
  'drag_map_route',
  'drag_target_pieces',
  'drag_cycle_order',
  'drag_story_order',
  'tap_effect_choice',
  'tap_rhythm_replay',
  'drag_procedure_order',
  'tap_quantity_next',
  'drag_rule_sort',
  'drag_attribute_bins',
  'tap_shared_property',
  'tap_larger_cloud',
  'tap_related_picture',
  'tap_sound_pair',
  'tap_story_outcome',
  'tap_analogy_piece',
  'drag_story_build',
  'tap_memory_cells',
  'tap_scene_difference',
  'tap_stream_target',
  'tap_tone_replay',
  'tap_hidden_target',
  'tap_emotion_icon',
  'tap_perspective_outcome',
  'tap_turn_strategy',
  'tap_melody_match',
  'drag_symmetry_piece',
] as const;
type InteractionPlan = typeof interactionPlans[number];

const stimulusTemplates = [
  'rotating_shape_match',
  'pattern_grid_gap',
  'point_cloud_odd_one_out',
  'animated_maze_path',
  'target_picture_rebuild',
  'picture_growth_cycle',
  'wordless_comic_order',
  'action_effect_scene',
  'light_pulse_pattern',
  'procedure_icon_order',
  'dot_quantity_pattern',
  'demonstrated_visual_rule',
  'multi_attribute_bins',
  'shared_property_scatter',
  'brief_dot_cloud_compare',
  'picture_concept_match',
  'nonword_sound_pair',
  'picture_story_next',
  'picture_analogy_grid',
  'wordless_story_builder',
  'lit_cell_replay',
  'scene_change_pair',
  'target_shape_stream',
  'tone_icon_replay',
  'hidden_target_field',
  'emotion_icon_scene',
  'perspective_scene_outcome',
  'turn_strategy_board',
  'melody_pattern_icons',
  'symmetry_composition',
] as const;
type StimulusTemplate = typeof stimulusTemplates[number];

// Rules are a fixed, non-verbal visual vocabulary. The server, rather than an
// LLM, owns the rule, stimulus, answer value, and target option for every
// task. This keeps a choice tied to an actual displayed puzzle plan.
const puzzleRules = [
  'matchMentalRotation',
  'completeVisualPattern',
  'detectPointCloudAnomaly',
  'navigateMapRoute',
  'reconstructSpatialTarget',
  'orderPictureCycle',
  'orderStoryPanels',
  'chooseEffect',
  'repeatRhythm',
  'orderProcedureIcons',
  'completeQuantityPattern',
  'discoverVisualRule',
  'sortMultipleAttributes',
  'findSharedProperty',
  'chooseLargerDotCloud',
  'matchPictureAssociation',
  'matchPhonologicalPattern',
  'chooseStoryNext',
  'completePictureAnalogy',
  'arrangeStoryPanels',
  'replayCellSequence',
  'findSceneChange',
  'identifyTargetStream',
  'replayToneSequence',
  'findSelectiveTarget',
  'matchEmotionIcon',
  'choosePerspectiveOutcome',
  'chooseTurnStrategy',
  'matchMelodyPattern',
  'completeVisualComposition',
] as const;
type PuzzleRule = typeof puzzleRules[number];
const layouts = ['leftToRight', 'grid', 'path'] as const;
const animations = ['none', 'slide', 'roll', 'rotate', 'snap', 'gentlePulse'] as const;
const optionIds = ['option_a', 'option_b', 'option_c', 'option_d', 'option_e'] as const;

const sectorSet = new Set<string>(sectors);
const sectorGroupSet = new Set<string>(sectorGroups);
const worldSet = new Set<string>(worlds);
const colorSet = new Set<string>(colors);
const styleSet = new Set<string>(objectStyles);
const interactionSet = new Set<string>(interactions);
const sceneTypeSet = new Set<string>(sceneTypes);
const interactionPlanSet = new Set<string>(interactionPlans);
const stimulusTemplateSet = new Set<string>(stimulusTemplates);
const layoutSet = new Set<string>(layouts);
const animationSet = new Set<string>(animations);
const optionIdSet = new Set<string>(optionIds);
const puzzleRuleSet = new Set<string>(puzzleRules);

type SectorBlueprint = {
  group: SectorGroup;
  sceneType: SceneType;
  rule: PuzzleRule;
  interaction: InteractionPlan;
  stimulusTemplate: StimulusTemplate;
};

const sectorPuzzleBlueprints: Record<Sector, SectorBlueprint> = {
  mentalRotation: {
    group: 'spatialVisual', sceneType: 'rotate', rule: 'matchMentalRotation',
    interaction: 'tap_rotated_match', stimulusTemplate: 'rotating_shape_match',
  },
  visualPatternCompletion: {
    group: 'spatialVisual', sceneType: 'pattern', rule: 'completeVisualPattern',
    interaction: 'tap_pattern_piece', stimulusTemplate: 'pattern_grid_gap',
  },
  pointCloudAnomalyDetection: {
    group: 'spatialVisual', sceneType: 'search', rule: 'detectPointCloudAnomaly',
    interaction: 'tap_outlier_point', stimulusTemplate: 'point_cloud_odd_one_out',
  },
  mapRouteNavigation: {
    group: 'spatialVisual', sceneType: 'route', rule: 'navigateMapRoute',
    interaction: 'drag_map_route', stimulusTemplate: 'animated_maze_path',
  },
  visualSpatialConstruction: {
    group: 'spatialVisual', sceneType: 'connect', rule: 'reconstructSpatialTarget',
    interaction: 'drag_target_pieces', stimulusTemplate: 'target_picture_rebuild',
  },
  chronologicalSequencing: {
    group: 'temporalSequential', sceneType: 'sequence', rule: 'orderPictureCycle',
    interaction: 'drag_cycle_order', stimulusTemplate: 'picture_growth_cycle',
  },
  narrativeEventOrdering: {
    group: 'temporalSequential', sceneType: 'sequence', rule: 'orderStoryPanels',
    interaction: 'drag_story_order', stimulusTemplate: 'wordless_comic_order',
  },
  causeAndEffectChains: {
    group: 'temporalSequential', sceneType: 'repair', rule: 'chooseEffect',
    interaction: 'tap_effect_choice', stimulusTemplate: 'action_effect_scene',
  },
  rhythmicMotorSequencing: {
    group: 'temporalSequential', sceneType: 'rhythm', rule: 'repeatRhythm',
    interaction: 'tap_rhythm_replay', stimulusTemplate: 'light_pulse_pattern',
  },
  proceduralSequencing: {
    group: 'temporalSequential', sceneType: 'sequence', rule: 'orderProcedureIcons',
    interaction: 'drag_procedure_order', stimulusTemplate: 'procedure_icon_order',
  },
  numberPatternRecognition: {
    group: 'numericLogical', sceneType: 'pattern', rule: 'completeQuantityPattern',
    interaction: 'tap_quantity_next', stimulusTemplate: 'dot_quantity_pattern',
  },
  ruleDiscovery: {
    group: 'numericLogical', sceneType: 'sort', rule: 'discoverVisualRule',
    interaction: 'drag_rule_sort', stimulusTemplate: 'demonstrated_visual_rule',
  },
  multiAttributeSorting: {
    group: 'numericLogical', sceneType: 'sort', rule: 'sortMultipleAttributes',
    interaction: 'drag_attribute_bins', stimulusTemplate: 'multi_attribute_bins',
  },
  systemizing: {
    group: 'numericLogical', sceneType: 'search', rule: 'findSharedProperty',
    interaction: 'tap_shared_property', stimulusTemplate: 'shared_property_scatter',
  },
  quantitativeEstimation: {
    group: 'numericLogical', sceneType: 'quantity', rule: 'chooseLargerDotCloud',
    interaction: 'tap_larger_cloud', stimulusTemplate: 'brief_dot_cloud_compare',
  },
  pictureAssociation: {
    group: 'nonVerbalLanguage', sceneType: 'match', rule: 'matchPictureAssociation',
    interaction: 'tap_related_picture', stimulusTemplate: 'picture_concept_match',
  },
  phonologicalPatternRecognition: {
    group: 'nonVerbalLanguage', sceneType: 'rhythm', rule: 'matchPhonologicalPattern',
    interaction: 'tap_sound_pair', stimulusTemplate: 'nonword_sound_pair',
  },
  wordlessInference: {
    group: 'nonVerbalLanguage', sceneType: 'sequence', rule: 'chooseStoryNext',
    interaction: 'tap_story_outcome', stimulusTemplate: 'picture_story_next',
  },
  analogyMapping: {
    group: 'nonVerbalLanguage', sceneType: 'match', rule: 'completePictureAnalogy',
    interaction: 'tap_analogy_piece', stimulusTemplate: 'picture_analogy_grid',
  },
  creativeStorytelling: {
    group: 'nonVerbalLanguage', sceneType: 'connect', rule: 'arrangeStoryPanels',
    interaction: 'drag_story_build', stimulusTemplate: 'wordless_story_builder',
  },
  workingMemorySpan: {
    group: 'memoryAttention', sceneType: 'memory', rule: 'replayCellSequence',
    interaction: 'tap_memory_cells', stimulusTemplate: 'lit_cell_replay',
  },
  visualSceneMemory: {
    group: 'memoryAttention', sceneType: 'memory', rule: 'findSceneChange',
    interaction: 'tap_scene_difference', stimulusTemplate: 'scene_change_pair',
  },
  sustainedAttention: {
    group: 'memoryAttention', sceneType: 'search', rule: 'identifyTargetStream',
    interaction: 'tap_stream_target', stimulusTemplate: 'target_shape_stream',
  },
  auditorySequenceRecall: {
    group: 'memoryAttention', sceneType: 'rhythm', rule: 'replayToneSequence',
    interaction: 'tap_tone_replay', stimulusTemplate: 'tone_icon_replay',
  },
  selectiveAttention: {
    group: 'memoryAttention', sceneType: 'search', rule: 'findSelectiveTarget',
    interaction: 'tap_hidden_target', stimulusTemplate: 'hidden_target_field',
  },
  emotionRecognition: {
    group: 'socialCreative', sceneType: 'match', rule: 'matchEmotionIcon',
    interaction: 'tap_emotion_icon', stimulusTemplate: 'emotion_icon_scene',
  },
  perspectiveTaking: {
    group: 'socialCreative', sceneType: 'sequence', rule: 'choosePerspectiveOutcome',
    interaction: 'tap_perspective_outcome', stimulusTemplate: 'perspective_scene_outcome',
  },
  turnTakingStrategy: {
    group: 'socialCreative', sceneType: 'switch', rule: 'chooseTurnStrategy',
    interaction: 'tap_turn_strategy', stimulusTemplate: 'turn_strategy_board',
  },
  musicalPatternRecognition: {
    group: 'socialCreative', sceneType: 'rhythm', rule: 'matchMelodyPattern',
    interaction: 'tap_melody_match', stimulusTemplate: 'melody_pattern_icons',
  },
  visualArtisticComposition: {
    group: 'socialCreative', sceneType: 'shape', rule: 'completeVisualComposition',
    interaction: 'drag_symmetry_piece', stimulusTemplate: 'symmetry_composition',
  },
};

// Keep the Layer 1 breadth catalogue fail-closed. A future edit cannot
// silently collapse a sector into a generic colour/shape task: every one of
// the exact thirty sectors must retain a rule, interaction and visual
// template of its own before this Edge Function can serve a task.
function validateSectorPuzzleBlueprintCatalogue(): void {
  const blueprints = sectors.map((sector) => sectorPuzzleBlueprints[sector]);
  if (sectors.length !== 30 || blueprints.length !== 30 ||
      blueprints.some((blueprint) => !blueprint ||
        !sectorGroupSet.has(blueprint.group) ||
        !sceneTypeSet.has(blueprint.sceneType) ||
        !puzzleRuleSet.has(blueprint.rule) ||
        !interactionPlanSet.has(blueprint.interaction) ||
        !stimulusTemplateSet.has(blueprint.stimulusTemplate))) {
    throw new Error('Synthetic Engine 2 Layer 1 catalogue is invalid.');
  }
  if (new Set(blueprints.map((blueprint) => blueprint.rule)).size !== sectors.length ||
      new Set(blueprints.map((blueprint) => blueprint.interaction)).size !== sectors.length ||
      new Set(blueprints.map((blueprint) => blueprint.stimulusTemplate)).size !== sectors.length) {
    throw new Error('Synthetic Engine 2 Layer 1 catalogue must keep one plan per sector.');
  }
}

validateSectorPuzzleBlueprintCatalogue();

type VisualPreferences = {
  world: World;
  palette: string[];
  objectStyle: string;
  motionAllowed: boolean;
  allowDistractors: boolean;
  interaction: string;
};

type Telemetry = {
  latencyMs: number;
  misclicks: number;
  recoveredErrors: number;
  interactions: number;
  supportLevel: number;
};

type AggregatedTelemetry = Telemetry & { attemptCount: number };

type StartRequest = { action: 'start'; visual: VisualPreferences };
type TaskResponseRequest = {
  sessionId: string;
  taskId: string;
  sector: Sector;
  layer: number;
  telemetry: Telemetry;
};
type AnswerRequest = TaskResponseRequest & {
  action: 'answer';
  optionId: string;
};
// A skip is a final, non-correct response for an already-issued synthetic
// task. It has no option or free-text field, so a client cannot turn an idle
// timeout into an answer submission.
type SkipRequest = TaskResponseRequest & { action: 'skip' };
type DemoRequest = StartRequest | AnswerRequest | SkipRequest;

type PuzzlePlan = {
  version: 1;
  sector: Sector;
  group: SectorGroup;
  sceneType: SceneType;
  rule: PuzzleRule;
  /// Exact fixed interaction for this sector (for example a drag route vs a
  /// rhythm replay). This is independent from the guardian's preferred input
  /// modality, which remains in `visual.interaction` for sensory adaptation.
  interaction: InteractionPlan;
  /// Fixed word-free visual treatment used by Flutter to select a distinct
  /// scene composition inside the broader renderer stage.
  stimulusTemplate: StimulusTemplate;
  variant: number;
  stimulus: number[];
  optionValues: number[];
  answerValue: number;
  targetIndex: number;
};

/// The optional LLM is intentionally limited to visual skin. It cannot
/// choose the sector, puzzle rule, answer, options, or item count.
type GeneratedSkin = {
  sector: Sector;
  layout: string;
  onTap: string;
  success: string;
};

type SessionRow = {
  id: string;
  anonymous_user_id: string;
  status: 'in_progress' | 'complete' | 'expired';
  current_layer: number;
  active_sectors: unknown;
  pending_sectors: unknown;
  visual_preferences: unknown;
  final_sector: string | null;
  final_sandbox: string | null;
  expires_at: string;
};

type TaskRow = {
  id: string;
  session_id: string;
  anonymous_user_id: string;
  layer: number;
  sequence_index: number;
  sector: Sector;
  status: 'queued' | 'issued' | 'completed';
  source: 'openai' | 'fallback';
  task_payload: unknown;
};

type EventRow = {
  sector: Sector;
  isolation_score: number | string;
  support_level: number | string;
};

type AttemptRow = {
  correct: boolean;
  latency_ms: number | string;
  support_level: number | string;
};

class QuotaExceededError extends Error {
  constructor() {
    super('The synthetic cloud demo request limit has been reached. Please try again later.');
    this.name = 'QuotaExceededError';
  }
}

function asRecord(value: unknown, field: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ValidationError(`${field} must be an object.`);
  }
  return value as Record<string, unknown>;
}

function requireExactKeys(
  value: Record<string, unknown>,
  keys: readonly string[],
  field: string,
): void {
  if (Object.keys(value).some((key) => !keys.includes(key))) {
    throw new ValidationError(`${field} contains an unsupported field.`);
  }
  if (keys.some((key) => !(key in value))) {
    throw new ValidationError(`${field} is missing a required field.`);
  }
}

function requireInteger(value: unknown, field: string, min: number, max: number): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max) {
    throw new ValidationError(`${field} must be an integer from ${min} to ${max}.`);
  }
  return value;
}

function requireUuid(value: unknown, field: string): string {
  if (typeof value !== 'string' ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) {
    throw new ValidationError(`${field} must be a UUID.`);
  }
  return value;
}

function requireEnum<T extends string>(value: unknown, allowed: Set<string>, field: string): T {
  if (typeof value !== 'string' || !allowed.has(value)) {
    throw new ValidationError(`${field} is invalid.`);
  }
  return value as T;
}

function parseVisual(value: unknown): VisualPreferences {
  const raw = asRecord(value, 'visual');
  requireExactKeys(
    raw,
    ['world', 'palette', 'object_style', 'motion_allowed', 'allow_distractors', 'interaction'],
    'visual',
  );
  const palette = raw.palette;
  if (!Array.isArray(palette) || palette.length < 1 || palette.length > 3 ||
      palette.some((item) => typeof item !== 'string' || !colorSet.has(item)) ||
      new Set(palette).size !== palette.length) {
    throw new ValidationError('visual.palette must contain one to three distinct allowed colours.');
  }
  if (typeof raw.motion_allowed !== 'boolean' || typeof raw.allow_distractors !== 'boolean') {
    throw new ValidationError('visual motion and distractor settings must be booleans.');
  }
  return {
    world: requireEnum<World>(raw.world, worldSet, 'visual.world'),
    palette: [...palette] as string[],
    objectStyle: requireEnum<string>(raw.object_style, styleSet, 'visual.object_style'),
    motionAllowed: raw.motion_allowed,
    allowDistractors: raw.allow_distractors,
    interaction: requireEnum<string>(raw.interaction, interactionSet, 'visual.interaction'),
  };
}

function parseTelemetry(value: unknown): Telemetry {
  const raw = asRecord(value, 'telemetry');
  requireExactKeys(
    raw,
    ['latency_ms', 'misclicks', 'recovered_errors', 'interactions', 'support_level'],
    'telemetry',
  );
  const misclicks = requireInteger(raw.misclicks, 'telemetry.misclicks', 0, 50);
  const recoveredErrors = requireInteger(
    raw.recovered_errors,
    'telemetry.recovered_errors',
    0,
    50,
  );
  if (recoveredErrors > misclicks) {
    throw new ValidationError('telemetry.recovered_errors cannot exceed telemetry.misclicks.');
  }
  const interactions = requireInteger(raw.interactions, 'telemetry.interactions', 1, 100);
  if (misclicks > interactions) {
    throw new ValidationError('telemetry.misclicks cannot exceed telemetry.interactions.');
  }
  return {
    latencyMs: requireInteger(raw.latency_ms, 'telemetry.latency_ms', 0, 600000),
    misclicks,
    recoveredErrors,
    interactions,
    supportLevel: requireInteger(raw.support_level, 'telemetry.support_level', 0, 3),
  };
}

function parseRequest(value: unknown): DemoRequest {
  const body = asRecord(value, 'request');
  const action = body.action;
  if (action === 'start') {
    requireExactKeys(body, ['action', 'visual'], 'request');
    return { action, visual: parseVisual(body.visual) };
  }
  if (action === 'answer') {
    requireExactKeys(
      body,
      ['action', 'session_id', 'task_id', 'sector', 'layer', 'option_id', 'telemetry'],
      'request',
    );
    return {
      action,
      sessionId: requireUuid(body.session_id, 'session_id'),
      taskId: requireUuid(body.task_id, 'task_id'),
      sector: requireEnum<Sector>(body.sector, sectorSet, 'sector'),
      layer: requireInteger(body.layer, 'layer', 1, 10),
      optionId: requireEnum<string>(body.option_id, optionIdSet, 'option_id'),
      telemetry: parseTelemetry(body.telemetry),
    };
  }
  if (action === 'skip') {
    requireExactKeys(
      body,
      ['action', 'session_id', 'task_id', 'sector', 'layer', 'telemetry'],
      'request',
    );
    return {
      action,
      sessionId: requireUuid(body.session_id, 'session_id'),
      taskId: requireUuid(body.task_id, 'task_id'),
      sector: requireEnum<Sector>(body.sector, sectorSet, 'sector'),
      layer: requireInteger(body.layer, 'layer', 1, 10),
      telemetry: parseTelemetry(body.telemetry),
    };
  }
  throw new ValidationError('action must be start, answer, or skip.');
}

function asSectorList(value: unknown): Sector[] {
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== 'string' || !sectorSet.has(entry))) {
    throw new Error('Stored synthetic demo sectors are invalid.');
  }
  const list = value as Sector[];
  if (new Set(list).size !== list.length) throw new Error('Stored synthetic demo sectors are duplicated.');
  return [...list];
}

function asVisualPreferences(value: unknown): VisualPreferences {
  const raw = asRecord(value, 'stored visual preferences');
  return parseVisual({
    world: raw.world,
    palette: raw.palette,
    object_style: raw.object_style,
    motion_allowed: raw.motion_allowed,
    allow_distractors: raw.allow_distractors,
    interaction: raw.interaction,
  });
}

function sameVisualPreferences(
  left: VisualPreferences,
  right: VisualPreferences,
): boolean {
  return left.world === right.world &&
    left.objectStyle === right.objectStyle &&
    left.motionAllowed === right.motionAllowed &&
    left.allowDistractors === right.allowDistractors &&
    left.interaction === right.interaction &&
    left.palette.length === right.palette.length &&
    left.palette.every((colour, index) => colour === right.palette[index]);
}

function fnv1a(input: string): number {
  let hash = 0x811c9dc5;
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return hash >>> 0;
}

function orderedSectors(seed: string): Sector[] {
  return [...sectors].sort((a, b) => {
    const compare = fnv1a(`${seed}:${a}`) - fnv1a(`${seed}:${b}`);
    return compare !== 0 ? compare : a.localeCompare(b);
  });
}

function speedBudgetFor(layer: number): number {
  return ({
    1: 12000,
    2: 12000,
    3: 10500,
    4: 9000,
    5: 8000,
    6: 7000,
    7: 6200,
    8: 5500,
    9: 4800,
    10: 4200,
  } as Record<number, number>)[layer] ?? 12000;
}

function defaultItemCount(layer: number): number {
  if (layer === 1) return 3;
  if (layer <= 3) return 4;
  return 5;
}

function itemCountFitsLayer(itemCount: number, layer: number): boolean {
  if (layer === 1) return itemCount === 3;
  if (layer <= 3) return itemCount >= 3 && itemCount <= 4;
  return itemCount >= 4 && itemCount <= 5;
}

function seededValue(seed: string, salt: string, modulo = 12): number {
  return fnv1a(`${seed}:${salt}`) % modulo;
}

function at(values: readonly number[], index: number): number {
  return values[index] ?? 0;
}

function differentValue(value: number, seed: string, modulo = 12): number {
  return (value + 1 + seededValue(seed, 'different', modulo - 1)) % modulo;
}

function stimulusForRule(rule: PuzzleRule, seed: string): number[] {
  const a = seededValue(seed, 'a');
  const b = differentValue(a, `${seed}:b`);
  const c = differentValue(b, `${seed}:c`);
  switch (rule) {
    // Spatial / visual
    case 'matchMentalRotation': return [a % 8];
    case 'completeVisualPattern': return [a % 8, b % 8, a % 8];
    case 'detectPointCloudAnomaly': return [a % 8, b % 8, c % 8];
    case 'navigateMapRoute': return [a % 12, b % 12, c % 12];
    case 'reconstructSpatialTarget': return [a % 4, b % 4];
    // Temporal / sequential
    case 'orderPictureCycle': return [a % 9, (a + 1) % 9, (a + 2) % 9];
    case 'orderStoryPanels': return [a % 10, b % 10];
    case 'chooseEffect': return [a % 10];
    case 'repeatRhythm': return [a % 4, b % 4, a % 4];
    case 'orderProcedureIcons': return [a % 6, b % 6, c % 6];
    // Numeric / logical
    case 'completeQuantityPattern': return [a % 5 + 1, b % 5 + 1, a % 5 + 1];
    case 'discoverVisualRule': return [a % 6, b % 6];
    case 'sortMultipleAttributes': return [a % 4, b % 4, c % 4];
    case 'findSharedProperty': return [a % 6, b % 6, c % 6];
    case 'chooseLargerDotCloud': {
      const firstCount = a % 5 + 1;
      // The two clouds must never contain the same number of dots; otherwise
      // the word-free comparison would be ambiguous. A one-to-four step on a
      // five-value ring guarantees a distinct bounded count.
      const step = 1 + seededValue(seed, 'larger-dot-cloud', 4);
      const secondCount = ((firstCount - 1 + step) % 5) + 1;
      return [firstCount, secondCount];
    }
    // Non-verbal language proxies
    case 'matchPictureAssociation': return [a % 6];
    case 'matchPhonologicalPattern': return [a % 6, b % 6];
    case 'chooseStoryNext': return [a % 10, b % 10];
    case 'completePictureAnalogy': return [a % 4, b % 4];
    case 'arrangeStoryPanels': return [a % 6, b % 6, c % 6];
    // Memory / attention
    case 'replayCellSequence': return [a % 4, b % 4, c % 4];
    case 'findSceneChange': return [a % 8, b % 8];
    case 'identifyTargetStream': return [a % 8, b % 8, c % 8];
    case 'replayToneSequence': return [a % 6, b % 6, c % 6];
    case 'findSelectiveTarget': return [a % 8, b % 8, c % 8];
    // Social / creative
    case 'matchEmotionIcon': return [a % 6];
    case 'choosePerspectiveOutcome': return [a % 10, b % 10];
    case 'chooseTurnStrategy': return [a % 4];
    case 'matchMelodyPattern': return [a % 6, b % 6, a % 6];
    case 'completeVisualComposition': return [a % 4, b % 4];
  }
}

function answerForRule(rule: PuzzleRule, stimulus: readonly number[]): number {
  switch (rule) {
    // Spatial / visual
    case 'matchMentalRotation': return at(stimulus, 0);
    case 'completeVisualPattern': return at(stimulus, 0);
    case 'detectPointCloudAnomaly': return at(stimulus, 2);
    case 'navigateMapRoute': return (at(stimulus, 0) + at(stimulus, 1) + at(stimulus, 2)) % 12;
    case 'reconstructSpatialTarget': return (at(stimulus, 0) + at(stimulus, 1)) % 8;
    // Temporal / sequential
    case 'orderPictureCycle': return (at(stimulus, 2) + 1) % 9;
    case 'orderStoryPanels': return (at(stimulus, 1) + 1) % 10;
    case 'chooseEffect': return (at(stimulus, 0) + 2) % 12;
    case 'repeatRhythm': return at(stimulus, 1);
    case 'orderProcedureIcons': return (at(stimulus, 0) + at(stimulus, 1) + at(stimulus, 2)) % 12;
    // Numeric / logical
    case 'completeQuantityPattern': return at(stimulus, 1);
    case 'discoverVisualRule': return at(stimulus, 0);
    case 'sortMultipleAttributes': return at(stimulus, 0) * 4 + at(stimulus, 1);
    case 'findSharedProperty': return at(stimulus, 0);
    case 'chooseLargerDotCloud': return Math.max(at(stimulus, 0), at(stimulus, 1));
    // Non-verbal language proxies
    case 'matchPictureAssociation': return at(stimulus, 0);
    case 'matchPhonologicalPattern': return at(stimulus, 0);
    case 'chooseStoryNext': return (at(stimulus, 1) + 1) % 10;
    case 'completePictureAnalogy': return at(stimulus, 0) * 4 + at(stimulus, 1);
    case 'arrangeStoryPanels': return (at(stimulus, 0) + at(stimulus, 1) + at(stimulus, 2)) % 12;
    // Memory / attention
    case 'replayCellSequence': return (at(stimulus, 0) * 2 + at(stimulus, 1) + at(stimulus, 2)) % 12;
    case 'findSceneChange': return at(stimulus, 1);
    case 'identifyTargetStream': return at(stimulus, 0);
    case 'replayToneSequence': return at(stimulus, 1);
    case 'findSelectiveTarget': return at(stimulus, 0);
    // Social / creative
    case 'matchEmotionIcon': return at(stimulus, 0);
    case 'choosePerspectiveOutcome': return (at(stimulus, 1) + 2) % 12;
    case 'chooseTurnStrategy': return at(stimulus, 0);
    case 'matchMelodyPattern': return at(stimulus, 1);
    case 'completeVisualComposition': return (at(stimulus, 0) + at(stimulus, 1)) % 8;
  }
}

function optionValuesFor(
  answerValue: number,
  itemCount: number,
  seed: string,
): { optionValues: number[]; targetIndex: number } {
  const distractors: number[] = [];
  const used = new Set<number>([answerValue]);
  let salt = 0;
  while (distractors.length < itemCount - 1) {
    const candidate = seededValue(seed, `option:${salt}`, 16);
    salt += 1;
    if (used.has(candidate)) continue;
    used.add(candidate);
    distractors.push(candidate);
  }
  const targetIndex = seededValue(seed, 'target-index', itemCount);
  const optionValues = [...distractors];
  optionValues.splice(targetIndex, 0, answerValue);
  return { optionValues, targetIndex };
}

function validatePuzzlePlan(plan: PuzzlePlan, layer: number): void {
  if (plan.version !== 1) throw new Error('Synthetic puzzle plan has an invalid version.');
  const blueprint = sectorPuzzleBlueprints[plan.sector];
  if (!blueprint || !sectorGroupSet.has(plan.group) || !sceneTypeSet.has(plan.sceneType) ||
      !puzzleRuleSet.has(plan.rule) || !interactionPlanSet.has(plan.interaction) ||
      !stimulusTemplateSet.has(plan.stimulusTemplate) || plan.group !== blueprint.group ||
      plan.sceneType !== blueprint.sceneType || plan.rule !== blueprint.rule ||
      plan.interaction !== blueprint.interaction ||
      plan.stimulusTemplate !== blueprint.stimulusTemplate) {
    throw new Error('Synthetic puzzle plan does not match its assigned sector.');
  }
  if (!itemCountFitsLayer(plan.optionValues.length, layer)) {
    throw new Error('Synthetic puzzle plan has an invalid option count.');
  }
  if (!Number.isInteger(plan.variant) || plan.variant < 0 || plan.variant > 7 ||
      !Number.isInteger(plan.answerValue) || plan.answerValue < 0 || plan.answerValue > 15 ||
      !Number.isInteger(plan.targetIndex) || plan.targetIndex < 0 || plan.targetIndex >= plan.optionValues.length ||
      plan.stimulus.length < 1 || plan.stimulus.length > 6 ||
      plan.stimulus.some((value) => !Number.isInteger(value) || value < 0 || value > 15) ||
      plan.optionValues.some((value) => !Number.isInteger(value) || value < 0 || value > 15) ||
      new Set(plan.optionValues).size !== plan.optionValues.length) {
    throw new Error('Synthetic puzzle plan contains invalid primitive values.');
  }
  if (plan.optionValues[plan.targetIndex] !== plan.answerValue ||
      answerForRule(plan.rule, plan.stimulus) !== plan.answerValue) {
    throw new Error('Synthetic puzzle plan answer is not derived from its rule.');
  }
}

function createPuzzlePlan(sector: Sector, layer: number, seed: string): PuzzlePlan {
  const blueprint = sectorPuzzleBlueprints[sector];
  const planSeed = `${seed}:${sector}:layer:${layer}`;
  const stimulus = stimulusForRule(blueprint.rule, planSeed);
  const answerValue = answerForRule(blueprint.rule, stimulus);
  const { optionValues, targetIndex } = optionValuesFor(
    answerValue,
    defaultItemCount(layer),
    planSeed,
  );
  const plan: PuzzlePlan = {
    version: 1,
    sector,
    group: blueprint.group,
    sceneType: blueprint.sceneType,
    rule: blueprint.rule,
    interaction: blueprint.interaction,
    stimulusTemplate: blueprint.stimulusTemplate,
    variant: seededValue(planSeed, 'variant', 8),
    stimulus,
    optionValues,
    answerValue,
    targetIndex,
  };
  validatePuzzlePlan(plan, layer);
  return plan;
}

function fallbackSkin(
  sector: Sector,
  layer: number,
  preferences: VisualPreferences,
  seed: string,
): GeneratedSkin {
  const skinSeed = fnv1a(`${seed}:${sector}:${layer}:${preferences.world}`);
  const onTap = preferences.motionAllowed
    ? animations[1 + (skinSeed % (animations.length - 1))]
    : 'none';
  const success = preferences.motionAllowed
    ? animations[1 + (Math.floor(skinSeed / 7) % (animations.length - 1))]
    : 'none';
  return {
    sector,
    layout: layouts[skinSeed % layouts.length],
    onTap,
    success,
  };
}

function skinSchema(activeSectors: Sector[], motionAllowed: boolean): Record<string, unknown> {
  return {
    name: 'mindbridge_synthetic_engine2_layer_skin',
    strict: true,
    schema: {
      type: 'object',
      additionalProperties: false,
      required: ['skins'],
      properties: {
        skins: {
          type: 'array',
          minItems: activeSectors.length,
          maxItems: activeSectors.length,
          items: {
            type: 'object',
            additionalProperties: false,
            required: ['sector', 'layout', 'animation'],
            properties: {
              sector: { type: 'string', enum: activeSectors },
              layout: { type: 'string', enum: layouts },
              animation: {
                type: 'object',
                additionalProperties: false,
                required: ['on_tap', 'success'],
                properties: {
                  on_tap: { type: 'string', enum: motionAllowed ? animations : ['none'] },
                  success: { type: 'string', enum: motionAllowed ? animations : ['none'] },
                },
              },
            },
          },
        },
      },
    },
  };
}

function outputText(value: unknown): string | null {
  const raw = value as Record<string, unknown>;
  if (typeof raw?.output_text === 'string' && raw.output_text.trim()) return raw.output_text;
  if (!Array.isArray(raw?.output)) return null;
  for (const item of raw.output) {
    if (!item || typeof item !== 'object') continue;
    const content = (item as Record<string, unknown>).content;
    if (!Array.isArray(content)) continue;
    for (const part of content) {
      if (!part || typeof part !== 'object') continue;
      const text = (part as Record<string, unknown>).text;
      if (typeof text === 'string' && text.trim()) return text;
    }
  }
  return null;
}

function parseGeneratedSkins(
  value: unknown,
  activeSectors: Sector[],
  preferences: VisualPreferences,
): GeneratedSkin[] {
  const raw = asRecord(value, 'generated skin batch');
  requireExactKeys(raw, ['skins'], 'generated skin batch');
  if (!Array.isArray(raw.skins) || raw.skins.length !== activeSectors.length) {
    throw new ValidationError('Generated skin batch has an invalid skin count.');
  }
  const bySector = new Map<Sector, GeneratedSkin>();
  for (const entry of raw.skins) {
    const skin = asRecord(entry, 'generated skin');
    requireExactKeys(
      skin,
      ['sector', 'layout', 'animation'],
      'generated skin',
    );
    const sector = requireEnum<Sector>(skin.sector, sectorSet, 'generated skin sector');
    if (!activeSectors.includes(sector) || bySector.has(sector)) {
      throw new ValidationError('Generated skin batch does not match the active sectors.');
    }
    const layout = requireEnum<string>(skin.layout, layoutSet, 'generated layout');
    const animation = asRecord(skin.animation, 'generated animation');
    requireExactKeys(animation, ['on_tap', 'success'], 'generated animation');
    const allowedAnimations = preferences.motionAllowed ? animationSet : new Set(['none']);
    const onTap = requireEnum<string>(animation.on_tap, allowedAnimations, 'generated on_tap animation');
    const success = requireEnum<string>(animation.success, allowedAnimations, 'generated success animation');
    bySector.set(sector, {
      sector,
      layout,
      onTap,
      success,
    });
  }
  return activeSectors.map((sector) => {
    const skin = bySector.get(sector);
    if (!skin) throw new ValidationError('Generated skin batch is incomplete.');
    return skin;
  });
}

function openAiEndpoint(): string {
  const configured = (Deno.env.get('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1').replace(/\/$/, '');
  if (configured.endsWith('/responses')) return configured;
  if (configured.endsWith('/chat/completions')) return `${configured.slice(0, -'/chat/completions'.length)}/responses`;
  return `${configured}/responses`;
}

async function generateLayerWithOpenAi(
  activeSectors: Sector[],
  layer: number,
  preferences: VisualPreferences,
  seed: string,
): Promise<{ skins: GeneratedSkin[]; source: 'openai' | 'fallback' }> {
  const fallback = {
    skins: activeSectors.map((sector) => fallbackSkin(sector, layer, preferences, seed)),
    source: 'fallback' as const,
  };
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  const model = Deno.env.get('OPENAI_MODEL');
  if (!apiKey || !model) return fallback;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 18000);
  try {
    const response = await fetch(openAiEndpoint(), {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        store: false,
        temperature: 0.2,
        max_output_tokens: Math.min(4000, 500 + activeSectors.length * 100),
        input: [
          {
            role: 'system',
            content: [
              {
                type: 'input_text',
                text: 'Generate only the requested strict JSON for fictional, non-verbal visual play scene SKINS. Return one layout and two animation names for each supplied sector. Do not evaluate, rank, predict, diagnose, profile, mention abilities, write instructions, include people, faces, brands, copyrighted characters, weapons, unsafe content, personal data, or text labels. Never choose or alter a puzzle rule, scene type, option, answer, difficulty, or sector: the deterministic server owns all puzzle logic.',
              },
            ],
          },
          {
            role: 'user',
            content: [
              {
                type: 'input_text',
                text: JSON.stringify({
                  fictional_demo: true,
                  layer,
                  active_sectors: activeSectors,
                  visual: {
                    world: preferences.world,
                    palette: preferences.palette,
                    object_style: preferences.objectStyle,
                    motion_allowed: preferences.motionAllowed,
                    allow_distractors: preferences.allowDistractors,
                    interaction: preferences.interaction,
                  },
                  task: 'skin_only',
                }),
              },
            ],
          },
        ],
        text: { format: { type: 'json_schema', ...skinSchema(activeSectors, preferences.motionAllowed) } },
      }),
    });
    if (!response.ok) {
      console.warn('[synthetic-engine2-next-task] OpenAI returned:', response.status);
      return fallback;
    }
    const responseBody = await response.json();
    const text = outputText(responseBody);
    if (!text) return fallback;
    return {
      skins: parseGeneratedSkins(JSON.parse(text), activeSectors, preferences),
      source: 'openai',
    };
  } catch (error) {
    console.warn('[synthetic-engine2-next-task] OpenAI generation failed; using fallback.');
    return fallback;
  } finally {
    clearTimeout(timeout);
  }
}

function rateLimit(): number {
  const raw = Number(Deno.env.get('SYNTHETIC_ENGINE2_RATE_LIMIT_PER_HOUR') ?? '100');
  return Number.isInteger(raw) && raw >= 76 && raw <= 200 ? raw : 100;
}

async function consumeQuota(serviceClient: { rpc: Function }, userId: string): Promise<void> {
  const { data, error } = await serviceClient.rpc('consume_synthetic_engine2_demo_quota', {
    p_user_id: userId,
    p_limit: rateLimit(),
  });
  if (error) {
    console.error('[synthetic-engine2-next-task] quota check failed');
    throw new Error('Synthetic demo quota is unavailable.');
  }
  if (data !== true) throw new QuotaExceededError();
}

function taskPayload(
  plan: PuzzlePlan,
  skin: GeneratedSkin,
  layer: number,
  preferences: VisualPreferences,
): Record<string, unknown> {
  validatePuzzlePlan(plan, layer);
  const options = optionIds.slice(0, plan.optionValues.length);
  const correctOption = options[plan.targetIndex];
  if (!correctOption) throw new Error('Synthetic puzzle plan has no derived correct option.');
  const showsDistractors = layer >= 6 && preferences.allowDistractors;
  return {
    sector: plan.sector,
    sector_group: plan.group,
    layer,
    difficulty: layer,
    item_count: plan.optionValues.length,
    shows_distractors: showsDistractors,
    speed_budget_ms: speedBudgetFor(layer),
    visual: {
      world: preferences.world,
      palette: preferences.palette,
      object_style: preferences.objectStyle,
      motion_allowed: preferences.motionAllowed,
      allow_distractors: preferences.allowDistractors,
      interaction: preferences.interaction,
    },
    scene: {
      scene_type: plan.sceneType,
      subject: preferences.world,
      palette: preferences.palette,
      object_style: preferences.objectStyle,
      layout: skin.layout,
      item_count: plan.optionValues.length,
      animation: { on_tap: skin.onTap, success: skin.success },
      show_text: false,
      // This plan is restricted to allowlisted enum strings and bounded
      // numeric primitives. Flutter renders it; OpenAI never creates or
      // changes it.
      puzzle_plan: {
        version: plan.version,
        kind: plan.sector,
        sector_group: plan.group,
        scene_type: plan.sceneType,
        rule: plan.rule,
        interaction: plan.interaction,
        stimulus_template: plan.stimulusTemplate,
        variant: plan.variant,
        stimulus: plan.stimulus,
        option_values: plan.optionValues,
        answer_value: plan.answerValue,
        target_index: plan.targetIndex,
      },
    },
    options,
    correct_option: correctOption,
  };
}

function publicTask(task: TaskRow): Record<string, unknown> {
  const payload = asRecord(task.task_payload, 'stored task payload');
  return { id: task.id, ...payload };
}

function sandboxForSector(sector: Sector): 'calendar' | 'constellation' | 'exploring' {
  if (new Set<Sector>([
    'chronologicalSequencing', 'narrativeEventOrdering',
    'causeAndEffectChains', 'proceduralSequencing',
  ]).has(sector)) return 'calendar';
  if (new Set<Sector>([
    'mentalRotation', 'pointCloudAnomalyDetection',
    'mapRouteNavigation', 'visualSpatialConstruction',
  ]).has(sector)) return 'constellation';
  return 'exploring';
}

function scoreFinalTelemetry(
  telemetry: AggregatedTelemetry,
  layer: number,
  correct: boolean,
): {
  accuracy: number;
  recovery: number;
  engagement: number;
  speed: number;
  isolationScore: number;
} {
  // A completed answer has one server-validated correct final selection. A
  // skip is final too, but is never turned into a correct/recovered response
  // claim. Its bounded interaction and timing aggregates still contribute to
  // the existing response-signal formula below.
  const accuracy = correct ? clamp(1 / telemetry.attemptCount) : 0;
  const recovery = correct
    ? (telemetry.misclicks === 0
      ? 1
      : clamp(telemetry.recoveredErrors / telemetry.misclicks))
    : 0;
  // Engagement is deliberately bounded and distinct from speed/accuracy: a
  // second sustained attempt can lift the interaction signal, while heavy
  // Support Ladder use lowers the independence part of that signal. For a
  // skip, use only the supplied aggregate rather than inventing an answer
  // attempt count.
  const interactionSignal = clamp(
    (correct ? telemetry.attemptCount : telemetry.interactions) / 2,
  );
  const independenceSignal = clamp(1 - telemetry.supportLevel / 3);
  const engagement = clamp(0.6 * interactionSignal + 0.4 * independenceSignal);
  const speed = clamp(1 - telemetry.latencyMs / speedBudgetFor(layer));
  return {
    accuracy,
    recovery,
    engagement,
    speed,
    isolationScore: 0.4 * accuracy + 0.3 * recovery + 0.2 * engagement + 0.1 * speed,
  };
}

function clamp(value: number): number {
  return Math.max(0, Math.min(1, value));
}

async function getIssuedTask(
  serviceClient: { from: Function },
  sessionId: string,
): Promise<TaskRow | null> {
  const { data, error } = await serviceClient.from('synthetic_engine2_demo_tasks')
    .select('*')
    .eq('session_id', sessionId)
    .eq('status', 'issued')
    .order('sequence_index', { ascending: true })
    .maybeSingle();
  if (error) throw new Error('Synthetic demo task could not be read.');
  return data ? data as TaskRow : null;
}

function taskHasCurrentPuzzlePlan(task: TaskRow): boolean {
  try {
    const payload = asRecord(task.task_payload, 'stored task payload');
    const scene = asRecord(payload.scene, 'stored task scene');
    const plan = asRecord(scene.puzzle_plan, 'stored puzzle plan');
    return plan.version === 1 &&
      typeof plan.kind === 'string' && sectorSet.has(plan.kind) &&
      typeof plan.sector_group === 'string' && sectorGroupSet.has(plan.sector_group) &&
      typeof plan.scene_type === 'string' && sceneTypeSet.has(plan.scene_type) &&
      typeof plan.rule === 'string' && puzzleRuleSet.has(plan.rule) &&
      typeof plan.interaction === 'string' && interactionPlanSet.has(plan.interaction) &&
      typeof plan.stimulus_template === 'string' && stimulusTemplateSet.has(plan.stimulus_template) &&
      Array.isArray(plan.stimulus) && Array.isArray(plan.option_values) &&
      typeof plan.answer_value === 'number' && typeof plan.target_index === 'number';
  } catch (_) {
    return false;
  }
}

/// Sessions created before the deterministic plan contract had generic visual
/// tasks. Reset them on the next synthetic start so a deploy never leaves the
/// builder looking at the old car-only queue.
async function sessionNeedsPuzzlePlanReset(
  serviceClient: { from: Function },
  sessionId: string,
): Promise<boolean> {
  const { data, error } = await serviceClient
    .from('synthetic_engine2_demo_tasks')
    .select('*')
    .eq('session_id', sessionId)
    .in('status', ['issued', 'queued'])
    .order('sequence_index', { ascending: true })
    .limit(1)
    .maybeSingle();
  if (error) throw new Error('Synthetic demo task migration state could not be read.');
  return !data || !taskHasCurrentPuzzlePlan(data as TaskRow);
}

async function issueNextQueuedTask(
  serviceClient: { from: Function },
  session: SessionRow,
): Promise<TaskRow | null> {
  const existing = await getIssuedTask(serviceClient, session.id);
  if (existing) return existing;
  const { data: queued, error: queuedError } = await serviceClient
    .from('synthetic_engine2_demo_tasks')
    .select('*')
    .eq('session_id', session.id)
    .eq('status', 'queued')
    .order('sequence_index', { ascending: true })
    .limit(1)
    .maybeSingle();
  if (queuedError) throw new Error('Synthetic demo queued task could not be read.');
  if (!queued) return null;
  const { data: issued, error: issueError } = await serviceClient
    .from('synthetic_engine2_demo_tasks')
    .update({ status: 'issued' })
    .eq('id', queued.id)
    .eq('status', 'queued')
    .select('*')
    .maybeSingle();
  if (issueError) {
    // The partial unique index permits one issued task only. A concurrent
    // retry may have won the update, so return that task rather than failing.
    const concurrent = await getIssuedTask(serviceClient, session.id);
    if (concurrent) return concurrent;
    throw new Error('Synthetic demo task could not be issued.');
  }
  if (!issued) return getIssuedTask(serviceClient, session.id);
  const pending = asSectorList(session.pending_sectors).filter((sector) => sector !== queued.sector);
  const { error: sessionError } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .update({ pending_sectors: pending, updated_at: new Date().toISOString() })
    .eq('id', session.id);
  if (sessionError) throw new Error('Synthetic demo session could not be updated.');
  return issued as TaskRow;
}

async function createLayerTasks(
  serviceClient: { from: Function; rpc: Function },
  session: SessionRow,
  activeSectors: Sector[],
  preferences: VisualPreferences,
): Promise<TaskRow> {
  await consumeQuota(serviceClient, session.anonymous_user_id);
  const generated = await generateLayerWithOpenAi(
    activeSectors,
    session.current_layer,
    preferences,
    session.id,
  );
  const skinsBySector = new Map(generated.skins.map((skin) => [skin.sector, skin]));
  const rows = activeSectors.map((sector, index) => {
    const plan = createPuzzlePlan(sector, session.current_layer, session.id);
    const skin = skinsBySector.get(sector);
    if (!skin) throw new Error('Synthetic skin batch is incomplete.');
    return {
    session_id: session.id,
    anonymous_user_id: session.anonymous_user_id,
    layer: session.current_layer,
    sequence_index: index + 1,
    sector,
    status: index === 0 ? 'issued' : 'queued',
    source: generated.source,
    task_payload: taskPayload(plan, skin, session.current_layer, preferences),
    };
  });
  const { data, error } = await serviceClient
    .from('synthetic_engine2_demo_tasks')
    .insert(rows)
    .select('*');
  if (error || !data) {
    // A repeated mobile request can race the original layer creation. In that
    // case, return the already-issued task instead of generating another one.
    const existing = await getIssuedTask(serviceClient, session.id);
    if (existing) return existing;
    console.error('[synthetic-engine2-next-task] task batch insert failed');
    throw new Error('Synthetic demo tasks could not be created.');
  }
  const issued = (data as TaskRow[]).find((task) => task.status === 'issued');
  if (!issued) throw new Error('Synthetic demo task batch has no issued task.');
  return issued;
}

async function updateLayerState(
  serviceClient: { from: Function },
  sessionId: string,
  layer: number,
  activeSectors: Sector[],
): Promise<SessionRow> {
  const { data, error } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .update({
      current_layer: layer,
      active_sectors: activeSectors,
      pending_sectors: activeSectors.slice(1),
      updated_at: new Date().toISOString(),
    })
    .eq('id', sessionId)
    .select('*')
    .maybeSingle();
  if (error || !data) throw new Error('Synthetic demo layer state could not be updated.');
  return data as SessionRow;
}

async function rankLayer(
  serviceClient: { from: Function },
  session: SessionRow,
): Promise<SyntheticLayerSignal<Sector>[]> {
  const active = asSectorList(session.active_sectors);
  const { data, error } = await serviceClient
    .from('synthetic_engine2_demo_events')
    .select('sector, isolation_score, support_level')
    .eq('session_id', session.id)
    .eq('layer', session.current_layer);
  if (error) throw new Error('Synthetic demo events could not be read.');
  const bySector = new Map<Sector, EventRow>();
  for (const row of (data ?? []) as EventRow[]) {
    if (sectorSet.has(row.sector)) bySector.set(row.sector, row);
  }
  if (bySector.size !== active.length || active.some((sector) => !bySector.has(sector))) {
    throw new Error('Synthetic demo layer is incomplete.');
  }
  return active.map((sector, activeIndex) => {
    const row = bySector.get(sector)!;
    return {
      sector,
      isolationScore: Number(row.isolation_score),
      supportLevel: Number(row.support_level),
      activeIndex,
    };
  }).sort((left, right) => {
    const scoreDelta = right.isolationScore - left.isolationScore;
    if (scoreDelta !== 0) return scoreDelta;
    const supportDelta = left.supportLevel - right.supportLevel;
    if (supportDelta !== 0) return supportDelta;
    return left.activeIndex - right.activeIndex;
  });
}

function progressResponse(
  session: SessionRow,
  solved: boolean | undefined,
  task?: TaskRow,
  skipped = false,
): Response {
  const body: Record<string, unknown> = {
    status: 'in_progress',
    session_id: session.id,
    current_layer: session.current_layer,
    active_sectors: asSectorList(session.active_sectors),
  };
  if (solved !== undefined) body.solved = solved;
  if (skipped) body.skipped = true;
  if (task) body.next_task = publicTask(task);
  return ok(body);
}

function completeResponse(
  session: SessionRow,
  finalSector: Sector,
  { solved = true, skipped = false }: { solved?: boolean; skipped?: boolean } = {},
): Response {
  const body: Record<string, unknown> = {
    status: 'complete',
    solved,
    session_id: session.id,
    current_layer: 10,
    active_sectors: [finalSector],
    final_sector: finalSector,
    sandbox: sandboxForSector(finalSector),
  };
  if (skipped) body.skipped = true;
  return ok(body);
}

async function startSession(
  serviceClient: { from: Function; rpc: Function },
  anonymousUserId: string,
  preferences: VisualPreferences,
): Promise<Response> {
  const now = new Date().toISOString();
  const { error: expireError } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .update({ status: 'expired', updated_at: now })
    .eq('anonymous_user_id', anonymousUserId)
    .eq('status', 'in_progress')
    .lte('expires_at', now);
  if (expireError) throw new Error('Expired synthetic demo sessions could not be closed.');

  const { data: current, error: currentError } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .select('*')
    .eq('anonymous_user_id', anonymousUserId)
    .eq('status', 'in_progress')
    .gt('expires_at', now)
    .maybeSingle();
  if (currentError) throw new Error('Synthetic demo session could not be read.');
  if (current) {
    const session = current as SessionRow;
    if (sameVisualPreferences(asVisualPreferences(session.visual_preferences), preferences)) {
      if (!await sessionNeedsPuzzlePlanReset(serviceClient, session.id)) {
        const task = await issueNextQueuedTask(serviceClient, session);
        if (!task) throw new Error('Synthetic demo session is missing its current task.');
        return progressResponse(session, undefined, task);
      }
      // A function deploy changed the task contract. Retire the old generic
      // queue and create a new synthetic-only session below.
      const { error: legacyResetError } = await serviceClient
        .from('synthetic_engine2_demo_sessions')
        .update({ status: 'expired', updated_at: now })
        .eq('id', session.id)
        .eq('status', 'in_progress');
      if (legacyResetError) throw new Error('Synthetic demo tasks could not be refreshed.');
    } else {
      // A new fictional intake mapping deserves its own visual run. Never
      // overwrite an in-progress session's preferences in place: expire it and
      // create a new isolated anonymous session below.
      const { error: resetError } = await serviceClient
        .from('synthetic_engine2_demo_sessions')
        .update({ status: 'expired', updated_at: now })
        .eq('id', session.id)
        .eq('status', 'in_progress');
      if (resetError) throw new Error('Synthetic demo preferences could not be refreshed.');
    }
  }

  const storedPreferences = {
    world: preferences.world,
    palette: preferences.palette,
    object_style: preferences.objectStyle,
    motion_allowed: preferences.motionAllowed,
    allow_distractors: preferences.allowDistractors,
    interaction: preferences.interaction,
  };
  const { data: inserted, error: insertError } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .insert({
      anonymous_user_id: anonymousUserId,
      visual_preferences: storedPreferences,
      active_sectors: [],
      pending_sectors: [],
    })
    .select('*')
    .maybeSingle();
  if (insertError || !inserted) {
    // The partial unique index may have won a simultaneous mobile start.
    const { data: raced } = await serviceClient
      .from('synthetic_engine2_demo_sessions')
      .select('*')
      .eq('anonymous_user_id', anonymousUserId)
      .eq('status', 'in_progress')
      .gt('expires_at', now)
      .maybeSingle();
    if (raced) {
      const task = await issueNextQueuedTask(serviceClient, raced as SessionRow);
      if (task) return progressResponse(raced as SessionRow, undefined, task);
    }
    throw new Error('Synthetic demo session could not be created.');
  }
  const ordered = orderedSectors((inserted as SessionRow).id);
  const session = await updateLayerState(serviceClient, (inserted as SessionRow).id, 1, ordered);
  const task = await createLayerTasks(serviceClient, session, ordered, preferences);
  return progressResponse(session, undefined, task);
}

async function finalizeTaskResponse(
  serviceClient: { from: Function; rpc: Function },
  session: SessionRow,
  task: TaskRow,
  telemetry: AggregatedTelemetry,
  { correct, skipped = false }: { correct: boolean; skipped?: boolean },
): Promise<Response> {
  const scored = scoreFinalTelemetry(telemetry, task.layer, correct);
  const { error: eventError } = await serviceClient
    .from('synthetic_engine2_demo_events')
    .insert({
      session_id: session.id,
      task_id: task.id,
      anonymous_user_id: session.anonymous_user_id,
      layer: task.layer,
      sector: task.sector,
      correct,
      latency_ms: telemetry.latencyMs,
      misclicks: telemetry.misclicks,
      recovered_errors: telemetry.recoveredErrors,
      interactions: telemetry.interactions,
      support_level: telemetry.supportLevel,
      accuracy: scored.accuracy,
      recovery: scored.recovery,
      engagement: scored.engagement,
      speed: scored.speed,
      isolation_score: scored.isolationScore,
    });
  if (eventError) {
    // A network retry may repeat a final response after the event insert won.
    // It can resume only the same outcome; an answer and a skip must never
    // overwrite each other or silently change correctness.
    const { data: existing } = await serviceClient
      .from('synthetic_engine2_demo_events')
      .select('correct')
      .eq('task_id', task.id)
      .maybeSingle();
    if (!existing) throw new Error('Synthetic demo response could not be recorded.');
    if ((existing as { correct?: unknown }).correct !== correct) {
      return conflict('Synthetic demo task already has a different final response.');
    }
  }
  const { error: completeTaskError } = await serviceClient
    .from('synthetic_engine2_demo_tasks')
    .update({ status: 'completed', completed_at: new Date().toISOString() })
    .eq('id', task.id)
    .eq('status', 'issued');
  if (completeTaskError) throw new Error('Synthetic demo task could not be completed.');

  const nextQueued = await issueNextQueuedTask(serviceClient, session);
  if (nextQueued) return progressResponse(session, correct, nextQueued, skipped);

  const ranked = await rankLayer(serviceClient, session);
  if (session.current_layer >= 10) {
    const finalSector = ranked[0].sector;
    const { data: completeSession, error: completeError } = await serviceClient
      .from('synthetic_engine2_demo_sessions')
      .update({
        status: 'complete',
        final_sector: finalSector,
        final_sandbox: sandboxForSector(finalSector),
        pending_sectors: [],
        updated_at: new Date().toISOString(),
      })
      .eq('id', session.id)
      .select('*')
      .maybeSingle();
    if (completeError || !completeSession) throw new Error('Synthetic demo completion could not be saved.');
    return completeResponse(completeSession as SessionRow, finalSector, {
      solved: correct,
      skipped,
    });
  }

  const nextLayer = session.current_layer + 1;
  // Layer 1 retains every sector that clears its score bar. Each later layer
  // repeats that response-driven filter using only its latest interaction
  // data; Layer 10 receives one deterministic capstone sector.
  const survivors = selectSyntheticSurvivors(ranked, session.current_layer);
  const nextSession = await updateLayerState(serviceClient, session.id, nextLayer, survivors);
  const preferences = asVisualPreferences(nextSession.visual_preferences);
  const nextTask = await createLayerTasks(serviceClient, nextSession, survivors, preferences);
  return progressResponse(nextSession, correct, nextTask, skipped);
}

async function recordAttempt(
  serviceClient: { from: Function },
  session: SessionRow,
  task: TaskRow,
  optionId: string,
  correct: boolean,
  telemetry: Telemetry,
): Promise<void> {
  const { error } = await serviceClient
    .from('synthetic_engine2_demo_attempts')
    .insert({
      session_id: session.id,
      task_id: task.id,
      anonymous_user_id: session.anonymous_user_id,
      layer: task.layer,
      sector: task.sector,
      option_id: optionId,
      correct,
      latency_ms: telemetry.latencyMs,
      misclicks: telemetry.misclicks,
      recovered_errors: telemetry.recoveredErrors,
      interactions: telemetry.interactions,
      support_level: telemetry.supportLevel,
    });
  if (error) throw new Error('Synthetic demo selection could not be recorded.');
}

async function aggregateAttempts(
  serviceClient: { from: Function },
  taskId: string,
): Promise<AggregatedTelemetry> {
  const { data, error } = await serviceClient
    .from('synthetic_engine2_demo_attempts')
    .select('correct, latency_ms, support_level')
    .eq('task_id', taskId)
    .order('created_at', { ascending: true });
  if (error || !data || data.length === 0) {
    throw new Error('Synthetic demo attempt telemetry could not be read.');
  }
  const attempts = data as AttemptRow[];
  if (attempts.length > 100) {
    throw new Error('Synthetic demo task exceeded its attempt limit.');
  }
  const incorrectAttempts = attempts.filter((attempt) => attempt.correct !== true).length;
  const latest = attempts[attempts.length - 1];
  const supportLevel = attempts.reduce(
    (maximum, attempt) => Math.max(maximum, Number(attempt.support_level)),
    0,
  );
  return {
    latencyMs: Math.max(0, Math.min(600000, Number(latest.latency_ms))),
    misclicks: incorrectAttempts,
    // A correct final selection after an incorrect selection is a recovered
    // error. This is reconstructed server-side even if Flutter's callback
    // snapshot was captured before its local tracker updated.
    recoveredErrors: incorrectAttempts,
    interactions: attempts.length,
    supportLevel: Math.max(0, Math.min(3, supportLevel)),
    attemptCount: attempts.length,
  };
}

type OwnedTaskResolution =
  | { kind: 'response'; response: Response }
  | { kind: 'task'; session: SessionRow; task: TaskRow };

async function loadOwnedTask(
  serviceClient: { from: Function },
  anonymousUserId: string,
  request: TaskResponseRequest,
): Promise<OwnedTaskResolution> {
  const { data: rawSession, error: sessionError } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .select('*')
    .eq('id', request.sessionId)
    .eq('anonymous_user_id', anonymousUserId)
    .maybeSingle();
  if (sessionError || !rawSession) {
    return { kind: 'response', response: conflict('Synthetic demo session is not available.') };
  }
  const session = rawSession as SessionRow;
  if (session.status === 'complete') {
    const finalSector = session.final_sector;
    if (typeof finalSector === 'string' && sectorSet.has(finalSector)) {
      return {
        kind: 'response',
        response: completeResponse(session, finalSector as Sector),
      };
    }
    return {
      kind: 'response',
      response: conflict('Synthetic demo session has already completed.'),
    };
  }
  if (session.status !== 'in_progress' || new Date(session.expires_at) <= new Date()) {
    await serviceClient.from('synthetic_engine2_demo_sessions')
      .update({ status: 'expired', updated_at: new Date().toISOString() })
      .eq('id', session.id)
      .eq('status', 'in_progress');
    return {
      kind: 'response',
      response: conflict('Synthetic demo session has expired. Start a new showcase session.'),
    };
  }
  const { data: rawTask, error: taskError } = await serviceClient
    .from('synthetic_engine2_demo_tasks')
    .select('*')
    .eq('id', request.taskId)
    .eq('session_id', session.id)
    .eq('anonymous_user_id', anonymousUserId)
    .maybeSingle();
  if (taskError || !rawTask) {
    return { kind: 'response', response: conflict('Synthetic demo task is not available.') };
  }
  const task = rawTask as TaskRow;
  if (task.sector !== request.sector || task.layer !== request.layer ||
      task.layer !== session.current_layer) {
    return {
      kind: 'response',
      response: conflict('Synthetic demo task does not match the active layer.'),
    };
  }
  return { kind: 'task', session, task };
}

async function answerTask(
  serviceClient: { from: Function; rpc: Function },
  anonymousUserId: string,
  request: AnswerRequest,
): Promise<Response> {
  const resolved = await loadOwnedTask(serviceClient, anonymousUserId, request);
  if (resolved.kind === 'response') return resolved.response;
  const { session, task } = resolved;
  if (task.status === 'completed') {
    const next = await issueNextQueuedTask(serviceClient, session);
    return next ? progressResponse(session, true, next) : conflict('Synthetic demo task was already completed.');
  }
  if (task.status !== 'issued') return conflict('Synthetic demo task is not the active task.');

  const payload = asRecord(task.task_payload, 'stored task payload');
  const options = payload.options;
  const correctOption = payload.correct_option;
  if (!Array.isArray(options) || options.some((option) => typeof option !== 'string') ||
      typeof correctOption !== 'string' || !options.includes(correctOption)) {
    throw new Error('Stored synthetic demo task is invalid.');
  }
  if (!options.includes(request.optionId)) {
    throw new ValidationError('option_id was not issued for this task.');
  }
  const solved = request.optionId === correctOption;
  await recordAttempt(serviceClient, session, task, request.optionId, solved, request.telemetry);
  if (!solved) {
    // Do not advance or record a final task event. Flutter retains this exact
    // task; its next answer carries the aggregate fictional telemetry.
    return progressResponse(session, false);
  }
  return finalizeTaskResponse(
    serviceClient,
    session,
    task,
    await aggregateAttempts(serviceClient, task.id),
    { correct: true },
  );
}

async function skipTask(
  serviceClient: { from: Function; rpc: Function },
  anonymousUserId: string,
  request: SkipRequest,
): Promise<Response> {
  const resolved = await loadOwnedTask(serviceClient, anonymousUserId, request);
  if (resolved.kind === 'response') return resolved.response;
  const { session, task } = resolved;
  // A skip is valid only for the one currently issued task. It cannot be used
  // to rewrite an already-final answer or to advance a queued task.
  if (task.status !== 'issued') return conflict('Synthetic demo task is not the active task.');

  // Do not create a fake selection/attempt for inactivity. The final event
  // stores only the already allowlisted, bounded aggregate supplied by Flutter.
  return finalizeTaskResponse(
    serviceClient,
    session,
    task,
    { ...request.telemetry, attemptCount: request.telemetry.interactions },
    { correct: false, skipped: true },
  );
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return badRequest('POST is required.');
  if (Deno.env.get('SYNTHETIC_ENGINE2_CLOUD_ENABLED') !== 'true') {
    return Response.json(
      { error: 'Synthetic cloud Engine 2 is not enabled for this project.' },
      { status: 503, headers: corsHeaders },
    );
  }

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  if ((auth.user as { is_anonymous?: unknown }).is_anonymous !== true) {
    return forbidden('This endpoint is available only to anonymous synthetic demo sessions.');
  }

  try {
    const request = parseRequest(await req.json());
    if (request.action === 'start') {
      return await startSession(auth.serviceClient, auth.user.id, request.visual);
    }
    if (request.action === 'answer') {
      return await answerTask(auth.serviceClient, auth.user.id, request);
    }
    return await skipTask(auth.serviceClient, auth.user.id, request);
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    if (error instanceof QuotaExceededError) {
      return Response.json({ error: error.message }, { status: 429, headers: corsHeaders });
    }
    console.error('[synthetic-engine2-next-task] unexpected error');
    return internalError('Synthetic cloud task could not be prepared.');
  }
});
