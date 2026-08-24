/**
 * 60% adaptive filtering algorithm for the 10-layer RIASEC strength funnel.
 *
 * Layer 1: 30 sectors → Layer 2: 18 → Layer 3: 11 → Layer 4: 7 → Layer 5: 4
 * Layers 6–10: deep-dive (no further elimination; complexity increases).
 */

export const TOTAL_SECTORS = 30;
export const FILTER_RATIO = 0.6;

/** Sector counts advancing *into* each layer (per .cursorrules §4). */
export const LAYER_SECTOR_TARGETS: Record<number, number> = {
  1: 30,
  2: 18,
  3: 11,
  4: 7,
  5: 4,
  6: 4,
  7: 3,
  8: 3,
  9: 2,
  10: 2,
};

export interface SectorEngagement {
  sectorId: string;
  engagementScore: number;
}

/** Returns how many sectors should advance after completing [layer]. */
export function sectorsAdvancingAfterLayer(layer: number): number {
  if (layer >= 6) {
    return LAYER_SECTOR_TARGETS[layer] ?? 2;
  }
  return LAYER_SECTOR_TARGETS[layer + 1] ??
    Math.max(2, Math.ceil(LAYER_SECTOR_TARGETS[layer] * FILTER_RATIO));
}

/** Returns sector count assessed at the start of [layer]. */
export function sectorsAtLayerStart(layer: number): number {
  return LAYER_SECTOR_TARGETS[layer] ?? TOTAL_SECTORS;
}

/**
 * Selects top N sectors by engagement score (stable sort by sectorId tie-break).
 */
export function selectAdvancingSectors(
  scores: SectorEngagement[],
  advanceCount: number,
): string[] {
  return [...scores]
    .sort((a, b) => {
      const diff = b.engagementScore - a.engagementScore;
      if (diff !== 0) return diff;
      return a.sectorId.localeCompare(b.sectorId);
    })
    .slice(0, Math.max(0, advanceCount))
    .map((s) => s.sectorId);
}

/** Whether this layer eliminates sectors or only deepens complexity. */
export function isEliminationLayer(layer: number): boolean {
  return layer <= 5;
}

/** All 30 sector ids in deterministic order (matches migration seed). */
export function allSectorIds(): string[] {
  return [
    "r_build_fix", "r_nature_outdoors", "r_sports_movement", "r_crafts_making",
    "r_vehicles_machines",
    "i_puzzles_logic", "i_nature_science", "i_numbers_patterns", "i_maps_exploring",
    "i_experiments_trying",
    "a_drawing_color", "a_music_rhythm", "a_story_imagine", "a_build_design",
    "a_performance_show",
    "s_helping_caring", "s_teaching_showing", "s_team_play", "s_community_events",
    "s_friend_connections",
    "e_leading_groups", "e_selling_trading", "e_planning_events",
    "e_persuading_sharing", "e_starting_projects",
    "c_sorting_organizing", "c_schedules_routines", "c_lists_checklists",
    "c_collecting_sets", "c_patterns_order",
  ];
}

export function initialActiveSectors(): string[] {
  return allSectorIds();
}
