import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  selectSyntheticSurvivors,
  survivalThresholdAfterLayer,
  type SyntheticLayerSignal,
} from "../functions/_shared/synthetic_engine2_funnel.ts";

type Sector = `sector_${number}`;

function signal(
  index: number,
  isolationScore: number,
  supportLevel = 0,
): SyntheticLayerSignal<Sector> {
  return {
    sector: `sector_${index}`,
    isolationScore,
    supportLevel,
    activeIndex: index,
  };
}

Deno.test("synthetic Engine 2 retains every Layer 1 sector above the explicit score bar", () => {
  const signals = Array.from(
    { length: 30 },
    (_, index) => signal(index, index < 20 ? 0.80 : 0.59),
  );

  assertEquals(survivalThresholdAfterLayer(1), 0.60);
  assertEquals(
    selectSyntheticSurvivors(signals, 1),
    Array.from({ length: 20 }, (_, index) => `sector_${index}`),
  );
});

Deno.test("synthetic Engine 2 carries only the five Layer 1 sectors that clear the same bar", () => {
  const signals = Array.from(
    { length: 30 },
    (_, index) => signal(index, index < 5 ? 0.62 : 0.59),
  );

  assertEquals(
    selectSyntheticSurvivors(signals, 1),
    Array.from({ length: 5 }, (_, index) => `sector_${index}`),
  );
});

Deno.test("synthetic Engine 2 filters later layers from their latest response signals", () => {
  const signals = [
    signal(0, 0.81),
    signal(1, 0.60),
    signal(2, 0.59),
    signal(3, 0.40),
  ];

  // Layer 4 uses the same latest-score bar; it does not use a fixed survivor
  // count or carry forward a prior-layer ranking.
  assertEquals(survivalThresholdAfterLayer(4), 0.60);
  assertEquals(selectSyntheticSurvivors(signals, 4), ["sector_0", "sector_1"]);
});

Deno.test("synthetic Engine 2 keeps one deterministic capstone sector for Layer 10", () => {
  const signals = [
    signal(0, 0.90, 1),
    signal(1, 0.90, 0),
    signal(2, 0.89, 0),
  ];

  assertEquals(survivalThresholdAfterLayer(9), 0.60);
  assertEquals(selectSyntheticSurvivors(signals, 9), ["sector_1"]);
});

Deno.test("synthetic Engine 2 has a deterministic fallback when no sector reaches a bar", () => {
  const signals = [signal(0, 0.50), signal(1, 0.54), signal(2, 0.53)];

  assertEquals(selectSyntheticSurvivors(signals, 1), ["sector_1"]);
});
