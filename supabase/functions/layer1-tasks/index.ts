import { corsHeaders, requireAuth, badRequest, conflict, internalError, ok } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import {
  ValidationError, requireActiveConsent, requireOwnership, requireUuid,
} from '../_shared/validate.ts';
import {
  VERTICALS, createTask, contentHash, loadEngine1Config, publicTask, type VerticalId,
} from '../_shared/engine2.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db, serviceClient: svc } = auth;

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return badRequest('Request body must be valid JSON.'); }

  try {
    const childId = requireUuid(body.child_id ?? body.childId, 'child_id');
    const requestedSession = body.session_id ?? body.sessionId;
    const sessionId = requestedSession ? requireUuid(requestedSession, 'session_id') : null;
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const config = await loadEngine1Config(db, guardianId, childId);

    let session: Record<string, unknown> | null = null;
    if (sessionId) {
      const { data } = await svc.from('layer1_sessions').select('id, child_id, guardian_id, status').eq('id', sessionId).eq('child_id', childId).eq('guardian_id', guardianId).maybeSingle();
      if (!data) return conflict('The requested orchestration session is not available.');
      session = data;
    } else {
      const { data, error } = await svc.from('layer1_sessions').insert({ child_id: childId, guardian_id: guardianId }).select('id, child_id, guardian_id, status').single();
      if (error || !data) {
        console.error('[layer1-tasks] session insert:', error?.message);
        return internalError('Layer 1 session could not be created.');
      }
      session = data;
    }

    const existing = await svc.from('vertical_task_bank')
      .select('id, vertical_id, layer_number, source_type, difficulty_tier, item_payload')
      .eq('session_id', session.id).eq('layer_number', 1).eq('active', true);
    if (existing.error) return internalError('Layer 1 tasks could not be read.');

    const taskRows: Record<string, unknown>[] = [];
    for (const vertical of config.activeVerticals) {
      const found = (existing.data ?? []).find((row: Record<string, unknown>) => row.vertical_id === vertical);
      if (found) {
        taskRows.push(found);
        continue;
      }
      const task = await createTask(vertical, 1, `${session.id}:${vertical}`, config);
      const hash = await contentHash({ vertical, layer: 1, payload: task.payload, answer: task.answerKey });
      const { data, error } = await svc.from('vertical_task_bank').insert({
        child_id: childId, session_id: session.id, vertical_id: vertical, layer_number: 1,
        source_type: task.sourceType, difficulty_tier: task.difficultyTier,
        item_payload: { public_payload: task.payload, answer_key: task.answerKey },
        content_hash: hash, rule_version: task.ruleVersion,
      }).select('id, vertical_id, layer_number, source_type, difficulty_tier, item_payload').single();
      if (error || !data) {
        console.error('[layer1-tasks] task insert:', error?.message);
        return internalError('Layer 1 task could not be assembled.');
      }
      taskRows.push(data);
    }

    await writeAudit({ action: 'engine2.layer1_tasks_issued', guardianId, childId, meta: { session_id: session.id, verticals: config.activeVerticals } });
    return ok({
      session_id: session.id,
      phase: 'layer1',
      verticals: taskRows.map(publicTask),
      active_verticals: config.activeVerticals,
    }, 200);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[layer1-tasks] unexpected:', (err as Error).message);
    return internalError();
  }
});
