import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// This function is the only Firebase integration. It receives a queue row,
// reads the token from Supabase, sends once, and records the result in Supabase.
Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });
  const body = await req.json();
  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: trigger, error: readError } = await db.from('pending_triggers').select('id,guardian_id,title,body,channel').eq('id', body.id).eq('status', 'queued').single();
  if (readError || !trigger) return Response.json({ error: 'trigger_not_found' }, { status: 404 });
  const { data: profile } = await db.from('profiles').select('fcm_token').eq('id', trigger.guardian_id).single();
  if (!profile?.fcm_token) return Response.json({ error: 'device_token_missing' }, { status: 409 });
  await db.from('pending_triggers').update({ status: 'sending', attempts: 1 }).eq('id', trigger.id);
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${Deno.env.get('FCM_PROJECT_ID')}/messages:send`, { method: 'POST', headers: { Authorization: `Bearer ${Deno.env.get('FCM_ACCESS_TOKEN')}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ message: { token: profile.fcm_token, notification: { title: trigger.title, body: trigger.body }, data: { channel: trigger.channel } } }) });
  if (!response.ok) { const error = (await response.text()).slice(0, 500); await db.from('pending_triggers').update({ status: 'failed', last_error: error }).eq('id', trigger.id); return Response.json({ error: 'fcm_send_failed' }, { status: 502 }); }
  await db.from('pending_triggers').update({ status: 'sent', dispatched_at: new Date().toISOString() }).eq('id', trigger.id);
  return Response.json({ ok: true });
});
