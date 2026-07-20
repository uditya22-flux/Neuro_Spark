import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  createTestGuardian,
  anonClient,
  serviceClient,
  seedChild,
  cleanupGuardian,
} from './helpers.ts';

Deno.test('separation — adult_exploratory_note inaccessible to anonymous', async () => {
  const anon = anonClient();
  const { data } = await anon.from('adult_exploratory_note').select('id').limit(5);
  assertEquals((data ?? []).length, 0);
});

Deno.test('separation — guardian cannot read another guardian\'s notes', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();
  const svc = serviceClient();

  try {
    const childB = await seedChild(guardianB.client, guardianB.id);
    // Insert a note for Guardian B's child via service role
    await svc.from('adult_exploratory_note').insert({
      child_id: childB,
      taxonomy_key: 'chronologicalOrganization',
      observations: {},
      evidence: [],
      disclaimer: 'Illustrative only.',
    });

    // Guardian A tries to read it
    const { data } = await guardianA.client
      .from('adult_exploratory_note')
      .select('id')
      .eq('child_id', childB);

    assertEquals((data ?? []).length, 0, 'Guardian A must not read Guardian B notes');
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});

Deno.test('separation — child_experience row does not contain exploratory note fields', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const childId = await seedChild(guardian.client, guardian.id);

    // Insert an experience row and an adult note for the same child
    await svc.from('child_experience').insert({ child_id: childId, payload: { type: 'timeline', items: [] } });
    await svc.from('adult_exploratory_note').insert({
      child_id: childId,
      taxonomy_key: 'chronologicalOrganization',
      observations: { secret: true },
      evidence: [],
      disclaimer: 'Illustrative only.',
    });

    // Load child_experience and assert no adult note data leaks
    const { data } = await guardian.client
      .from('child_experience')
      .select('id, payload')
      .eq('child_id', childId)
      .single();

    const payloadStr = JSON.stringify(data?.payload ?? {});
    assertEquals(payloadStr.includes('taxonomy_key'), false);
    assertEquals(payloadStr.includes('observations'), false);
    assertEquals(payloadStr.includes('secret'), false);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});
