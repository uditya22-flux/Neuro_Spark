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

const BASE = Deno.env.get('TEST_SUPABASE_URL') ?? 'http://127.0.0.1:64321';

async function call(
  fn: string,
  token: string,
  body: Record<string, unknown>,
): Promise<{ status: number; data: Record<string, unknown> }> {
  const res = await fetch(`${BASE}/functions/v1/${fn}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: res.status, data: await res.json() };
}

Deno.test('session — issue and revoke lifecycle', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);
    const childId = await seedChild(guardian.client, guardian.id);

    const session = await guardian.client.auth.getSession();
    const token = session.data.session?.access_token ?? '';

    // Issue
    const issued = await call('issue-session', token, { childId });
    assertEquals(issued.status, 201);
    assertExists(issued.data.sessionId);
    assertExists(issued.data.expiresAt);

    const sessionId = issued.data.sessionId as string;

    // Revoke
    const revoked = await call('revoke-session', token, { sessionId });
    assertEquals(revoked.status, 200);
    assertEquals((revoked.data as Record<string, unknown>).ok, true);

    // Revoke again — idempotent
    const revoked2 = await call('revoke-session', token, { sessionId });
    assertEquals(revoked2.status, 200);
    assertEquals((revoked2.data as Record<string, unknown>).alreadyRevoked, true);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('session — cross-guardian revoke blocked', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardianA.id);
    await seedActiveConsent(svc, guardianA.id, cvId);
    const childId = await seedChild(guardianA.client, guardianA.id);

    const sessionA = await guardianA.client.auth.getSession();
    const tokenA = sessionA.data.session?.access_token ?? '';

    // Guardian A issues a session
    const issued = await call('issue-session', tokenA, { childId });
    const sessionId = issued.data.sessionId as string;

    // Guardian B attempts to revoke it
    const sessionB = await guardianB.client.auth.getSession();
    const tokenB = sessionB.data.session?.access_token ?? '';
    const revoked = await call('revoke-session', tokenB, { sessionId });
    assertEquals(revoked.status, 404, 'Cross-guardian revoke must return 404');
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});

Deno.test('session — issue blocked without consent', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    await seedVerifiedGuardian(svc, guardian.id);
    const childId = await seedChild(guardian.client, guardian.id);

    const s = await guardian.client.auth.getSession();
    const token = s.data.session?.access_token ?? '';
    const { status } = await call('issue-session', token, { childId });
    assertEquals(status, 400);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});
