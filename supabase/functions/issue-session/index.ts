import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import {
  ValidationError,
  requireUuid,
  requireOwnership,
  requireActiveConsent,
  requireVerifiedGuardian,
} from '../_shared/validate.ts';

// Session duration in hours — override with SESSION_DURATION_HOURS env var
const SESSION_HOURS = parseInt(Deno.env.get('SESSION_DURATION_HOURS') ?? '8', 10);

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
    const childId = requireUuid(body.childId, 'childId');

    // Prerequisite checks in order
    await requireVerifiedGuardian(db, guardianId);
    await requireActiveConsent(db, guardianId);
    await requireOwnership(db, guardianId, childId);

    const expiresAt = new Date(Date.now() + SESSION_HOURS * 3_600_000).toISOString();

    const { data, error } = await db
      .from('sessions')
      .insert({ child_id: childId, guardian_id: guardianId, expires_at: expiresAt })
      .select('id, expires_at, created_at')
      .single();

    if (error) {
      console.error('[issue-session] db error:', error.message);
      return internalError('Session could not be created. Please try again.');
    }

    await writeAudit({
      action: 'session_issued',
      guardianId,
      childId,
      meta: { session_id: data.id, expires_at: expiresAt },
    });

    // Return only what Flutter needs — no child PII
    return ok({ sessionId: data.id, expiresAt: data.expires_at }, 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[issue-session] unexpected:', (err as Error).message);
    return internalError();
  }
});
