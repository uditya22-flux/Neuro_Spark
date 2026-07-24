// This source-contract test keeps the anonymous synthetic skip boundary small.
// The Edge entrypoint itself cannot be imported here because it registers
// Deno.serve as a module side effect.

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function sourceBlock(
  source: string,
  startMarker: string,
  endMarker: string,
): string {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert(start >= 0 && end > start, `Could not find ${startMarker}.`);
  return source.slice(start, end);
}

Deno.test("synthetic Engine 2 inactivity skip is allowlisted and finalizes false", async () => {
  const source = await Deno.readTextFile(
    new URL(
      "../functions/synthetic-engine2-next-task/index.ts",
      import.meta.url,
    ),
  );

  const parseSkip = sourceBlock(
    source,
    "if (action === 'skip')",
    "throw new ValidationError('action must be start, answer, or skip.')",
  );
  assert(
    parseSkip.includes(
      "['action', 'session_id', 'task_id', 'sector', 'layer', 'telemetry']",
    ),
    "Skip must accept only its opaque task context and telemetry.",
  );
  assert(
    !parseSkip.includes("option_id"),
    "Skip must not accept an answer option.",
  );
  assert(
    !parseSkip.includes("reason"),
    "Skip must not accept free-text reasons.",
  );

  const skipTask = sourceBlock(
    source,
    "async function skipTask(",
    "\nDeno.serve(",
  );
  assert(
    skipTask.includes("if (task.status !== 'issued')"),
    "Skip must require the currently issued task.",
  );
  assert(
    skipTask.includes("attemptCount: request.telemetry.interactions"),
    "Skip scoring must use the supplied bounded aggregate rather than inventing an answer.",
  );
  assert(
    skipTask.includes("{ correct: false, skipped: true }"),
    "Skip must finalise with a non-correct event outcome.",
  );
  const scoreFinal = sourceBlock(
    source,
    "function scoreFinalTelemetry(",
    "\nfunction clamp(",
  );
  assert(
    scoreFinal.includes(
      "const accuracy = correct ? clamp(1 / telemetry.attemptCount) : 0;",
    ),
    "A skipped final event must not claim answer accuracy.",
  );
  assert(
    scoreFinal.includes("const recovery = correct") &&
      scoreFinal.includes("    : 0;"),
    "A skipped final event must not claim answer recovery.",
  );
  assert(
    source.includes(
      "return progressResponse(session, correct, nextQueued, skipped);",
    ),
    "Final skip responses must use the same queued-task progression path.",
  );
  assert(
    source.includes(
      "const survivors = selectSyntheticSurvivors(ranked, session.current_layer);",
    ),
    "Final skip responses must retain the existing response-driven survivor funnel.",
  );
});
