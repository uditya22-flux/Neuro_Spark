import { assertEquals, assertExists, assertStringIncludes } from 'https://deno.land/std@0.224.0/assert/mod.ts';
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

async function submitIntake(
  token: string,
  body: Record<string, unknown>,
): Promise<{ status: number; data: Record<string, unknown> }> {
  const res = await fetch(`${BASE}/functions/v1/submit-intake`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: res.status, data: await res.json() };
}

Deno.test('intake — submission with PII redaction', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);
    const childId = await seedChild(guardian.client, guardian.id);

    const session = await guardian.client.auth.getSession();
    const token = session.data.session?.access_token ?? '';

    const { status, data } = await submitIntake(token, {
      childId,
      text: 'My child Riya, phone 9876543210 and email riya@example.com loves puzzles.',
    });

    assertEquals(status, 201);
    assertExists(data.id);
    // Raw text must NOT be in response
    assertEquals((data as Record<string, unknown>).rawText, undefined);

    // Verify stored redacted text via service client
    const { data: stored } = await svc
      .from('discovery_intakes')
      .select('raw_text, redacted_text')
      .eq('id', data.id as string)
      .single();

    assertStringIncludes(stored!.redacted_text, '[redacted-phone]');
    assertStringIncludes(stored!.redacted_text, '[redacted-email]');
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('intake — rejected for wrong child', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedActiveConsent(svc, guardianA.id, cvId);
    // Create a child under guardian B
    const childId = await seedChild(guardianB.client, guardianB.id);

    const sA = await guardianA.client.auth.getSession();
    const tokenA = sA.data.session?.access_token ?? '';

    const { status } = await submitIntake(tokenA, { childId, text: 'Some text' });
    assertEquals(status, 400, 'Guardian A must not submit intake for Guardian B child');
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});

Deno.test('intake — rejected when text exceeds 4000 chars', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);
    const childId = await seedChild(guardian.client, guardian.id);

    const s = await guardian.client.auth.getSession();
    const token = s.data.session?.access_token ?? '';
    const { status } = await submitIntake(token, { childId, text: 'x'.repeat(4001) });
    assertEquals(status, 400);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});
