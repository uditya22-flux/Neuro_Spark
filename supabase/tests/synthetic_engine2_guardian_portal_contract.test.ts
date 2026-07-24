// Source-contract coverage for the anonymous synthetic guardian snapshot.
// The entrypoint registers Deno.serve, so these tests inspect its boundary
// instead of importing it directly.

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test('synthetic guardian portal accepts only an opaque snapshot request', async () => {
  const source = await Deno.readTextFile(
    new URL(
      '../functions/synthetic-engine2-guardian-portal/index.ts',
      import.meta.url,
    ),
  );

  assert(
    source.includes("keys.length !== 2 || keys[0] !== 'action' || keys[1] !== 'session_id'"),
    'The snapshot request must reject additional fields such as intake text.',
  );
  assert(
    source.includes("if (body.action !== 'snapshot')"),
    'The snapshot action must be fixed.',
  );
  assert(
    source.includes('uuidPattern.test(body.session_id)'),
    'The share code must be an opaque UUID.',
  );
  assert(
    source.includes("is_anonymous !== true"),
    'Only anonymous synthetic identities may call the endpoint.',
  );
});

Deno.test('synthetic guardian portal returns aggregates, never task content or intake', async () => {
  const source = await Deno.readTextFile(
    new URL(
      '../functions/synthetic-engine2-guardian-portal/index.ts',
      import.meta.url,
    ),
  );

  assert(source.includes(".from('synthetic_engine2_demo_events')"), 'Events must source the snapshot.');
  assert(source.includes(".from('synthetic_engine2_demo_attempts')"), 'Attempts must support skip inference.');
  assert(source.includes('skipped: !attemptedTaskIds.has(event.task_id)'), 'Skip must be inferred from no attempts.');
  assert(!source.includes('task_payload'), 'Task payloads must never reach the portal.');
  assert(!source.includes('visual_preferences'), 'Visual preference data must never reach the portal.');
  assert(!source.includes('option_id,'), 'Selection option IDs must never reach the portal.');
});
