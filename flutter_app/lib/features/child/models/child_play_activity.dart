import 'package:flutter/material.dart';

/// One present-moment play card derived from a strength-funnel finalist sector.
class ChildPlayActivity {
  const ChildPlayActivity({
    required this.sectorId,
    required this.displayName,
    required this.activityLabel,
    required this.presentMomentPrompt,
    required this.pictureDescription,
    required this.modality,
    required this.icon,
  });

  final String sectorId;
  final String displayName;
  final String activityLabel;
  final String presentMomentPrompt;
  final String pictureDescription;
  final String modality;
  final IconData icon;
}

IconData iconForSectorId(String sectorId) {
  return switch (sectorId) {
    'r_build_fix' => Icons.construction_rounded,
    'r_nature_outdoors' => Icons.park_rounded,
    'r_sports_movement' => Icons.directions_run_rounded,
    'r_crafts_making' => Icons.brush_rounded,
    'r_vehicles_machines' => Icons.train_rounded,
    'i_puzzles_logic' => Icons.extension_rounded,
    'i_nature_science' => Icons.biotech_rounded,
    'i_numbers_patterns' => Icons.grid_on_rounded,
    'i_maps_exploring' => Icons.map_rounded,
    'i_experiments_trying' => Icons.science_rounded,
    'a_drawing_color' => Icons.palette_rounded,
    'a_music_rhythm' => Icons.music_note_rounded,
    'a_story_imagine' => Icons.auto_stories_rounded,
    'a_build_design' => Icons.category_rounded,
    'a_performance_show' => Icons.theaters_rounded,
    's_helping_caring' => Icons.favorite_border_rounded,
    's_teaching_showing' => Icons.school_rounded,
    's_team_play' => Icons.groups_rounded,
    's_community_events' => Icons.celebration_rounded,
    's_friend_connections' => Icons.people_outline_rounded,
    'e_leading_groups' => Icons.record_voice_over_rounded,
    'e_selling_trading' => Icons.swap_horiz_rounded,
    'e_planning_events' => Icons.event_rounded,
    'e_persuading_sharing' => Icons.lightbulb_outline_rounded,
    'e_starting_projects' => Icons.rocket_launch_rounded,
    'c_sorting_organizing' => Icons.inventory_2_outlined,
    'c_schedules_routines' => Icons.view_timeline_rounded,
    'c_lists_checklists' => Icons.checklist_rounded,
    'c_collecting_sets' => Icons.collections_bookmark_outlined,
    'c_patterns_order' => Icons.repeat_rounded,
    _ => Icons.toys_rounded,
  };
}
