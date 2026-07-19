import { accepted, json, readJson } from '../_shared/http.ts';
import { createUserClient, requireUser } from '../_shared/supabase.ts';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return json({}, { status: 200 });
  const client = createUserClient(request);
  const user = await requireUser(client);
  const body = await readJson<{ childId?: string }>(request).catch(() => ({}));
  const requestId = crypto.randomUUID();
  const redirectUrl = Deno.env.get('DIGILOCKER_SANDBOX_URL') ?? `https://example.invalid/digilocker/${requestId}`;
  await client.from('parent_verifications').upsert({ guardian_id: user.id, method: 'digilocker', status: 'pending', metadata: { requestId, childId: body.childId ?? null, redirectUrl } }, { onConflict: 'guardian_id,method' });
  return accepted({ requestId, redirectUrl });
});