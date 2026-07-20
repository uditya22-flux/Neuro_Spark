import { assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts';
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

async function callExport(
  token: string,
  body: Record<string, unknown> = {},
): Promise<{ status: number; data: Record<string, unknown> }> {
  const res = await fetch(`${BASE}/functions/v1/privacy-export`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: res.status, data: await res.json() };
}

Deno.test('privacy-export — returns authorized records only', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);
    const childId = await seedChild(guardian.client, guardian.id);

    const s = await guardian.client.auth.getSession();
    const token = s.data.session?.access_token ?? '';

    const { status, data } = await callExport(token);
    assertEquals(status, 200);

    // Must contain expected keys
    assertExists(data.guardian);
    assertExists(data.children);
    assertExists(data.consents);

    // Must NOT contain raw_text or adult notes
    assertEquals((data as Record<string, unknown>).adult_exploratory_note, undefined);
    const dataStr = JSON.stringify(data);
    assertEquals(dataStr.includes('raw_text'), false);
    assertEquals(dataStr.includes('fcm_token'), false);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('privacy-export — scoped to child excludes other children', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);
    const child1 = await seedChild(guardian.client, guardian.id);
    const child2 = await seedChild(guardian.client, guardian.id);

    const s = await guardian.client.auth.getSession();
    const token = s.data.session?.access_token ?? '';

    const { status, data } = await callExport(token, { childId: child1 });
    assertEquals(status, 200);
    const childIds = ((data.children ?? []) as Array<{ id: string }>).map((c) => c.id);
    assertEquals(childIds.includes(child2), false, 'Export scoped to child1 must not include child2');
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('privacy-export — blocked without JWT', async () => {
  const { status } = await callExport('', {});
  assertEquals(status, 401);
});
