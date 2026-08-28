import '../../../models/intake_models.dart';

/// Evidence-informed activity variant for a RIASEC play sector.
///
/// These are **original present-moment prompts** framed from published frameworks
/// (Holland RIASEC interest types, developmental constructive/social play research,
/// elementary leisure activity taxonomies). They are **not** verbatim items from
/// ISAA, ADOS, Vineland, or other licensed clinical instruments.
class ClinicalActivityVariant {
  const ClinicalActivityVariant({
    required this.sectorId,
    required this.presentMomentPrompt,
    required this.activityLabel,
    required this.pictureDescription,
    required this.provenanceFramework,
    this.affinity = const [],
    this.avoidSensoryTriggers = const [],
    this.ageMin = 7,
    this.ageMax = 13,
  });

  final String sectorId;
  final String presentMomentPrompt;
  final String activityLabel;
  final String pictureDescription;

  /// e.g. `RIASEC-Realistic`, `DevPlay-Constructive`, `Leisure-Elementary`
  final String provenanceFramework;

  /// Parent hyperfixation categories this variant aligns with.
  final List<HyperFixationCategory> affinity;

  /// Skip this variant if any trigger is in the child's sensory profile.
  final List<String> avoidSensoryTriggers;

  final int ageMin;
  final int ageMax;
}

