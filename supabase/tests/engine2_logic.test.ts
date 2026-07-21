import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  evaluateAnswer,
  parseSelectedStarIds,
  pathForIsolation,
  pathLayers,
  publicTask,
  scoreResponse,
  supportTransition,
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

  const scored = scoreResponse(1, Number.NaN, 0, 0, false, "curated");
  assertEquals(scored.accuracy, 1);
  assertEquals(scored.latencyMs, 0);
  assertFalse(Number.isNaN(scored.isolationScore));
});
