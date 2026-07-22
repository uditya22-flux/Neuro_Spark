import {
  assertEquals,
  assertExists,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  evaluateAnswer,
  layerProtocol,
  modalityForExecution,
  parseSelectedStarIds,
  pathForIsolation,
  pathLayers,
  publicTask,
  reEvaluatePath,
  requiredExecutions,
  scoreResponse,
  supportTransition,
  VERTICALS,
} from "../functions/_shared/engine2.ts";

Deno.test("Engine 2.a public task output never exposes the calendar answer key", () => {
  const task = publicTask({
    id: "task-1",
    layer_number: 1,
    vertical_id: "calendar_genius",
    source_type: "curated",
    difficulty_tier: "baseline",
    item_payload: {
      public_payload: {
        kind: "calendar-order",
        prompt: "Find the day for 2026-07-20.",
        target_date: "2026-07-20",
        correct_day: "Monday",
      },
      answer_key: { expected: "Monday" },
    },
  });

  assertEquals(task.answer_key_present, true);
  assertEquals(
    (task.task_data as Record<string, unknown>).correct_day,
    undefined,
  );
  assertFalse(JSON.stringify(task).includes("Monday"));
});

Deno.test("Engine 2.b constellation scoring rejects malformed selections", () => {
  const task = {
    public_payload: {
      stars: [{ id: "star-0" }, { id: "star-1" }, { id: "star-2" }],
    },
    answer_key: { requiredCount: 2 },
  };

  assertEquals(parseSelectedStarIds("connected_stars_0_2"), [0, 2]);
  assertEquals(evaluateAnswer(task, "connected_stars_0_2"), 1);
  assertEquals(evaluateAnswer(task, "connected_stars_0_0"), 0);
  assertEquals(evaluateAnswer(task, "connected_stars_0_4"), 0);
  assertEquals(evaluateAnswer(task, "0_2"), 0);
  assertEquals(parseSelectedStarIds("connected_stars_2_x"), null);
});

Deno.test("Engine 2.b path and support transitions stay bounded", () => {
  assertEquals(pathForIsolation(0.9, 0.9), "accelerated");
  assertEquals(pathForIsolation(0.5, 0.9), "standard");
  assertEquals(pathForIsolation(0.9, 0.2), "supported");
  assertEquals(pathLayers("accelerated"), [2, 3, 7, 10]);
  assertEquals(
    supportTransition(0, {
      accuracy: 0,
      latencyMs: 1,
      retryCount: 0,
      skipped: false,
      path: "supported",
    }).level,
    2,
  );
  assertEquals(
    supportTransition(5, {
      accuracy: 0,
      latencyMs: 1,
      retryCount: 0,
      skipped: false,
      path: "standard",
    }).level,
    5,
  );
  assertEquals(
    supportTransition(2, {
      accuracy: 1,
      latencyMs: 1000,
      retryCount: 0,
      skipped: false,
      path: "standard",
    }),
    {
      level: 1,
      reason: "sustained independent response",
      outcome: "de_escalated",
    },
  );

  const scored = scoreResponse(1, Number.NaN, 0, 0, false, "curated");
  assertEquals(scored.accuracy, 1);
  assertEquals(scored.latencyMs, 0);
  assertFalse(Number.isNaN(scored.isolationScore));
  assertEquals(
    scoreResponse(0.8, 20_000, 1, 0, false, "curated").isolationScore,
    scoreResponse(0.8, 20_000, 1, 0, false, "created").isolationScore,
  );
});

Deno.test("Engine 2 exposes ten exploration verticals and composes every task from three sources", async () => {
  assertEquals(VERTICALS.length, 10);
  const task = await (await import("../functions/_shared/engine2.ts"))
    .createTask(
      "logic_lens",
      2,
      "composition-seed",
      {
        activeVerticals: ["logic_lens"],
        sensory: {},
        layoutComplexityTier: "standard",
        hyperFocusTheme: "trains",
      },
    );
  assertExists(task.composition?.curatedBaselineId);
  assertExists(task.composition?.predictedVariantId);
  assertExists(task.composition?.createdInstanceId);
  const composition = (task.payload.content_composition ?? {}) as Record<
    string,
    unknown
  >;
  assertExists(composition.curated_baseline_id);
  assertExists(composition.predicted_variant_id);
  assertExists(composition.created_instance_id);
});

  assertEquals(requiredExecutions(1), 30);
  assertEquals(requiredExecutions(2), 10);
  assertEquals(layerProtocol("calendar_genius", 4).timingBudgetsMs, [
    60_000,
    45_000,
    30_000,
    15_000,
  ]);
  assertEquals(layerProtocol("calendar_genius", 5).modalities, [
    "visual",
    "audio",
    "animated",
    "interactive",
  ]);
  assertEquals(modalityForExecution(5, 4), "interactive");
  assertEquals(layerProtocol("calendar_genius", 8).instrumentationOnly, true);
  assertEquals(
    layerProtocol("calendar_genius", 3).structureId,
    "calendar_genius:novel-structure:v1",
  );
  assertEquals(
    layerProtocol("calendar_genius", 7).surfaceDomain,
    "route-planning",
  );
});

Deno.test("Engine 2 re-evaluates a per-vertical route without replacing the Layer 1 score", () => {
  const supported = reEvaluatePath(
    { isolationScore: 0.9, recovery: 0.9 },
    { accuracy: 0.9, recovery: 0.2, engagement: 0.9, speed: 0.9 },
  );
  assertEquals(supported.path, "supported");
  const accelerated = reEvaluatePath(
    { isolationScore: 0.9, recovery: 0.9 },
    { accuracy: 1, recovery: 1, engagement: 1, speed: 1 },
  );
  assertEquals(accelerated.path, "accelerated");
});

Deno.test("Engine 2 discovery mode uses independent domains (not calendar/constellation)", async () => {
  const { createTask } = await import("../functions/_shared/engine2.ts");
  const task = await createTask(
    "discovery",
    1,
    "test-seed",
    {
      activeVerticals: [],
      sensory: { low_contrast: false, slow_motion: false },
      layoutComplexityTier: "standard",
      hyperFocusTheme: "calm",
    },
    "visual",
    "baseline",
    { accuracy: 1.0 },
  );

  // Must be in the discovery vertical
  assertEquals(task.verticalId, "discovery");
  // Must NOT be a calendar or constellation task
  assertFalse(
    (task.payload as Record<string, string>).kind === "calendar-order",
  );
  assertFalse(
    (task.payload as Record<string, string>).kind === "constellation-anomaly",
  );
  // Must be a known discovery domain kind
  const validKinds = [
    "shape-sort",
    "colour-pattern",
    "number-sequence",
    "spatial-mirror",
    "memory-match",
  ];
  assertExists(
    validKinds.find((k) => k === (task.payload as Record<string, string>).kind),
  );
  // Answer key must not expose the answer in the payload
  assertFalse(
    JSON.stringify(task.payload).includes(JSON.stringify(task.answerKey)),
  );
});
