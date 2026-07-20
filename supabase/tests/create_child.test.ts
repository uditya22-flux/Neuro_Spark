import { assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  createTestGuardian,
  serviceClient,
  seedConsentVersion,
  seedVerifiedGuardian,
  seedActiveConsent,
  cleanupGuardian,
} from './helpers.ts';

const BASE = Deno.env.get('TEST_SUPABASE_URL') ?? 'http://127.0.0.1:54321';

async function callCreateChild(
  token: string,
  body: Record<string, unknown>,
): Promise<{ status: number; data: unknown }> {
  const res = await fetch(`${BASE}/functions/v1/create-child`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  return { status: res.status, data: await res.json() };
}

Deno.test('create-child — success with full prerequisites', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);

    const session = await guardian.client.auth.getSession();
    const token = session.data.session?.access_token ?? '';

    const { status, data } = await callCreateChild(token, {
      preferredName: 'Arjun',
      birthYear: 2017,
    });
    assertEquals(status, 201);
    assertExists((data as Record<string, unknown>).id);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('create-child — blocked without verified guardian', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedActiveConsent(svc, guardian.id, cvId);
    // No seedVerifiedGuardian

    const session = await guardian.client.auth.getSession();
    const token = session.data.session?.access_token ?? '';

    const { status } = await callCreateChild(token, {
      preferredName: 'Arjun',
      birthYear: 2017,
    });
    assertEquals(status, 400, 'Should reject when guardian is not verified');
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('create-child — blocked without active consent', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    await seedVerifiedGuardian(svc, guardian.id);
    // No seedActiveConsent

    const session = await guardian.client.auth.getSession();
    const token = session.data.session?.access_token ?? '';

    const { status } = await callCreateChild(token, {
      preferredName: 'Arjun',
      birthYear: 2017,
    });
    assertEquals(status, 400, 'Should reject when consent is missing');
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('create-child — blocked without JWT', async () => {
  const { status } = await callCreateChild('', { preferredName: 'X', birthYear: 2018 });
  assertEquals(status, 401);
});

Deno.test('create-child — rejects invalid birth year', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await seedVerifiedGuardian(svc, guardian.id);
    await seedActiveConsent(svc, guardian.id, cvId);

    const session = await guardian.client.auth.getSession();
    const token = session.data.session?.access_token ?? '';

    const { status } = await callCreateChild(token, { preferredName: 'X', birthYear: 1800 });
    assertEquals(status, 400);
  } finally {
    await cleanupGuardian(guardian.id);
  }
});
