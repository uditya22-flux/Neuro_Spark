/// Static RIASEC sector metadata — mirrors `supabase/migrations` seed order.
class RiasecSector {
  const RiasecSector({
    required this.id,
    required this.riasecType,
    required this.displayName,
    required this.playTheme,
  });

  final String id;
  final String riasecType;
  final String displayName;
  final String playTheme;
}

const kRiasecSectors = <RiasecSector>[
  RiasecSector(id: 'r_build_fix', riasecType: 'realistic', displayName: 'Build & Fix', playTheme: 'building blocks and fixing things'),
  RiasecSector(id: 'r_nature_outdoors', riasecType: 'realistic', displayName: 'Nature Outdoors', playTheme: 'plants, trails, and outdoor exploring'),
  RiasecSector(id: 'r_sports_movement', riasecType: 'realistic', displayName: 'Sports & Movement', playTheme: 'running, climbing, and active play'),
  RiasecSector(id: 'r_crafts_making', riasecType: 'realistic', displayName: 'Crafts & Making', playTheme: 'hands-on making and crafting'),
  RiasecSector(id: 'r_vehicles_machines', riasecType: 'realistic', displayName: 'Vehicles & Machines', playTheme: 'trains, wheels, and simple machines'),
  RiasecSector(id: 'i_puzzles_logic', riasecType: 'investigative', displayName: 'Puzzles & Logic', playTheme: 'logic puzzles and figuring things out'),
  RiasecSector(id: 'i_nature_science', riasecType: 'investigative', displayName: 'Nature Science', playTheme: 'bugs, rocks, and curious observing'),
  RiasecSector(id: 'i_numbers_patterns', riasecType: 'investigative', displayName: 'Numbers & Patterns', playTheme: 'counting patterns and sequences'),
  RiasecSector(id: 'i_maps_exploring', riasecType: 'investigative', displayName: 'Maps & Exploring', playTheme: 'maps, mazes, and path finding'),
  RiasecSector(id: 'i_experiments_trying', riasecType: 'investigative', displayName: 'Experiments & Trying', playTheme: 'mixing, testing, and trying ideas'),
  RiasecSector(id: 'a_drawing_color', riasecType: 'artistic', displayName: 'Drawing & Color', playTheme: 'drawing, coloring, and visual art'),
  RiasecSector(id: 'a_music_rhythm', riasecType: 'artistic', displayName: 'Music & Rhythm', playTheme: 'sounds, beats, and rhythm play'),
  RiasecSector(id: 'a_story_imagine', riasecType: 'artistic', displayName: 'Story & Imagine', playTheme: 'stories, characters, and imagination'),
  RiasecSector(id: 'a_build_design', riasecType: 'artistic', displayName: 'Build & Design', playTheme: 'designing shapes and creative layouts'),
  RiasecSector(id: 'a_performance_show', riasecType: 'artistic', displayName: 'Performance & Show', playTheme: 'acting out and playful performance'),
  RiasecSector(id: 's_helping_caring', riasecType: 'social', displayName: 'Helping & Caring', playTheme: 'helping others and gentle care play'),
  RiasecSector(id: 's_teaching_showing', riasecType: 'social', displayName: 'Teaching & Showing', playTheme: 'showing how something works to a friend'),
  RiasecSector(id: 's_team_play', riasecType: 'social', displayName: 'Team Play', playTheme: 'cooperative games and shared goals'),
  RiasecSector(id: 's_community_events', riasecType: 'social', displayName: 'Community Events', playTheme: 'festivals, groups, and gatherings'),
  RiasecSector(id: 's_friend_connections', riasecType: 'social', displayName: 'Friend Connections', playTheme: 'friendship routines and social play'),
  RiasecSector(id: 'e_leading_groups', riasecType: 'enterprising', displayName: 'Leading Groups', playTheme: 'leading a small play group activity'),
  RiasecSector(id: 'e_selling_trading', riasecType: 'enterprising', displayName: 'Trading & Swapping', playTheme: 'swapping cards and playful trading'),
  RiasecSector(id: 'e_planning_events', riasecType: 'enterprising', displayName: 'Planning Events', playTheme: 'planning a pretend party or outing'),
  RiasecSector(id: 'e_persuading_sharing', riasecType: 'enterprising', displayName: 'Sharing Ideas', playTheme: 'sharing a fun idea with others'),
  RiasecSector(id: 'e_starting_projects', riasecType: 'enterprising', displayName: 'Starting Projects', playTheme: 'starting a small creative project'),
  RiasecSector(id: 'c_sorting_organizing', riasecType: 'conventional', displayName: 'Sorting & Organizing', playTheme: 'sorting objects into groups'),
  RiasecSector(id: 'c_schedules_routines', riasecType: 'conventional', displayName: 'Schedules & Routines', playTheme: 'daily routines and timetables'),
  RiasecSector(id: 'c_lists_checklists', riasecType: 'conventional', displayName: 'Lists & Checklists', playTheme: 'checklists and step-by-step lists'),
  RiasecSector(id: 'c_collecting_sets', riasecType: 'conventional', displayName: 'Collecting Sets', playTheme: 'collecting and completing sets'),
  RiasecSector(id: 'c_patterns_order', riasecType: 'conventional', displayName: 'Patterns & Order', playTheme: 'patterns, order, and neat arrangements'),
];

List<String> allRiasecSectorIds() => kRiasecSectors.map((s) => s.id).toList();

RiasecSector? sectorById(String id) {
  for (final sector in kRiasecSectors) {
    if (sector.id == id) return sector;
  }
  return null;
}
