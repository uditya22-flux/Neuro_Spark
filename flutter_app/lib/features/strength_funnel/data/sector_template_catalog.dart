import '../models/riasec_sector.dart';

/// Canonical present-moment prompts for all 30 sectors (offline + parity with Supabase seed).
class SectorTemplateSample {
  const SectorTemplateSample({
    required this.sectorId,
    required this.displayName,
    required this.presentMomentPrompt,
    required this.activityLabel,
    required this.pictureDescription,
  });

  final String sectorId;
  final String displayName;
  final String presentMomentPrompt;
  final String activityLabel;
  final String pictureDescription;

  String promptForLayer(int layer) {
    if (layer <= 1) return presentMomentPrompt;
    final base = presentMomentPrompt.replaceAll(RegExp(r'\?$'), '');
    return '$base — thinking about ${activityLabel.toLowerCase()}?';
  }
}

const kSectorTemplateCatalog = <SectorTemplateSample>[
  SectorTemplateSample(sectorId: 'r_build_fix', displayName: 'Build & Fix', presentMomentPrompt: 'Is snapping blocks together fun for you right now?', activityLabel: 'Building a small tower', pictureDescription: 'Side-view of hands stacking three plain blocks. No faces.'),
  SectorTemplateSample(sectorId: 'r_nature_outdoors', displayName: 'Nature Outdoors', presentMomentPrompt: 'Is walking on a leafy trail fun for you right now?', activityLabel: 'Trail exploring', pictureDescription: 'Simple path with trees and leaves. No people faces.'),
  SectorTemplateSample(sectorId: 'r_sports_movement', displayName: 'Sports & Movement', presentMomentPrompt: 'Is climbing on playground bars fun for you right now?', activityLabel: 'Climbing and running', pictureDescription: 'Plain figure on monkey bars, side view. No facial detail.'),
  SectorTemplateSample(sectorId: 'r_crafts_making', displayName: 'Crafts & Making', presentMomentPrompt: 'Is gluing paper shapes together fun for you right now?', activityLabel: 'Paper crafting', pictureDescription: 'Hands holding glue stick and colored paper. No faces.'),
  SectorTemplateSample(sectorId: 'r_vehicles_machines', displayName: 'Vehicles & Machines', presentMomentPrompt: 'Is rolling toy wheels back and forth fun for you right now?', activityLabel: 'Toy wheels and trains', pictureDescription: 'Simple toy train on a track. Neutral colors.'),
  SectorTemplateSample(sectorId: 'i_puzzles_logic', displayName: 'Puzzles & Logic', presentMomentPrompt: 'Is fitting puzzle pieces together fun for you right now?', activityLabel: 'Jigsaw puzzle', pictureDescription: 'Two puzzle pieces about to connect. Minimal background.'),
  SectorTemplateSample(sectorId: 'i_nature_science', displayName: 'Nature Science', presentMomentPrompt: 'Is looking at a bug with a magnifier fun for you right now?', activityLabel: 'Bug observing', pictureDescription: 'Magnifying glass over a leaf with a simple bug shape.'),
  SectorTemplateSample(sectorId: 'i_numbers_patterns', displayName: 'Numbers & Patterns', presentMomentPrompt: 'Is lining up counting blocks in order fun for you right now?', activityLabel: 'Number patterns', pictureDescription: 'Colored blocks numbered 1-2-3 in a row.'),
  SectorTemplateSample(sectorId: 'i_maps_exploring', displayName: 'Maps & Exploring', presentMomentPrompt: 'Is tracing a path through a maze fun for you right now?', activityLabel: 'Maze path', pictureDescription: 'Simple top-down maze with one clear route.'),
  SectorTemplateSample(sectorId: 'i_experiments_trying', displayName: 'Experiments & Trying', presentMomentPrompt: 'Is mixing two safe liquids in a cup fun for you right now?', activityLabel: 'Mix and try', pictureDescription: 'Two beakers pouring into one cup. No faces.'),
  SectorTemplateSample(sectorId: 'a_drawing_color', displayName: 'Drawing & Color', presentMomentPrompt: 'Is filling shapes with bright colors fun for you right now?', activityLabel: 'Coloring shapes', pictureDescription: 'Crayons next to an outlined star and circle.'),
  SectorTemplateSample(sectorId: 'a_music_rhythm', displayName: 'Music & Rhythm', presentMomentPrompt: 'Is tapping a steady beat on a drum fun for you right now?', activityLabel: 'Rhythm tapping', pictureDescription: 'Simple hand tapping a plain drum. No face.'),
  SectorTemplateSample(sectorId: 'a_story_imagine', displayName: 'Story & Imagine', presentMomentPrompt: 'Is making up a silly story out loud fun for you right now?', activityLabel: 'Story imagining', pictureDescription: 'Open book with a star and moon icons floating above.'),
  SectorTemplateSample(sectorId: 'a_build_design', displayName: 'Build & Design', presentMomentPrompt: 'Is arranging shapes into a new pattern fun for you right now?', activityLabel: 'Shape design', pictureDescription: 'Triangles and squares forming a new layout.'),
  SectorTemplateSample(sectorId: 'a_performance_show', displayName: 'Performance & Show', presentMomentPrompt: 'Is acting out a short scene with toys fun for you right now?', activityLabel: 'Toy performance', pictureDescription: 'Two toy figures on a small stage. No faces.'),
  SectorTemplateSample(sectorId: 's_helping_caring', displayName: 'Helping & Caring', presentMomentPrompt: 'Is gently caring for a toy doll fun for you right now?', activityLabel: 'Caring play', pictureDescription: 'Hands tucking a blanket around a plain toy figure.'),
  SectorTemplateSample(sectorId: 's_teaching_showing', displayName: 'Teaching & Showing', presentMomentPrompt: 'Is showing a friend how a toy works fun for you right now?', activityLabel: 'Showing a toy', pictureDescription: 'One hand pointing at toy gears while another watches.'),
  SectorTemplateSample(sectorId: 's_team_play', displayName: 'Team Play', presentMomentPrompt: 'Is passing a ball back and forth with someone fun for you right now?', activityLabel: 'Cooperative ball play', pictureDescription: 'Two plain figures passing a ball. No facial detail.'),
  SectorTemplateSample(sectorId: 's_community_events', displayName: 'Community Events', presentMomentPrompt: 'Is walking through a busy fair with stalls fun for you right now?', activityLabel: 'Fair exploring', pictureDescription: 'Simple tents and banner flags. No crowd faces.'),
  SectorTemplateSample(sectorId: 's_friend_connections', displayName: 'Friend Connections', presentMomentPrompt: 'Is sharing a snack with a friend fun for you right now?', activityLabel: 'Friend sharing', pictureDescription: 'Two plain cups and a small snack plate.'),
  SectorTemplateSample(sectorId: 'e_leading_groups', displayName: 'Leading Groups', presentMomentPrompt: 'Is picking the next group game fun for you right now?', activityLabel: 'Leading play', pictureDescription: 'Plain figure pointing at three game cards on the ground.'),
  SectorTemplateSample(sectorId: 'e_selling_trading', displayName: 'Trading & Swapping', presentMomentPrompt: 'Is swapping trading cards with a friend fun for you right now?', activityLabel: 'Card swapping', pictureDescription: 'Two hands exchanging plain cards.'),
  SectorTemplateSample(sectorId: 'e_planning_events', displayName: 'Planning Events', presentMomentPrompt: 'Is planning a pretend picnic fun for you right now?', activityLabel: 'Picnic planning', pictureDescription: 'Checklist next to a blanket and basket icon.'),
  SectorTemplateSample(sectorId: 'e_persuading_sharing', displayName: 'Sharing Ideas', presentMomentPrompt: 'Is telling someone about a fun idea fun for you right now?', activityLabel: 'Idea sharing', pictureDescription: 'Speech bubble with a lightbulb icon. No face.'),
  SectorTemplateSample(sectorId: 'e_starting_projects', displayName: 'Starting Projects', presentMomentPrompt: 'Is starting a new craft project fun for you right now?', activityLabel: 'New project start', pictureDescription: 'Blank paper, scissors, and tape laid out neatly.'),
  SectorTemplateSample(sectorId: 'c_sorting_organizing', displayName: 'Sorting & Organizing', presentMomentPrompt: 'Is sorting buttons by color fun for you right now?', activityLabel: 'Color sorting', pictureDescription: 'Buttons grouped into three color piles.'),
  SectorTemplateSample(sectorId: 'c_schedules_routines', displayName: 'Schedules & Routines', presentMomentPrompt: 'Is following a picture schedule fun for you right now?', activityLabel: 'Picture schedule', pictureDescription: 'Three picture cards in a row with arrows.'),
  SectorTemplateSample(sectorId: 'c_lists_checklists', displayName: 'Lists & Checklists', presentMomentPrompt: 'Is checking off a simple to-do list fun for you right now?', activityLabel: 'Checklist play', pictureDescription: 'Clipboard with three checkboxes, two checked.'),
  SectorTemplateSample(sectorId: 'c_collecting_sets', displayName: 'Collecting Sets', presentMomentPrompt: 'Is lining up a complete sticker set fun for you right now?', activityLabel: 'Set collecting', pictureDescription: 'Sticker sheet with one empty spot highlighted.'),
  SectorTemplateSample(sectorId: 'c_patterns_order', displayName: 'Patterns & Order', presentMomentPrompt: 'Is making a repeating color pattern fun for you right now?', activityLabel: 'Pattern making', pictureDescription: 'Red-blue-red-blue bead sequence on a string.'),
];

SectorTemplateSample? sectorTemplateById(String sectorId) {
  for (final sample in kSectorTemplateCatalog) {
    if (sample.sectorId == sectorId) return sample;
  }
  return null;
}

SectorTemplateSample templateForSector(RiasecSector sector) {
  return sectorTemplateById(sector.id) ??
      SectorTemplateSample(
        sectorId: sector.id,
        displayName: sector.displayName,
        presentMomentPrompt: 'Is ${sector.playTheme} fun for you right now?',
        activityLabel: sector.displayName,
        pictureDescription: 'Simple drawing related to ${sector.playTheme}. No faces.',
      );
}
