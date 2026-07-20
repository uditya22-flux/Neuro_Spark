import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  createTestGuardian,
  serviceClient,
  seedConsentVersion,
  seedVerifiedGuardian,
  seedActiveConsent,
  seedChild,
  cleanupGuardian,
} from './helpers.ts';

const BASE = Deno.env.get('TEST_SUPABASE_URL') ?? 'http://127.0.0.1:54321';

async function callPurge(
  token: string,
  body: Record<string, unknown> = {},
): Promise<{ status: number; data: Record<string, unknown> }> {
  const res = await fetch(`${BASE}/functions/v1/privacy-purge`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: res.status, data: await res.json() };
}

Deno.test('privacy-purge — cascades and completes', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);
    const childId = await seedChild(guardian.client, guardian.id);

    // Add an intake row so cascade is exercised
    await svc.from('discovery_intakes').insert({
      guardian_id: guardian.id,
      child_id: childId,
      raw_text: 'test',
      redacted_text: 'test',
      expires_at: new Date(Date.now() + 86400000).toISOString(),
    });

    const s = await guardian.client.auth.getSession();
    const token = s.data.session?.access_token ?? '';

    const { status, data } = await callPurge(token, { childId });
    assertEquals(status, 202);
    assertEquals((data as Record<string, unknown>).status, 'completed');

    // Verify child is gone
    const { data: children } = await svc.from('children').select('id').eq('id', childId);
    assertEquals((children ?? []).length, 0, 'Child must be deleted after purge');

    // Verify intakes are gone
    const { data: intakes } = await svc.from('discovery_intakes').select('id').eq('child_id', childId);
    assertEquals((intakes ?? []).length, 0, 'Intakes must be deleted after purge');
  } finally {
    // Guardian may already be partially deleted — ignore errors
    try { await cleanupGuardian(guardian.id); } catch { /* ok */ }
  }
});

Deno.test('privacy-purge — idempotent (second call returns existing request)', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedActiveConsent(svc, guardian.id, cvId);

    const s = await guardian.client.auth.getSession();
    const token = s.data.session?.access_token ?? '';

    // First call
    const first = await callPurge(token, {});
    // Insert a fake in-progress request to test idempotency
    await svc.from('purge_requests').update({ status: 'in_progress' }).eq('id', first.data.id);

    // Second call should return the existing one
    const second = await callPurge(token, {});
    assertEquals(second.status, 202);
    assertEquals(second.data.id, first.data.id, 'Should return existing purge request ID');
  } finally {
    try { await cleanupGuardian(guardian.id); } catch { /* ok */ }
  }
});

Deno.test('privacy-purge — blocked without JWT', async () => {
  const { status } = await callPurge('');
  assertEquals(status, 401);
});
