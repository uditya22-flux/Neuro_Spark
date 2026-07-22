import { assertEquals, assertExists } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { anonClient, createTestGuardian, cleanupGuardian } from './helpers.ts';

Deno.test('RLS — guardian A cannot read guardian B children', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();

  try {
    // Insert a child under guardian B using service role
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2');
    const svc = createClient(
      Deno.env.get('TEST_SUPABASE_URL')!,
      Deno.env.get('TEST_SUPABASE_SERVICE_KEY')!,
    );
    const { data: child } = await svc
      .from('children')
      .insert({ guardian_id: guardianB.id, preferred_name: 'ChildB', birth_year: 2018 })
      .select('id')
      .single();

    // Guardian A attempts to read — should get empty result (not 403)
    const { data, error } = await guardianA.client
      .from('children')
      .select('id')
      .eq('id', child!.id);

    assertEquals(error, null);
    assertEquals((data ?? []).length, 0, 'Guardian A must not see Guardian B children');

    await svc.from('children').delete().eq('id', child!.id);
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});

Deno.test('RLS — anonymous user cannot read children table', async () => {
  const anon = anonClient();
  const { data, error } = await anon.from('children').select('id').limit(1);
  // RLS should return 0 rows or an error — never actual data
  assertEquals((data ?? []).length, 0);
});

Deno.test('RLS — guardian A cannot read guardian B intake', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();

  try {
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2');
    const svc = createClient(
      Deno.env.get('TEST_SUPABASE_URL')!,
      Deno.env.get('TEST_SUPABASE_SERVICE_KEY')!,
    );
    const { data: child } = await svc
      .from('children')
      .insert({ guardian_id: guardianB.id, preferred_name: 'ChildB', birth_year: 2019 })
      .select('id')
      .single();
    await svc.from('discovery_intakes').insert({
      guardian_id: guardianB.id,
      child_id: child!.id,
      raw_text: 'sensitive',
      redacted_text: 'sensitive',
      expires_at: new Date(Date.now() + 86400000).toISOString(),
    });

    const { data } = await guardianA.client
      .from('discovery_intakes')
      .select('id')
      .eq('child_id', child!.id);

    assertEquals((data ?? []).length, 0, 'Guardian A must not see Guardian B intakes');

    await svc.from('children').delete().eq('id', child!.id);
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});

Deno.test('RLS — adult_exploratory_note not accessible via anon', async () => {
  const anon = anonClient();
  const { data } = await anon.from('adult_exploratory_note').select('id').limit(1);
  assertEquals((data ?? []).length, 0);
});

Deno.test('RLS — guardian A cannot read guardian B sessions', async () => {
  const guardianA = await createTestGuardian();
  const guardianB = await createTestGuardian();

  try {
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2');
    const svc = createClient(
      Deno.env.get('TEST_SUPABASE_URL')!,
      Deno.env.get('TEST_SUPABASE_SERVICE_KEY')!,
    );
    const { data: child } = await svc
      .from('children')
      .insert({ guardian_id: guardianB.id, preferred_name: 'ChildB', birth_year: 2020 })
      .select('id')
      .single();
    await svc.from('sessions').insert({
      child_id: child!.id,
      guardian_id: guardianB.id,
      expires_at: new Date(Date.now() + 3600000).toISOString(),
    });

    const { data } = await guardianA.client
      .from('sessions')
      .select('id')
      .eq('child_id', child!.id);

    assertEquals((data ?? []).length, 0, 'Guardian A must not see Guardian B sessions');
    await svc.from('children').delete().eq('id', child!.id);
  } finally {
    await cleanupGuardian(guardianA.id);
    await cleanupGuardian(guardianB.id);
  }
});
