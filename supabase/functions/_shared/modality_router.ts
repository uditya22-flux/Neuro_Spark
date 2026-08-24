/**
 * ISAA Modality Routing Engine
 *
 * Maps Indian Scale for Assessment of Autism (ISAA) domain scores and sensory
 * triggers to UI/generation constraints for the 30-sector strength funnel.
 *
 * Charter: exploration-only routing — not diagnostic labeling.
 */

export interface IsaaProfile {
  socialRelationship: number;
  emotionalResponsiveness: number;
  speechCommunication: number;
  behaviorPatterns: number;
  sensoryAspects: number;
  cognitiveComponent: number;
  soundTriggers?: string[];
  visualTriggers?: string[];
  tactilePreference?: "prefers_haptics" | "no_vibrations" | "neutral";
}

export interface ModalityConstraints {
  /** Prefer stylized picture cards over reading. */
  requiresVisualItems: boolean;
  /** Text prompts and reading-based UI allowed. */
  allowText: boolean;
  /** Short looping video clips allowed. */
  allowVideo: boolean;
  /** Haptic confirmation channels allowed. */
  allowHaptics: boolean;
  /** Disable motion, parallax, and animated transitions. */
  disableAnimations: boolean;
  /** Use simplified concrete drawings — no gender cues or complex faces. */
  useSimpleConcreteDrawings: boolean;
  /** Primary modality the Layer 1 renderer should prefer. */
  primaryModality: "picture" | "video" | "text" | "haptic";
  /** Secondary fallbacks in priority order. */
  fallbackModalities: Array<"picture" | "video" | "text" | "haptic">;
  /** Pacing multiplier (>1 = slower). */
  pacingMultiplier: number;
}

const clampScore = (value: number): number => Math.max(1, Math.min(5, value));

export function normalizeIsaaProfile(raw: Partial<IsaaProfile>): IsaaProfile {
  return {
    socialRelationship: clampScore(raw.socialRelationship ?? 3),
    emotionalResponsiveness: clampScore(raw.emotionalResponsiveness ?? 3),
    speechCommunication: clampScore(raw.speechCommunication ?? 3),
    behaviorPatterns: clampScore(raw.behaviorPatterns ?? 3),
    sensoryAspects: clampScore(raw.sensoryAspects ?? 3),
    cognitiveComponent: clampScore(raw.cognitiveComponent ?? 3),
    soundTriggers: raw.soundTriggers ?? [],
    visualTriggers: raw.visualTriggers ?? [],
    tactilePreference: raw.tactilePreference ?? "neutral",
  };
}

/**
 * Core routing function referenced by .cursorrules §2.
 */
export function routeModalityFromIsaa(raw: Partial<IsaaProfile>): ModalityConstraints {
  const profile = normalizeIsaaProfile(raw);

  const lowVerbal = profile.speechCommunication >= 4;
  const moderateVerbal = profile.speechCommunication === 3;
  const highSensory =
    profile.sensoryAspects >= 4 ||
    (profile.visualTriggers?.length ?? 0) > 0;
  const soundSensitive =
    profile.sensoryAspects >= 4 ||
    (profile.soundTriggers?.length ?? 0) > 0;
  const prefersHaptics = profile.tactilePreference === "prefers_haptics";
  const noVibrations = profile.tactilePreference === "no_vibrations";

  const requiresVisualItems = lowVerbal || highSensory || moderateVerbal;
  const allowText = !lowVerbal && profile.speechCommunication <= 2;
  const allowVideo = !highSensory && !soundSensitive &&
    profile.sensoryAspects <= 3;
  const allowHaptics = !noVibrations &&
    (prefersHaptics || (soundSensitive && !noVibrations));
  const disableAnimations = highSensory ||
    (profile.visualTriggers ?? []).some((t) =>
      /flash|parallax|floating|busy/i.test(t)
    );
  const useSimpleConcreteDrawings = true; // always per .cursorrules §2

  let primaryModality: ModalityConstraints["primaryModality"] = "picture";
  const fallbacks: ModalityConstraints["fallbackModalities"] = [];

  if (lowVerbal) {
    primaryModality = allowHaptics ? "haptic" : "picture";
    fallbacks.push("picture");
    if (allowHaptics) fallbacks.push("haptic");
  } else if (allowText) {
    primaryModality = "text";
    fallbacks.push("picture");
  } else if (allowVideo) {
    primaryModality = "video";
    fallbacks.push("picture", "text");
  } else {
    primaryModality = "picture";
    if (allowHaptics) fallbacks.push("haptic");
  }

  const pacingMultiplier = highSensory ? 1.35 : profile.behaviorPatterns >= 4
    ? 1.15
    : 1.0;

  return {
    requiresVisualItems,
    allowText,
    allowVideo,
    allowHaptics,
    disableAnimations,
    useSimpleConcreteDrawings,
    primaryModality,
    fallbackModalities: fallbacks,
    pacingMultiplier,
  };
}

/** Validates generated task JSON against golden-rule forbidden terms. */
export function assertPresentMomentFraming(payload: Record<string, unknown>): void {
  const forbidden = [
    "career",
    "job",
    "employ",
    "salary",
    "when you grow up",
    "become a",
    "profession",
    "industry",
    "diagnos",
    "disorder",
  ];
  const text = JSON.stringify(payload).toLowerCase();
  for (const term of forbidden) {
    if (text.includes(term)) {
      throw new Error(
        `Generated task violates golden rule (forbidden term: ${term}).`,
      );
    }
  }
}

export function constraintsToJson(constraints: ModalityConstraints): Record<string, unknown> {
  return { ...constraints };
}
