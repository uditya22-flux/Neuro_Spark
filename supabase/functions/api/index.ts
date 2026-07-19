import { accepted, badRequest, empty, notFound, readJson, routeAfterFunction, unauthorized, json } from '../_shared/http.ts';
import { createUserClient, requireUser } from '../_shared/supabase.ts';
import { encryptText, sha256Hex } from '../_shared/crypto.ts';

const handler = async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') return empty(200);
  const route = routeAfterFunction(request, 'api');
  const client = createUserClient(request);

  const readUser = async () => await requireUser(client).catch(() => null);

  if (request.method === 'GET' && route[0] === 'consent-versions' && route[1] === 'current') {
    const { data, error } = await client.from('consent_versions').select('version,jurisdiction,document_url').eq('active', true).order('created_at', { ascending: false }).limit(1).maybeSingle();
    if (error) return json({ error: error.message }, { status: 500 });
    if (!data) return json({ error: 'Consent is not configured' }, { status: 503 });
    return json(data);
  }

  if (request.method === 'POST' && route[0] === 'consents' && route[1] === 'verify-parent') {
    const user = await readUser();
    if (!user) return unauthorized();
    const body = await readJson<{ method: 'email_otp' | 'phone_otp' | 'digilocker'; consentVersion: string; verificationReference?: string; displayName?: string; metadata?: Record<string, unknown> }>(request);
    const { data: version } = await client.from('consent_versions').select('id').eq('version', body.consentVersion).eq('active', true).maybeSingle();
    if (!version) return json({ error: 'That consent version is not active' }, { status: 400 });
    const { error } = await client.from('parent_verifications').upsert({ guardian_id: user.id, method: body.method, status: 'verified', verified_at: new Date().toISOString(), metadata: { consentVersion: body.consentVersion, verificationReference: body.verificationReference ?? null, displayName: body.displayName ?? null, ...body.metadata } }, { onConflict: 'guardian_id,method' });
    if (error) return json({ error: error.message }, { status: 500 });
    return json({ guardianId: user.id, consentVersion: body.consentVersion, verifiedAt: new Date().toISOString() }, { status: 201 });
  }

  if (request.method === 'POST' && route[0] === 'children' && route.length === 1) {
    const user = await readUser();
    if (!user) return unauthorized();
    const body = await readJson<{ preferredName: string; birthYear: number }>(request);
    const { data: verification } = await client.from('parent_verifications').select('id').eq('guardian_id', user.id).eq('status', 'verified').limit(1).maybeSingle();
    if (!verification) return json({ error: 'Verified parent consent is required before a child profile can be created' }, { status: 403 });
    const { data, error } = await client.from('children').insert({ guardian_id: user.id, preferred_name: body.preferredName, birth_year: body.birthYear }).select('id,preferred_name,birth_year').single();
    if (error) return json({ error: error.message }, { status: 500 });
    return json(data, { status: 201 });
  }

  if (request.method === 'POST' && route[0] === 'children' && route[2] === 'sessions') {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const { data: child } = await client.from('children').select('id').eq('id', childId).eq('guardian_id', user.id).maybeSingle();
    if (!child) return json({ error: 'Child profile was not found' }, { status: 404 });
    const token = crypto.randomUUID();
    const tokenHash = await sha256Hex(token);
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    const { error } = await client.from('child_sessions').insert({ child_id: childId, token_hash: tokenHash, expires_at: expiresAt });
    if (error) return json({ error: error.message }, { status: 500 });
    return json({ childId, token, expiresAt }, { status: 201 });
  }

  if (request.method === 'DELETE' && route[0] === 'children' && route[2] === 'sessions' && route.length === 4) {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const sessionId = route[3];
    const { data: child } = await client.from('children').select('id').eq('id', childId).eq('guardian_id', user.id).maybeSingle();
    if (!child) return json({ error: 'Child profile was not found' }, { status: 404 });
    const { error } = await client.from('child_sessions').update({ revoked_at: new Date().toISOString(), revoke_reason: 'guardian_revoked' }).eq('id', sessionId).eq('child_id', childId);
    if (error) return json({ error: error.message }, { status: 500 });
    return empty(204);
  }

  if (request.method === 'POST' && route[0] === 'children' && route[2] === 'discovery' && route[3] === 'intake') {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const body = await readJson<{ text: string }>(request);
    const redactedText = body.text.replace(/\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b/g, '[redacted-email]').replace(/\b(?:\+?\d[\d\s-]{7,}\d)\b/g, '[redacted-phone]');
    const encryptedRawText = await encryptText(body.text);
    const { error } = await client.from('discovery_intakes').insert({ guardian_id: user.id, child_id: childId, encrypted_raw_text: encryptedRawText, redacted_text: redactedText, expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() });
    if (error) return json({ error: error.message }, { status: 500 });
    return accepted({ status: 'queued', childId });
  }

  if (request.method === 'PATCH' && route[0] === 'children' && route[2] === 'discovery' && route[3] === 'configurations' && route.length === 5) {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const configVersion = Number(route[4]);
    const body = await readJson<{ items: Array<{ key: string; status: 'CONFIRMED' | 'REJECTED' }> }>(request);
    const updates = body.items.map((item) => client.from('sensory_configurations').update({ status: item.status, reviewed_at: new Date().toISOString() }).eq('child_id', childId).eq('config_version', configVersion).eq('key', item.key));
    const results = await Promise.all(updates);
    if (results.some((result) => result.error)) return json({ error: results.find((result) => result.error)?.error?.message ?? 'Configuration update failed' }, { status: 500 });
    return json({ childId, configVersion, items: body.items });
  }

  if (request.method === 'POST' && route[0] === 'children' && route[2] === 'discovery' && route[3] === 'configurations' && route[5] === 'activate') {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const configVersion = Number(route[4]);
    const { data: items } = await client.from('sensory_configurations').select('key,proposed_value,status').eq('child_id', childId).eq('config_version', configVersion);
    if (!items || items.length === 0 || items.some((item) => item.status !== 'CONFIRMED')) return json({ error: 'Every configuration item must be confirmed before activation' }, { status: 409 });
    const { error } = await client.from('sensory_configurations').update({ status: 'CONFIRMED' }).eq('child_id', childId).eq('config_version', configVersion);
    if (error) return json({ error: error.message }, { status: 500 });
    return json({ childId, configVersion, activated: true, guardianId: user.id }, { status: 201 });
  }

  if (request.method === 'POST' && route[0] === 'children' && route[2] === 'synthesis') {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const body = await readJson<{ track: string }>(request);
    const { data: evidence } = await client.from('layer_progression_state').select('state').eq('child_id', childId).limit(1).maybeSingle();
    const note = {
      taxonomyKey: body.track,
      taxonomyVersion: 'supabase-1',
      observations: [{ label: 'summary', value: 'Supabase edge synthesis placeholder generated server-side.' }],
      evidence: evidence?.state ?? {},
      disclaimer: 'Adult exploratory note generated in Supabase.',
      createdAt: new Date().toISOString(),
    };
    const { error } = await client.from('adult_exploratory_notes').insert({ child_id: childId, track: body.track, observations: note.observations, evidence: note.evidence, disclaimer: note.disclaimer });
    if (error) return json({ error: error.message }, { status: 500 });
    return json({ note, guardianId: user.id }, { status: 201 });
  }

  if (request.method === 'GET' && route[0] === 'children' && route[2] === 'adult-notes' && route[3] === 'latest') {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = route[1];
    const { data, error } = await client.from('adult_exploratory_notes').select('track,observations,evidence,disclaimer,created_at').eq('child_id', childId).order('created_at', { ascending: false }).limit(1).maybeSingle();
    if (error) return json({ error: error.message }, { status: 500 });
    if (!data) return json({ error: 'No field note is available yet' }, { status: 404 });
    return json({ ...data, guardianId: user.id });
  }

  if (request.method === 'POST' && route[0] === 'privacy' && route[1] === 'purge') {
    const user = await readUser();
    if (!user) return unauthorized();
    const body = await readJson<{ childId?: string; confirm: boolean }>(request);
    if (!body.confirm) return badRequest('confirm must be true');
    const { error } = await client.from('purge_requests').insert({ guardian_id: user.id, child_id: body.childId ?? null, status: 'REQUESTED' });
    if (error) return json({ error: error.message }, { status: 500 });
    return accepted({ status: 'REQUESTED' });
  }

  if (request.method === 'GET' && route[0] === 'privacy' && route[1] === 'export') {
    const user = await readUser();
    if (!user) return unauthorized();
    const childId = new URL(request.url).searchParams.get('childId');
    const query = client.from('children').select('id,preferred_name,birth_year,created_at,adult_exploratory_notes(*),child_sessions(*),discovery_intakes(*),layer_progression_state(*),layer_task_execution(*)').eq('guardian_id', user.id);
    if (childId) query.eq('id', childId);
    const { data, error } = await query;
    if (error) return json({ error: error.message }, { status: 500 });
    return json({ generatedAt: new Date().toISOString(), children: data });
  }

  if (request.method === 'GET' && route[0] === 'v1' && route[1] === 'discovery' && route[2] === 'layer1-tasks') {
    const { data, error } = await client.from('vertical_task_bank').select('id,track,bank_key,item').eq('active', true).order('created_at', { ascending: true });
    if (error) return json({ error: error.message }, { status: 500 });
    return json({ userId: route[3], tasks: data });
  }

  if (request.method === 'GET' && route[0] === 'v4' && route[1] === 'sandbox' && route[3] === 'session') {
    const userId = route[2];
    const { data, error } = await client.from('sandbox_session').insert({ user_id: userId, seed: crypto.randomUUID() }).select('id,seed,started_at').single();
    if (error) return json({ error: error.message }, { status: 500 });
    return json(data, { status: 201 });
  }

  if (request.method === 'POST' && route[0] === 'v4' && route[1] === 'sandbox' && route[3] === 'attempt') {
    const user = await readUser();
    if (!user) return unauthorized();
    const body = await readJson<{ payload: Record<string, unknown> }>(request);
    const { error } = await client.from('sandbox_attempt').insert({ session_id: route[2], user_id: user.id, payload: body.payload });
    if (error) return json({ error: error.message }, { status: 500 });
    return accepted({ sessionId: route[2], status: 'recorded' });
  }

  if (request.method === 'GET' && route[0] === 'v4' && route[1] === 'sandbox' && route[3] === 'streak') {
    const { data, error } = await client.from('difficulty_state').select('streak,difficulty,updated_at').eq('user_id', route[2]).maybeSingle();
    if (error) return json({ error: error.message }, { status: 500 });
    return json(data ?? { streak: 0, difficulty: {}, updated_at: null });
  }

  return notFound();
};

Deno.serve(handler);