/// Multiple clinically-framed activity options per sector for personalization.
const kClinicalActivityBank = <ClinicalActivityVariant>[
  // --- Realistic ---
  ClinicalActivityVariant(
    sectorId: 'r_build_fix',
    presentMomentPrompt: 'Is snapping blocks together fun for you right now?',
    activityLabel: 'Building a small tower',
    pictureDescription: 'Side-view of hands stacking three plain blocks. No faces.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-Constructive',
    affinity: [HyperFixationCategory.geometryPatterns, HyperFixationCategory.trainsVehicles],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_build_fix',
    presentMomentPrompt: 'Is connecting train track pieces fun for you right now?',
    activityLabel: 'Connecting track pieces',
    pictureDescription: 'Curved track pieces clicking together. No faces.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-Constructive',
    affinity: [HyperFixationCategory.trainsVehicles],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_nature_outdoors',
    presentMomentPrompt: 'Is walking on a leafy trail fun for you right now?',
    activityLabel: 'Trail exploring',
    pictureDescription: 'Simple path with trees and leaves. No people faces.',
    provenanceFramework: 'RIASEC-Realistic / Leisure-Outdoor',
    affinity: [HyperFixationCategory.animalsNature],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_nature_outdoors',
    presentMomentPrompt: 'Is watching birds near a window fun for you right now?',
    activityLabel: 'Bird watching',
    pictureDescription: 'Simple bird on a branch outside a window. No faces.',
    provenanceFramework: 'RIASEC-Realistic / Leisure-Outdoor',
    affinity: [HyperFixationCategory.animalsNature],
    avoidSensoryTriggers: ['loud_sudden_noise'],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_sports_movement',
    presentMomentPrompt: 'Is climbing on playground bars fun for you right now?',
    activityLabel: 'Climbing and balancing',
    pictureDescription: 'Plain figure on monkey bars, side view. No facial detail.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-Motor',
  ),
  ClinicalActivityVariant(
    sectorId: 'r_sports_movement',
    presentMomentPrompt: 'Is bouncing a ball in place fun for you right now?',
    activityLabel: 'Ball bouncing',
    pictureDescription: 'Ball mid-bounce on plain ground. No faces.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-Motor',
    avoidSensoryTriggers: ['loud_sudden_noise'],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_crafts_making',
    presentMomentPrompt: 'Is gluing paper shapes together fun for you right now?',
    activityLabel: 'Paper crafting',
    pictureDescription: 'Hands holding glue stick and colored paper. No faces.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-ArtMaking',
    affinity: [HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_vehicles_machines',
    presentMomentPrompt: 'Is rolling toy wheels back and forth fun for you right now?',
    activityLabel: 'Toy wheels and trains',
    pictureDescription: 'Simple toy train on a track. Neutral colors.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-Constructive',
    affinity: [HyperFixationCategory.trainsVehicles],
  ),
  ClinicalActivityVariant(
    sectorId: 'r_vehicles_machines',
    presentMomentPrompt: 'Is lining up toy cars in a row fun for you right now?',
    activityLabel: 'Toy car lineup',
    pictureDescription: 'Three toy cars in a neat row. No faces.',
    provenanceFramework: 'RIASEC-Realistic / DevPlay-Constructive',
    affinity: [HyperFixationCategory.trainsVehicles, HyperFixationCategory.geometryPatterns],
  ),
  // --- Investigative ---
  ClinicalActivityVariant(
    sectorId: 'i_puzzles_logic',
    presentMomentPrompt: 'Is fitting puzzle pieces together fun for you right now?',
    activityLabel: 'Jigsaw puzzle',
    pictureDescription: 'Two puzzle pieces about to connect. Minimal background.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-ProblemSolving',
    affinity: [HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'i_nature_science',
    presentMomentPrompt: 'Is looking at a bug with a magnifier fun for you right now?',
    activityLabel: 'Bug observing',
    pictureDescription: 'Magnifying glass over a leaf with a simple bug shape.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-Observation',
    affinity: [HyperFixationCategory.animalsNature],
  ),
  ClinicalActivityVariant(
    sectorId: 'i_numbers_patterns',
    presentMomentPrompt: 'Is lining up counting blocks in order fun for you right now?',
    activityLabel: 'Number patterns',
    pictureDescription: 'Colored blocks numbered 1-2-3 in a row.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-Pattern',
    affinity: [HyperFixationCategory.clocksNumbers, HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'i_numbers_patterns',
    presentMomentPrompt: 'Is matching clock faces to the right time fun for you right now?',
    activityLabel: 'Clock matching',
    pictureDescription: 'Simple analog clock faces without numbers clutter.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-Pattern',
    affinity: [HyperFixationCategory.clocksNumbers],
  ),
  ClinicalActivityVariant(
    sectorId: 'i_maps_exploring',
    presentMomentPrompt: 'Is tracing a path through a maze fun for you right now?',
    activityLabel: 'Maze path',
    pictureDescription: 'Simple top-down maze with one clear route.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-Spatial',
    affinity: [HyperFixationCategory.spaceAstronomy, HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'i_maps_exploring',
    presentMomentPrompt: 'Is following a star map on paper fun for you right now?',
    activityLabel: 'Star map tracing',
    pictureDescription: 'Dots connected as a simple constellation map. No faces.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-Spatial',
    affinity: [HyperFixationCategory.spaceAstronomy],
  ),
  ClinicalActivityVariant(
    sectorId: 'i_experiments_trying',
    presentMomentPrompt: 'Is mixing two safe liquids in a cup fun for you right now?',
    activityLabel: 'Mix and try',
    pictureDescription: 'Two beakers pouring into one cup. No faces.',
    provenanceFramework: 'RIASEC-Investigative / DevPlay-Exploration',
  ),
  // --- Artistic ---
  ClinicalActivityVariant(
    sectorId: 'a_drawing_color',
    presentMomentPrompt: 'Is filling shapes with bright colors fun for you right now?',
    activityLabel: 'Coloring shapes',
    pictureDescription: 'Crayons next to an outlined star and circle.',
    provenanceFramework: 'RIASEC-Artistic / DevPlay-ArtMaking',
    affinity: [HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'a_music_rhythm',
    presentMomentPrompt: 'Is tapping a steady beat on a drum fun for you right now?',
    activityLabel: 'Rhythm tapping',
    pictureDescription: 'Simple hand tapping a plain drum. No face.',
    provenanceFramework: 'RIASEC-Artistic / DevPlay-Music',
    avoidSensoryTriggers: ['loud_sudden_noise'],
  ),
  ClinicalActivityVariant(
    sectorId: 'a_music_rhythm',
    presentMomentPrompt: 'Is humming along to a soft melody fun for you right now?',
    activityLabel: 'Soft humming',
    pictureDescription: 'Musical notes floating gently. No speaker icon.',
    provenanceFramework: 'RIASEC-Artistic / DevPlay-Music',
  ),
  ClinicalActivityVariant(
    sectorId: 'a_story_imagine',
    presentMomentPrompt: 'Is making up a silly story out loud fun for you right now?',
    activityLabel: 'Story imagining',
    pictureDescription: 'Open book with a star and moon icons floating above.',
    provenanceFramework: 'RIASEC-Artistic / DevPlay-Symbolic',
    affinity: [HyperFixationCategory.spaceAstronomy],
  ),
  ClinicalActivityVariant(
    sectorId: 'a_build_design',
    presentMomentPrompt: 'Is arranging shapes into a new pattern fun for you right now?',
    activityLabel: 'Shape design',
    pictureDescription: 'Triangles and squares forming a new layout.',
    provenanceFramework: 'RIASEC-Artistic / DevPlay-Constructive',
    affinity: [HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'a_performance_show',
    presentMomentPrompt: 'Is acting out a short scene with toys fun for you right now?',
    activityLabel: 'Toy performance',
    pictureDescription: 'Two toy figures on a small stage. No faces.',
    provenanceFramework: 'RIASEC-Artistic / DevPlay-Symbolic',
  ),
  // --- Social ---
  ClinicalActivityVariant(
    sectorId: 's_helping_caring',
    presentMomentPrompt: 'Is gently caring for a toy doll fun for you right now?',
    activityLabel: 'Caring play',
    pictureDescription: 'Hands tucking a blanket around a plain toy figure.',
    provenanceFramework: 'RIASEC-Social / DevPlay-Caring',
  ),
  ClinicalActivityVariant(
    sectorId: 's_teaching_showing',
    presentMomentPrompt: 'Is showing a friend how a toy works fun for you right now?',
    activityLabel: 'Showing a toy',
    pictureDescription: 'One hand pointing at toy gears while another watches.',
    provenanceFramework: 'RIASEC-Social / DevPlay-Cooperative',
  ),
  ClinicalActivityVariant(
    sectorId: 's_team_play',
    presentMomentPrompt: 'Is passing a ball back and forth with someone fun for you right now?',
    activityLabel: 'Cooperative ball play',
    pictureDescription: 'Two plain figures passing a ball. No facial detail.',
    provenanceFramework: 'RIASEC-Social / DevPlay-Cooperative',
  ),
  ClinicalActivityVariant(
    sectorId: 's_community_events',
    presentMomentPrompt: 'Is walking through a quiet fair with stalls fun for you right now?',
    activityLabel: 'Fair exploring',
    pictureDescription: 'Simple tents and banner flags. No crowd faces.',
    provenanceFramework: 'RIASEC-Social / Leisure-Community',
    avoidSensoryTriggers: ['loud_sudden_noise', 'busy_patterns'],
  ),
  ClinicalActivityVariant(
    sectorId: 's_friend_connections',
    presentMomentPrompt: 'Is sharing a snack with a friend fun for you right now?',
    activityLabel: 'Friend sharing',
    pictureDescription: 'Two plain cups and a small snack plate.',
    provenanceFramework: 'RIASEC-Social / DevPlay-Cooperative',
  ),
  // --- Enterprising ---
  ClinicalActivityVariant(
    sectorId: 'e_leading_groups',
    presentMomentPrompt: 'Is picking the next group game fun for you right now?',
    activityLabel: 'Leading play',
    pictureDescription: 'Plain figure pointing at three game cards on the ground.',
    provenanceFramework: 'RIASEC-Enterprising / DevPlay-Initiative',
  ),
  ClinicalActivityVariant(
    sectorId: 'e_selling_trading',
    presentMomentPrompt: 'Is swapping trading cards with a friend fun for you right now?',
    activityLabel: 'Card swapping',
    pictureDescription: 'Two hands exchanging plain cards.',
    provenanceFramework: 'RIASEC-Enterprising / DevPlay-Exchange',
  ),
  ClinicalActivityVariant(
    sectorId: 'e_planning_events',
    presentMomentPrompt: 'Is planning a pretend picnic fun for you right now?',
    activityLabel: 'Picnic planning',
    pictureDescription: 'Checklist next to a blanket and basket icon.',
    provenanceFramework: 'RIASEC-Enterprising / DevPlay-Planning',
  ),
  ClinicalActivityVariant(
    sectorId: 'e_persuading_sharing',
    presentMomentPrompt: 'Is telling someone about a fun idea fun for you right now?',
    activityLabel: 'Idea sharing',
    pictureDescription: 'Speech bubble with a lightbulb icon. No face.',
    provenanceFramework: 'RIASEC-Enterprising / DevPlay-Communication',
  ),
  ClinicalActivityVariant(
    sectorId: 'e_starting_projects',
    presentMomentPrompt: 'Is starting a new craft project fun for you right now?',
    activityLabel: 'New project start',
    pictureDescription: 'Blank paper, scissors, and tape laid out neatly.',
    provenanceFramework: 'RIASEC-Enterprising / DevPlay-Initiative',
  ),
  // --- Conventional ---
  ClinicalActivityVariant(
    sectorId: 'c_sorting_organizing',
    presentMomentPrompt: 'Is sorting buttons by color fun for you right now?',
    activityLabel: 'Color sorting',
    pictureDescription: 'Buttons grouped into three color piles.',
    provenanceFramework: 'RIASEC-Conventional / DevPlay-Ordering',
    affinity: [HyperFixationCategory.geometryPatterns],
  ),
  ClinicalActivityVariant(
    sectorId: 'c_schedules_routines',
    presentMomentPrompt: 'Is following a picture schedule fun for you right now?',
    activityLabel: 'Picture schedule',
    pictureDescription: 'Three picture cards in a row with arrows.',
    provenanceFramework: 'RIASEC-Conventional / DevPlay-Routine',
    affinity: [HyperFixationCategory.clocksNumbers],
  ),
  ClinicalActivityVariant(
    sectorId: 'c_lists_checklists',
    presentMomentPrompt: 'Is checking off a simple to-do list fun for you right now?',
    activityLabel: 'Checklist play',
    pictureDescription: 'Clipboard with three checkboxes, two checked.',
    provenanceFramework: 'RIASEC-Conventional / DevPlay-Ordering',
  ),
  ClinicalActivityVariant(
    sectorId: 'c_collecting_sets',
    presentMomentPrompt: 'Is lining up a complete sticker set fun for you right now?',
    activityLabel: 'Set collecting',
    pictureDescription: 'Sticker sheet with one empty spot highlighted.',
    provenanceFramework: 'RIASEC-Conventional / DevPlay-Collecting',
  ),
  ClinicalActivityVariant(
    sectorId: 'c_patterns_order',
    presentMomentPrompt: 'Is making a repeating color pattern fun for you right now?',
    activityLabel: 'Pattern making',
    pictureDescription: 'Red-blue-red-blue bead sequence on a string.',
    provenanceFramework: 'RIASEC-Conventional / DevPlay-Pattern',
    affinity: [HyperFixationCategory.geometryPatterns, HyperFixationCategory.clocksNumbers],
  ),
];

List<ClinicalActivityVariant> variantsForSector(String sectorId) {
  return kClinicalActivityBank.where((v) => v.sectorId == sectorId).toList();
}
