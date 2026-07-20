import { corsHeaders, requireAuth, badRequest, ok, notFound, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import { ValidationError, requireUuid } from '../_shared/validate.ts';

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

  try {
    const sessionId = requireUuid(body.sessionId, 'sessionId');

    // Verify the session belongs to this guardian (RLS also enforces this)
    const { data: session, error: fetchErr } = await db
      .from('sessions')
      .select('id, child_id, revoked_at')
      .eq('id', sessionId)
      .eq('guardian_id', guardianId)
      .maybeSingle();

    if (fetchErr || !session) {
      return notFound('Session not found or does not belong to this guardian.');
    }

    if (session.revoked_at) {
      // Already revoked — idempotent success
      return ok({ ok: true, alreadyRevoked: true });
    }

    const { error: revokeErr } = await db
      .from('sessions')
      .update({ revoked_at: new Date().toISOString() })
      .eq('id', sessionId)
      .eq('guardian_id', guardianId);

    if (revokeErr) {
      console.error('[revoke-session] db error:', revokeErr.message);
      return internalError('Session could not be revoked. Please try again.');
    }

    await writeAudit({
      action: 'session_revoked',
      guardianId,
      childId: session.child_id,
      meta: { session_id: sessionId },
    });

    return ok({ ok: true });
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[revoke-session] unexpected:', (err as Error).message);
    return internalError();
  }
});
