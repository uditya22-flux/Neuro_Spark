/**
 * Canonical sample tasks for all 30 RIASEC sectors.
 * Used for DB seeding and offline local fallback prompts.
 * Charter: present-moment enjoyment only — no career framing.
 */

export interface SectorSample {
  sectorId: string;
  riasecType: string;
  displayName: string;
  playTheme: string;
  presentMomentPrompt: string;
  activityLabel: string;
  pictureDescription: string;
  videoDescription?: string;
}

const GOLDEN_FRAMING = {
  golden_rule:
    "Measure present-moment enjoyment only. Never reference future jobs, careers, salaries, or adult work roles.",
  prompt_tone: "playful_now",
  forbidden_terms: [
    "career", "job", "employ", "salary", "when you grow up",
    "become a", "profession", "industry",
  ],
  required_framing: "Ask whether the child is enjoying this activity right now.",
};

const VISUAL_GUIDELINES = {
  style: "simple_stylized_drawing",
  show_gender_features: false,
  show_complex_facial_expressions: false,
  focus: "concrete_activity_only",
  avoid_visual_clutter: true,
};

const ENJOYMENT_SCALE = {
  type: "present_moment_likert_visual",
  min_label: "Not fun right now",
  max_label: "Really fun right now",
};

export const SECTOR_TEMPLATE_SAMPLES: SectorSample[] = [
  { sectorId: "r_build_fix", riasecType: "realistic", displayName: "Build & Fix", playTheme: "building blocks and fixing things", presentMomentPrompt: "Is snapping blocks together fun for you right now?", activityLabel: "Building a small tower", pictureDescription: "Side-view of hands stacking three plain blocks. No faces." },
  { sectorId: "r_nature_outdoors", riasecType: "realistic", displayName: "Nature Outdoors", playTheme: "plants, trails, and outdoor exploring", presentMomentPrompt: "Is walking on a leafy trail fun for you right now?", activityLabel: "Trail exploring", pictureDescription: "Simple path with trees and leaves. No people faces." },
  { sectorId: "r_sports_movement", riasecType: "realistic", displayName: "Sports & Movement", playTheme: "running, climbing, and active play", presentMomentPrompt: "Is climbing on playground bars fun for you right now?", activityLabel: "Climbing and running", pictureDescription: "Plain figure on monkey bars, side view. No facial detail." },
  { sectorId: "r_crafts_making", riasecType: "realistic", displayName: "Crafts & Making", playTheme: "hands-on making and crafting", presentMomentPrompt: "Is gluing paper shapes together fun for you right now?", activityLabel: "Paper crafting", pictureDescription: "Hands holding glue stick and colored paper. No faces." },
  { sectorId: "r_vehicles_machines", riasecType: "realistic", displayName: "Vehicles & Machines", playTheme: "trains, wheels, and simple machines", presentMomentPrompt: "Is rolling toy wheels back and forth fun for you right now?", activityLabel: "Toy wheels and trains", pictureDescription: "Simple toy train on a track. Neutral colors." },
  { sectorId: "i_puzzles_logic", riasecType: "investigative", displayName: "Puzzles & Logic", playTheme: "logic puzzles and figuring things out", presentMomentPrompt: "Is fitting puzzle pieces together fun for you right now?", activityLabel: "Jigsaw puzzle", pictureDescription: "Two puzzle pieces about to connect. Minimal background." },
  { sectorId: "i_nature_science", riasecType: "investigative", displayName: "Nature Science", playTheme: "bugs, rocks, and curious observing", presentMomentPrompt: "Is looking at a bug with a magnifier fun for you right now?", activityLabel: "Bug observing", pictureDescription: "Magnifying glass over a leaf with a simple bug shape." },
  { sectorId: "i_numbers_patterns", riasecType: "investigative", displayName: "Numbers & Patterns", playTheme: "counting patterns and sequences", presentMomentPrompt: "Is lining up counting blocks in order fun for you right now?", activityLabel: "Number patterns", pictureDescription: "Colored blocks numbered 1-2-3 in a row." },
  { sectorId: "i_maps_exploring", riasecType: "investigative", displayName: "Maps & Exploring", playTheme: "maps, mazes, and path finding", presentMomentPrompt: "Is tracing a path through a maze fun for you right now?", activityLabel: "Maze path", pictureDescription: "Simple top-down maze with one clear route." },
  { sectorId: "i_experiments_trying", riasecType: "investigative", displayName: "Experiments & Trying", playTheme: "mixing, testing, and trying ideas", presentMomentPrompt: "Is mixing two safe liquids in a cup fun for you right now?", activityLabel: "Mix and try", pictureDescription: "Two beakers pouring into one cup. No faces." },
  { sectorId: "a_drawing_color", riasecType: "artistic", displayName: "Drawing & Color", playTheme: "drawing, coloring, and visual art", presentMomentPrompt: "Is filling shapes with bright colors fun for you right now?", activityLabel: "Coloring shapes", pictureDescription: "Crayons next to an outlined star and circle." },
  { sectorId: "a_music_rhythm", riasecType: "artistic", displayName: "Music & Rhythm", playTheme: "sounds, beats, and rhythm play", presentMomentPrompt: "Is tapping a steady beat on a drum fun for you right now?", activityLabel: "Rhythm tapping", pictureDescription: "Simple hand tapping a plain drum. No face." },
  { sectorId: "a_story_imagine", riasecType: "artistic", displayName: "Story & Imagine", playTheme: "stories, characters, and imagination", presentMomentPrompt: "Is making up a silly story out loud fun for you right now?", activityLabel: "Story imagining", pictureDescription: "Open book with a star and moon icons floating above." },
  { sectorId: "a_build_design", riasecType: "artistic", displayName: "Build & Design", playTheme: "designing shapes and creative layouts", presentMomentPrompt: "Is arranging shapes into a new pattern fun for you right now?", activityLabel: "Shape design", pictureDescription: "Triangles and squares forming a new layout." },
  { sectorId: "a_performance_show", riasecType: "artistic", displayName: "Performance & Show", playTheme: "acting out and playful performance", presentMomentPrompt: "Is acting out a short scene with toys fun for you right now?", activityLabel: "Toy performance", pictureDescription: "Two toy figures on a small stage. No faces." },
  { sectorId: "s_helping_caring", riasecType: "social", displayName: "Helping & Caring", playTheme: "helping others and gentle care play", presentMomentPrompt: "Is gently caring for a toy doll fun for you right now?", activityLabel: "Caring play", pictureDescription: "Hands tucking a blanket around a plain toy figure." },
  { sectorId: "s_teaching_showing", riasecType: "social", displayName: "Teaching & Showing", playTheme: "showing how something works to a friend", presentMomentPrompt: "Is showing a friend how a toy works fun for you right now?", activityLabel: "Showing a toy", pictureDescription: "One hand pointing at toy gears while another watches." },
  { sectorId: "s_team_play", riasecType: "social", displayName: "Team Play", playTheme: "cooperative games and shared goals", presentMomentPrompt: "Is passing a ball back and forth with someone fun for you right now?", activityLabel: "Cooperative ball play", pictureDescription: "Two plain figures passing a ball. No facial detail." },
  { sectorId: "s_community_events", riasecType: "social", displayName: "Community Events", playTheme: "festivals, groups, and gatherings", presentMomentPrompt: "Is walking through a busy fair with stalls fun for you right now?", activityLabel: "Fair exploring", pictureDescription: "Simple tents and banner flags. No crowd faces." },
  { sectorId: "s_friend_connections", riasecType: "social", displayName: "Friend Connections", playTheme: "friendship routines and social play", presentMomentPrompt: "Is sharing a snack with a friend fun for you right now?", activityLabel: "Friend sharing", pictureDescription: "Two plain cups and a small snack plate." },
  { sectorId: "e_leading_groups", riasecType: "enterprising", displayName: "Leading Groups", playTheme: "leading a small play group activity", presentMomentPrompt: "Is picking the next group game fun for you right now?", activityLabel: "Leading play", pictureDescription: "Plain figure pointing at three game cards on the ground." },
  { sectorId: "e_selling_trading", riasecType: "enterprising", displayName: "Trading & Swapping", playTheme: "swapping cards and playful trading", presentMomentPrompt: "Is swapping trading cards with a friend fun for you right now?", activityLabel: "Card swapping", pictureDescription: "Two hands exchanging plain cards." },
  { sectorId: "e_planning_events", riasecType: "enterprising", displayName: "Planning Events", playTheme: "planning a pretend party or outing", presentMomentPrompt: "Is planning a pretend picnic fun for you right now?", activityLabel: "Picnic planning", pictureDescription: "Checklist next to a blanket and basket icon." },
  { sectorId: "e_persuading_sharing", riasecType: "enterprising", displayName: "Sharing Ideas", playTheme: "sharing a fun idea with others", presentMomentPrompt: "Is telling someone about a fun idea fun for you right now?", activityLabel: "Idea sharing", pictureDescription: "Speech bubble with a lightbulb icon. No face." },
  { sectorId: "e_starting_projects", riasecType: "enterprising", displayName: "Starting Projects", playTheme: "starting a small creative project", presentMomentPrompt: "Is starting a new craft project fun for you right now?", activityLabel: "New project start", pictureDescription: "Blank paper, scissors, and tape laid out neatly." },
  { sectorId: "c_sorting_organizing", riasecType: "conventional", displayName: "Sorting & Organizing", playTheme: "sorting objects into groups", presentMomentPrompt: "Is sorting buttons by color fun for you right now?", activityLabel: "Color sorting", pictureDescription: "Buttons grouped into three color piles." },
  { sectorId: "c_schedules_routines", riasecType: "conventional", displayName: "Schedules & Routines", playTheme: "daily routines and timetables", presentMomentPrompt: "Is following a picture schedule fun for you right now?", activityLabel: "Picture schedule", pictureDescription: "Three picture cards in a row with arrows." },
  { sectorId: "c_lists_checklists", riasecType: "conventional", displayName: "Lists & Checklists", playTheme: "checklists and step-by-step lists", presentMomentPrompt: "Is checking off a simple to-do list fun for you right now?", activityLabel: "Checklist play", pictureDescription: "Clipboard with three checkboxes, two checked." },
  { sectorId: "c_collecting_sets", riasecType: "conventional", displayName: "Collecting Sets", playTheme: "collecting and completing sets", presentMomentPrompt: "Is lining up a complete sticker set fun for you right now?", activityLabel: "Set collecting", pictureDescription: "Sticker sheet with one empty spot highlighted." },
  { sectorId: "c_patterns_order", riasecType: "conventional", displayName: "Patterns & Order", playTheme: "patterns, order, and neat arrangements", presentMomentPrompt: "Is making a repeating color pattern fun for you right now?", activityLabel: "Pattern making", pictureDescription: "Red-blue-red-blue bead sequence on a string." },
];

