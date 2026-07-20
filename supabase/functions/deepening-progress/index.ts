import { corsHeaders, requireAuth, badRequest, internalError, ok } from '../_shared/auth.ts';
import { ValidationError, requireActiveConsent, requireOwnership, requireUuid } from '../_shared/validate.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db, serviceClient: svc } = auth;
  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return badRequest('Request body must be valid JSON.'); }
  try {
    const childId = requireUuid(body.child_id ?? body.childId, 'child_id');
    const sessionId = requireUuid(body.session_id ?? body.sessionId, 'session_id');
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data, error } = await svc.from('layer_progression_state').select('vertical_id, current_layer, path_type, path_layers, completed_layers, status, support_level, updated_at').eq('session_id', sessionId).eq('child_id', childId).order('vertical_id');
    if (error) return internalError('Deepening progress could not be read.');
    return ok({ session_id: sessionId, verticals: data ?? [] });
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[deepening-progress] unexpected:', (err as Error).message);
    return internalError();
  }
});
