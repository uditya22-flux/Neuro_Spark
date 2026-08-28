import '../../../models/intake_models.dart';
import 'research_activity_registry.dart';

/// A research-backed activity option for personalization (not a random prompt).
class ClinicalActivityVariant {
  const ClinicalActivityVariant({
    required this.researchStemId,
    required this.sectorId,
    this.affinity = const [],
    this.avoidSensoryTriggers = const [],
    this.ageMin = 7,
    this.ageMax = 13,
  });

  final String researchStemId;
  final String sectorId;
  final List<HyperFixationCategory> affinity;
  final List<String> avoidSensoryTriggers;
  final int ageMin;
  final int ageMax;

  ResearchActivityStem? get stem => researchStemById(researchStemId);

  String get presentMomentPrompt => stem?.presentMomentPrompt ?? '';
  String get activityLabel => stem?.activityLabel ?? '';
  String get pictureDescription => stem?.pictureDescription ?? '';
  String get provenanceFramework => stem != null ? '${stem!.framework} · ${stem!.citationShort}' : '';
  String get constructDomain => stem?.constructDomain ?? '';
  String get citationShort => stem?.citationShort ?? '';
}

/// Built from [kResearchActivityStems] — every question traces to a published construct.
final List<ClinicalActivityVariant> kClinicalActivityBank = _buildBank();

List<ClinicalActivityVariant> _buildBank() {
  final variants = <ClinicalActivityVariant>[];

  void add(
    String stemId,
    String sectorId, {
    List<HyperFixationCategory> affinity = const [],
    List<String> avoidSensoryTriggers = const [],
  }) {
    variants.add(ClinicalActivityVariant(
      researchStemId: stemId,
      sectorId: sectorId,
      affinity: affinity,
      avoidSensoryTriggers: avoidSensoryTriggers,
    ));
  }

  // Realistic
  add('cape_skill_constructive_build', 'r_build_fix',
      affinity: [HyperFixationCategory.geometryPatterns, HyperFixationCategory.trainsVehicles]);
  add('cape_skill_constructive_track', 'r_build_fix', affinity: [HyperFixationCategory.trainsVehicles]);
  add('cape_recreational_outdoor', 'r_nature_outdoors', affinity: [HyperFixationCategory.animalsNature]);
  add('cape_recreational_nature_observe', 'r_nature_outdoors',
      affinity: [HyperFixationCategory.animalsNature], avoidSensoryTriggers: ['loud_sudden_noise']);
  add('cape_physical_playground', 'r_sports_movement');
  add('cape_physical_ball', 'r_sports_movement', avoidSensoryTriggers: ['loud_sudden_noise']);
  add('cape_skill_crafts', 'r_crafts_making', affinity: [HyperFixationCategory.geometryPatterns]);
  add('cape_skill_vehicles', 'r_vehicles_machines', affinity: [HyperFixationCategory.trainsVehicles]);
  add('cape_skill_vehicle_lineup', 'r_vehicles_machines',
      affinity: [HyperFixationCategory.trainsVehicles, HyperFixationCategory.geometryPatterns]);

  // Investigative
  add('cape_skill_puzzles', 'i_puzzles_logic', affinity: [HyperFixationCategory.geometryPatterns]);
  add('cape_skill_science_observe', 'i_nature_science', affinity: [HyperFixationCategory.animalsNature]);
  add('cape_skill_numbers', 'i_numbers_patterns',
      affinity: [HyperFixationCategory.clocksNumbers, HyperFixationCategory.geometryPatterns]);
  add('pac_routine_time', 'i_numbers_patterns', affinity: [HyperFixationCategory.clocksNumbers]);
  add('cape_skill_spatial_maze', 'i_maps_exploring',
      affinity: [HyperFixationCategory.geometryPatterns]);
  add('riasec_investigative_space_map', 'i_maps_exploring',
      affinity: [HyperFixationCategory.spaceAstronomy]);
  add('cape_skill_experiment', 'i_experiments_trying');

  // Artistic
  add('cape_skill_drawing', 'a_drawing_color', affinity: [HyperFixationCategory.geometryPatterns]);
  add('cape_recreational_music_active', 'a_music_rhythm', avoidSensoryTriggers: ['loud_sudden_noise']);
  add('cape_recreational_music_quiet', 'a_music_rhythm');
  add('parten_symbolic_story', 'a_story_imagine', affinity: [HyperFixationCategory.spaceAstronomy]);
  add('cape_skill_design', 'a_build_design', affinity: [HyperFixationCategory.geometryPatterns]);
  add('parten_dramatic_play', 'a_performance_show');

  // Social
  add('cape_social_caring', 's_helping_caring');
  add('cape_social_teaching', 's_teaching_showing');
  add('cape_social_cooperative', 's_team_play');
  add('cape_social_community', 's_community_events',
      avoidSensoryTriggers: ['loud_sudden_noise', 'busy_patterns']);
  add('cape_social_friends', 's_friend_connections');

  // Enterprising
  add('riasec_enterprising_lead', 'e_leading_groups');
  add('cape_social_exchange', 'e_selling_trading');
  add('cape_skill_planning', 'e_planning_events');
  add('riasec_enterprising_share_ideas', 'e_persuading_sharing');
  add('cape_skill_project_start', 'e_starting_projects');

  // Conventional
  add('cape_skill_sorting', 'c_sorting_organizing', affinity: [HyperFixationCategory.geometryPatterns]);
  add('pac_routine_schedule', 'c_schedules_routines', affinity: [HyperFixationCategory.clocksNumbers]);
  add('cape_skill_checklist', 'c_lists_checklists');
  add('cape_skill_collecting', 'c_collecting_sets');
  add('riasec_conventional_pattern', 'c_patterns_order',
      affinity: [HyperFixationCategory.geometryPatterns, HyperFixationCategory.clocksNumbers]);

  return variants;
}

List<ClinicalActivityVariant> variantsForSector(String sectorId) {
  return kClinicalActivityBank.where((v) => v.sectorId == sectorId).toList();
}

/// Ensures every RIASEC sector has at least one research stem (release guard).
bool get allSectorsHaveResearchStems {
  const sectors = [
    'r_build_fix', 'r_nature_outdoors', 'r_sports_movement', 'r_crafts_making', 'r_vehicles_machines',
    'i_puzzles_logic', 'i_nature_science', 'i_numbers_patterns', 'i_maps_exploring', 'i_experiments_trying',
    'a_drawing_color', 'a_music_rhythm', 'a_story_imagine', 'a_build_design', 'a_performance_show',
    's_helping_caring', 's_teaching_showing', 's_team_play', 's_community_events', 's_friend_connections',
    'e_leading_groups', 'e_selling_trading', 'e_planning_events', 'e_persuading_sharing', 'e_starting_projects',
    'c_sorting_organizing', 'c_schedules_routines', 'c_lists_checklists', 'c_collecting_sets', 'c_patterns_order',
  ];
  for (final id in sectors) {
    if (variantsForSector(id).isEmpty) return false;
    if (variantsForSector(id).every((v) => v.stem == null)) return false;
  }
  return true;
}
