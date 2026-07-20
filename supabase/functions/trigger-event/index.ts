import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import { ValidationError } from '../_shared/validate.ts';

// ---------------------------------------------------------------------------
// CHARTER NOTICE
// Per AGENTS.md: re-engagement, streak, badge, and child-notification
// functionality requires an approved charter change before enablement.
// This function records the candidate action only. It does NOT dispatch
// notifications or modify any downstream trigger queue.
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db } = auth;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return badRequest('Request body must be valid JSON.');
  }

  // Reject non-object payloads (no arrays, primitives, or function injection)
  if (typeof body !== 'object' || Array.isArray(body)) {
    return badRequest('candidate_action must be a plain object.');
  }

  try {
    const { data, error } = await db
      .from('trigger_instances')
      .insert({ user_id: guardianId, candidate_action: body })
      .select('id, created_at')
      .single();

    if (error) {
      console.error('[trigger-event] db error:', error.message);
      return internalError('Trigger instance could not be recorded.');
    }

    await writeAudit({
      action: 'trigger_event_recorded',
      guardianId,
      meta: {
        instance_id: data.id,
        charter_note: 'downstream dispatch is charter-pending',
      },
    });

    // Downstream dispatch is intentionally NOT invoked here.
    // See dispatch-trigger/index.ts for the charter-gated stub.
    return ok({ id: data.id, createdAt: data.created_at }, 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[trigger-event] unexpected:', (err as Error).message);
    return internalError();
  }
});
