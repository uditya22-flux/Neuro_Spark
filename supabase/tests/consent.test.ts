import { assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  createTestGuardian,
  serviceClient,
  seedConsentVersion,
  seedVerifiedGuardian,
  cleanupGuardian,
} from './helpers.ts';

Deno.test('Consent — accept active consent version', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);

    // Guardian accepts consent via direct table insert (as the Flutter app would)
    const { error } = await guardian.client.from('guardian_consents').insert({
      guardian_id: guardian.id,
      consent_version_id: cvId,
      status: 'active',
      accepted_at: new Date().toISOString(),
    });
    assertEquals(error, null);

    // Verify it's readable
    const { data } = await guardian.client
      .from('guardian_consents')
      .select('status')
      .eq('guardian_id', guardian.id)
      .single();
    assertEquals(data?.status, 'active');
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('Consent — revoke consent', async () => {
  const guardian = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    await svc.from('guardian_consents').insert({
      guardian_id: guardian.id,
      consent_version_id: cvId,
      status: 'active',
      accepted_at: new Date().toISOString(),
    });

    // Revoke
    await guardian.client
      .from('guardian_consents')
      .update({ status: 'revoked', revoked_at: new Date().toISOString() })
      .eq('guardian_id', guardian.id)
      .eq('consent_version_id', cvId);

    const { data } = await guardian.client
      .from('guardian_consents')
      .select('status')
      .eq('guardian_id', guardian.id)
      .single();
    assertEquals(data?.status, 'revoked');
  } finally {
    await cleanupGuardian(guardian.id);
  }
});

Deno.test('Consent — cannot insert for another guardian', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();
  const svc = serviceClient();

  try {
    const cvId = await seedConsentVersion(svc);
    // Guardian A tries to write consent record for Guardian B's ID — RLS should block
    const { error } = await guardianA.client.from('guardian_consents').insert({
      guardian_id: guardianB.id,
      consent_version_id: cvId,
      status: 'active',
    });
    assertExists(error, 'RLS should have rejected cross-guardian consent insert');
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});
