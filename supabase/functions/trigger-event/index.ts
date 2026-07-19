import { accepted, json, readJson } from '../_shared/http.ts';
import { createServiceClient } from '../_shared/supabase.ts';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return json({}, { status: 200 });
  const client = createServiceClient();
  const body = await readJson<{ userId: string; candidateAction: Record<string, unknown> }>(request);
  const action = body.candidateAction ?? {};
  const rejectedReason = action.hardOptOut || action.quietHours || action.dailyCeiling || action.cooldown || action.sensoryOverload || action.guardianPaused ? 'guardrail_rejected' : null;
  const status = rejectedReason ? 'rejected' : 'approved';
  const { error } = await client.from('trigger_instances').insert({ user_id: body.userId, candidate_action: action, status, reason: rejectedReason });
  if (error) return json({ error: error.message }, { status: 500 });
  if (!rejectedReason) {
    await client.from('trigger_dispatch_queue').insert({ user_id: body.userId, payload: action, channel: 'realtime', status: 'pending' });
  }
  return accepted({ status, reason: rejectedReason });
});