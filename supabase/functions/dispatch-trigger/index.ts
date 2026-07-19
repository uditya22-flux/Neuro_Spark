import { accepted, json, readJson } from '../_shared/http.ts';
import { createServiceClient } from '../_shared/supabase.ts';

async function sendFcm(payload: Record<string, unknown>) {
  const accessToken = Deno.env.get('FCM_ACCESS_TOKEN');
  const projectId = Deno.env.get('FCM_PROJECT_ID');
  const token = payload.token as string | undefined;
  if (!accessToken || !projectId || !token) return false;
  await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: 'MindBridge', body: String(payload.body ?? 'You have a new update.') },
        data: payload,
      },
    }),
  });
  return true;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return json({}, { status: 200 });
  const client = createServiceClient();
  const body = await readJson<{ userId: string; payload: Record<string, unknown> }>(request);
  const { data: tokens } = await client.from('device_tokens').select('fcm_token').eq('user_id', body.userId).limit(1);
  if (tokens && tokens.length > 0) {
    await client.from('trigger_dispatch_queue').insert({ user_id: body.userId, payload: body.payload, channel: 'realtime', status: 'sent', sent_at: new Date().toISOString() });
    return accepted({ channel: 'realtime', delivered: true });
  }
  const delivered = await sendFcm({ ...body.payload, token: tokens?.[0]?.fcm_token });
  await client.from('trigger_dispatch_queue').insert({ user_id: body.userId, payload: body.payload, channel: 'fcm', status: delivered ? 'sent' : 'failed', sent_at: delivered ? new Date().toISOString() : null });
  return accepted({ channel: 'fcm', delivered });
});