export function sampleBySectorId(sectorId: string): SectorSample | undefined {
  return SECTOR_TEMPLATE_SAMPLES.find((s) => s.sectorId === sectorId);
}

export function buildTemplateJson(sample: SectorSample): Record<string, unknown> {
  return {
    template_version: "2026-08-24",
    sector_id: sample.sectorId,
    riasec_type: sample.riasecType,
    display_name: sample.displayName,
    framing_rules: GOLDEN_FRAMING,
    visual_guidelines: VISUAL_GUIDELINES,
    sample_generated_task: {
      present_moment_prompt: sample.presentMomentPrompt,
      activity_scene: {
        activity_label: sample.activityLabel,
        simple_picture_description: sample.pictureDescription,
        optional_video_loop_description: sample.videoDescription ??
          "Silent 3-second activity loop with no background music.",
      },
      response_modality: "picture",
      enjoyment_scale: ENJOYMENT_SCALE,
    },
    play_concept_sources: [
      "pediatric_iconographic_inventories",
      "elementary_hobby_drawings_age_8_to_13",
    ],
  };
}

/** Layer 2–5 adds specificity; layers 6–10 deepen present-moment focus. */
export function layerAdjustedPrompt(sample: SectorSample, layer: number): string {
  if (layer <= 1) return sample.presentMomentPrompt;
  if (layer >= 6) return deepDivePrompt(sample, layer);
  const base = sample.presentMomentPrompt.replace(/\?$/, "");
  return `${base} — thinking about ${sample.activityLabel.toLowerCase()}?`;
}

const DEEP_DIVE_CUES = [
  "noticing this exact moment",
  "the small details you like",
  "staying with this activity",
  "how absorbed you feel",
  "your strongest spark right now",
];

export function deepDivePrompt(sample: SectorSample, layer: number): string {
  const depthIndex = Math.min(Math.max(layer - 6, 0), DEEP_DIVE_CUES.length - 1);
  const base = sample.presentMomentPrompt.replace(/\?$/, "");
  return `${base} — ${DEEP_DIVE_CUES[depthIndex]}?`;
}

export function isDeepDiveLayer(layer: number): boolean {
  return layer >= 6;
}

export function catalogTemplateForSector(
  sectorId: string,
): Record<string, unknown> | null {
  const sample = sampleBySectorId(sectorId);
  return sample ? buildTemplateJson(sample) : null;
}
