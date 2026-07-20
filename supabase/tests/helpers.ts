// Test helpers — shared setup for all Supabase integration tests.
// Run against a local Supabase stack:
//   supabase start
//   deno test supabase/tests/ --allow-net --allow-env

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('TEST_SUPABASE_URL') ?? 'http://127.0.0.1:54321';
const ANON_KEY = Deno.env.get('TEST_SUPABASE_ANON_KEY') ?? '';
const SERVICE_KEY = Deno.env.get('TEST_SUPABASE_SERVICE_KEY') ?? '';

// ---------------------------------------------------------------------------
// Client builders
// ---------------------------------------------------------------------------

export function anonClient(): SupabaseClient {
  return createClient(SUPABASE_URL, ANON_KEY);
}

export function serviceClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SERVICE_KEY);
}

// ---------------------------------------------------------------------------
// Guardian factory
// ---------------------------------------------------------------------------

export interface TestGuardian {
  id: string;
  email: string;
  client: SupabaseClient;
}

let counter = 0;

export async function createTestGuardian(): Promise<TestGuardian> {
  counter++;
  const email = `test-guardian-${counter}-${Date.now()}@mindbridge-test.invalid`;
  const password = 'TestPass123!';

  const svc = serviceClient();
  const { data, error } = await svc.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (error || !data.user) throw new Error(`createTestGuardian failed: ${error?.message}`);

  const userClient = createClient(SUPABASE_URL, ANON_KEY);
  await userClient.auth.signInWithPassword({ email, password });

  return { id: data.user.id, email, client: userClient };
}

// ---------------------------------------------------------------------------
// Seed helpers
// ---------------------------------------------------------------------------

export async function seedConsentVersion(svc: SupabaseClient): Promise<string> {
  const { data, error } = await svc
    .from('consent_versions')
    .insert({
      version: `v-test-${Date.now()}`,
      jurisdiction: 'IN',
      document_url: 'https://example.com/consent.pdf',
      active: true,
    })
    .select('id')
    .single();
  if (error) throw new Error(`seedConsentVersion: ${error.message}`);
  return data.id;
}

export async function seedVerifiedGuardian(svc: SupabaseClient, guardianId: string): Promise<void> {
  const { error } = await svc.from('parent_verifications').insert({
    guardian_id: guardianId,
    method: 'email_otp',
    status: 'verified',
    verified_at: new Date().toISOString(),
  });
  if (error) throw new Error(`seedVerifiedGuardian: ${error.message}`);
}

export async function seedActiveConsent(
  svc: SupabaseClient,
  guardianId: string,
  consentVersionId: string,
): Promise<void> {
  const { error } = await svc.from('guardian_consents').insert({
    guardian_id: guardianId,
    consent_version_id: consentVersionId,
    status: 'active',
    accepted_at: new Date().toISOString(),
  });
  if (error) throw new Error(`seedActiveConsent: ${error.message}`);
}

export async function seedChild(
  client: SupabaseClient,
  guardianId: string,
): Promise<string> {
  const svc = serviceClient();
  const { data, error } = await svc
    .from('children')
    .insert({ guardian_id: guardianId, preferred_name: 'TestChild', birth_year: 2018 })
    .select('id')
    .single();
  if (error) throw new Error(`seedChild: ${error.message}`);
  return data.id;
}

// ---------------------------------------------------------------------------
// Clean-up helper — call in afterEach/afterAll
// ---------------------------------------------------------------------------

export async function cleanupGuardian(guardianId: string): Promise<void> {
  const svc = serviceClient();
  const { data: children } = await svc.from('children').select('id').eq('guardian_id', guardianId);
  const ids = (children ?? []).map((c: { id: string }) => c.id);
  if (ids.length > 0) {
    await svc.from('discovery_intakes').delete().in('child_id', ids);
    await svc.from('sensory_configurations').delete().in('child_id', ids);
    await svc.from('child_experience').delete().in('child_id', ids);
    await svc.from('adult_exploratory_note').delete().in('child_id', ids);
    await svc.from('sessions').delete().in('child_id', ids);
    await svc.from('children').delete().eq('guardian_id', guardianId);
  }
  await svc.from('guardian_consents').delete().eq('guardian_id', guardianId);
  await svc.from('parent_verifications').delete().eq('guardian_id', guardianId);
  await svc.from('purge_requests').delete().eq('guardian_id', guardianId);
  await svc.from('audit_log').delete().eq('guardian_id', guardianId);
  await svc.auth.admin.deleteUser(guardianId);
}
