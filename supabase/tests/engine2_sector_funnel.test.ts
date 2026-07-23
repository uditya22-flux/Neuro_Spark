import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  computeTrackAffinity,
  survivingSectorsForLayer,
  SECTORS,
  SectorId,
} from "../functions/_shared/engine2.ts";

Deno.test("computeTrackAffinity calculates correct weights for Constellation vs Calendar", () => {
  // Constellation-leaning strong performance
  const constellationScores: Record<string, number> = {
    spatial_reasoning: 0.95,
    visual_anomaly_detection: 0.90,
    pattern_recognition: 0.85,
    motor_precision: 0.80,
    sequencing_ordering: 0.20,
    working_memory: 0.25,
    numeric_reasoning: 0.30,
    categorization: 0.30,
    auditory_processing: 0.50,
    verbal_language: 0.50,
  };

  const affinity = computeTrackAffinity(constellationScores);
  assertEquals(affinity.leader, "constellation_mapper");
  assertEquals(affinity.isAmbiguous, false);
  assertEquals(affinity.constellation_mapper > affinity.calendar_genius, true);

  // Calendar-leaning strong performance
  const calendarScores: Record<string, number> = {
    spatial_reasoning: 0.20,
    visual_anomaly_detection: 0.25,
    pattern_recognition: 0.30,
    motor_precision: 0.30,
    sequencing_ordering: 0.95,
    working_memory: 0.90,
    numeric_reasoning: 0.85,
    categorization: 0.80,
    auditory_processing: 0.50,
    verbal_language: 0.50,
  };

  const calAffinity = computeTrackAffinity(calendarScores);
  assertEquals(calAffinity.leader, "calendar_genius");
  assertEquals(calAffinity.isAmbiguous, false);
  assertEquals(calAffinity.calendar_genius > calAffinity.constellation_mapper, true);
});

Deno.test("survivingSectorsForLayer correctly applies wide-to-narrow elimination schedule", () => {
  const ranked = [...SECTORS] as SectorId[];

  assertEquals(survivingSectorsForLayer(1, ranked).length, 10);
  assertEquals(survivingSectorsForLayer(2, ranked).length, 6);
  assertEquals(survivingSectorsForLayer(3, ranked).length, 4);
  assertEquals(survivingSectorsForLayer(4, ranked).length, 3);
  assertEquals(survivingSectorsForLayer(5, ranked).length, 2);
  assertEquals(survivingSectorsForLayer(6, ranked).length, 2);
  assertEquals(survivingSectorsForLayer(10, ranked).length, 2);
});
