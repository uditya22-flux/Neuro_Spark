import { corsHeaders, requireAuth, badRequest, internalError, ok } from '../_shared/auth.ts';
import { ValidationError, requireActiveConsent, requireOwnership, requireUuid } from '../_shared/validate.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db } = auth;
  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return badRequest('Request body must be valid JSON.'); }
  try {
    const childId = requireUuid(body.child_id ?? body.childId, 'child_id');
    const sessionId = requireUuid(body.session_id ?? body.sessionId, 'session_id');
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data, error } = await db.from('deepening_profiles').select('vertical_id, profile, telemetry_reference, created_at').eq('session_id', sessionId).eq('child_id', childId);
    if (error) return internalError('Deepening profile could not be read.');
    return ok({ session_id: sessionId, verticals: data ?? [] });
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[deepening-profile] unexpected:', (err as Error).message);
    return internalError();
  }
});
