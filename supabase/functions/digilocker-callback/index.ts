import { accepted, json, readJson } from '../_shared/http.ts';
import { createServiceClient } from '../_shared/supabase.ts';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return json({}, { status: 200 });
  const client = createServiceClient();
  const body = await readJson<{ guardianId: string; requestId: string; nameMatch?: boolean; metadata?: Record<string, unknown> }>(request);
  await client.from('parent_verifications').upsert({ guardian_id: body.guardianId, method: 'digilocker', status: 'verified', verified_at: new Date().toISOString(), metadata: { requestId: body.requestId, nameMatch: body.nameMatch ?? true, ...body.metadata } }, { onConflict: 'guardian_id,method' });
  return accepted({ verified: true });
});