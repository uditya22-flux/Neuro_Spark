import { assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  assertPresentMomentFraming,
  normalizeIsaaProfile,
  routeModalityFromIsaa,
} from "../functions/_shared/modality_router.ts";

Deno.test("modality router — low verbal ISAA routes to visual-first, no text", () => {
  const constraints = routeModalityFromIsaa({
    speechCommunication: 5,
    sensoryAspects: 3,
  });

  assertEquals(constraints.requiresVisualItems, true);
  assertEquals(constraints.allowText, false);
  assertEquals(constraints.useSimpleConcreteDrawings, true);
});

Deno.test("modality router — high sensory disables animations and video", () => {
  const constraints = routeModalityFromIsaa({
    speechCommunication: 2,
    sensoryAspects: 5,
    visualTriggers: ["Rapid flashing"],
  });

  assertEquals(constraints.disableAnimations, true);
  assertEquals(constraints.allowVideo, false);
});

Deno.test("modality router — text allowed for lower speech support scores", () => {
  const constraints = routeModalityFromIsaa({
    speechCommunication: 2,
    sensoryAspects: 2,
  });

  assertEquals(constraints.allowText, true);
  assertEquals(constraints.primaryModality, "text");
});

Deno.test("modality router — haptics when preferred and sound-sensitive", () => {
  const constraints = routeModalityFromIsaa({
    speechCommunication: 5,
    sensoryAspects: 5,
    soundTriggers: ["Sudden loud chime"],
    tactilePreference: "prefers_haptics",
  });

  assertEquals(constraints.allowHaptics, true);
});

Deno.test("golden rule validator rejects career framing", () => {
  assertThrows(
    () =>
      assertPresentMomentFraming({
        prompt: "Would you like this as a future career?",
      }),
  );
});

Deno.test("normalizeIsaaProfile clamps scores to 1-5", () => {
  const profile = normalizeIsaaProfile({ speechCommunication: 99, sensoryAspects: 0 });
  assertEquals(profile.speechCommunication, 5);
  assertEquals(profile.sensoryAspects, 1);
});
