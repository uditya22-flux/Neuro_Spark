import { corsHeaders, locked } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';

// ---------------------------------------------------------------------------
// CHARTER GATE — dispatch-trigger
//
// This function receives database webhook payloads from Supabase.
// Per AGENTS.md, notification dispatch requires an approved charter change.
// Until that approval is in place, all payloads are logged and rejected
// with 423 Locked. No FCM call is made. No child notification is sent.
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  // Parse body best-effort for audit purposes only
  let payload: Record<string, unknown> = {};
  try {
    payload = await req.json();
  } catch {
    // ignore parse errors — we still want to audit and reject
  }

  await writeAudit({
    action: 'dispatch_trigger_blocked',
    meta: {
      reason: 'charter_pending',
      trigger_id: typeof payload.id === 'string' ? payload.id : null,
    },
  });

  return locked('notification_dispatch_not_enabled: charter approval required before notifications can be sent.');
});
