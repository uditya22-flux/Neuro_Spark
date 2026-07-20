import { corsHeaders, requireAuth, badRequest, conflict, internalError, ok } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import { ValidationError, requireActiveConsent, requireOwnership, requireUuid } from '../_shared/validate.ts';
import {
  contentHash, createTask, loadEngine1Config, pathForIsolation, pathLayers, publicTask,
  requiredExecutions, type Modality, type PathType, type VerticalId,
} from '../_shared/engine2.ts';

function vertical(value: unknown): VerticalId {
  if (value === 'calendar_genius' || value === 'constellation_mapper') return value;
  throw new ValidationError('vertical_id must be calendar_genius or constellation_mapper.');
}

async function buildTask(svc: ReturnType<typeof import('../_shared/auth.ts').buildServiceClient>, childId: string, sessionId: string, verticalId: VerticalId, layer: number, config: Awaited<ReturnType<typeof loadEngine1Config>>, modality: Modality) {
  for (let attempt = 0; attempt < 5; attempt++) {
    const task = await createTask(verticalId, layer, `${sessionId}:${verticalId}:${layer}:${attempt}:${Date.now()}`, config, modality);
    const hash = await contentHash({ verticalId, layer, payload: task.payload, answer: task.answerKey });
    if (layer === 3) {
      const { data: seen } = await svc.from('vertical_task_bank').select('id').eq('child_id', childId).eq('vertical_id', verticalId).eq('layer_number', 3).eq('content_hash', hash).limit(1);
      if (seen && seen.length > 0) continue;
    }
    const { data, error } = await svc.from('vertical_task_bank').insert({
      child_id: childId, session_id: sessionId, vertical_id: verticalId, layer_number: layer,
      source_type: task.sourceType, difficulty_tier: task.difficultyTier,
      item_payload: { public_payload: task.payload, answer_key: task.answerKey },
      content_hash: hash, rule_version: task.ruleVersion,
    }).select('id, vertical_id, layer_number, source_type, difficulty_tier, item_payload').single();
    if (error || !data) throw new Error('Deepening task could not be stored.');
    return data as Record<string, unknown>;
  }
  throw new Error('Could not create an unseen Layer 3 task.');
}

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
    const verticalId = vertical(body.vertical_id ?? body.verticalId);
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data: handoff } = await svc.from('stage2_handoffs').select('isolation_score, recovery').eq('session_id', sessionId).eq('child_id', childId).eq('vertical_id', verticalId).maybeSingle();
    if (!handoff) return conflict('Complete Layer 1 for this vertical before starting deepening.');
    const config = await loadEngine1Config(db, guardianId, childId);
    let { data: state } = await svc.from('layer_progression_state').select('*').eq('session_id', sessionId).eq('child_id', childId).eq('vertical_id', verticalId).maybeSingle();
    if (!state) {
      const path = pathForIsolation(Number(handoff.isolation_score), Number(handoff.recovery));
      const { data: created, error } = await svc.from('layer_progression_state').insert({
        session_id: sessionId, child_id: childId, vertical_id: verticalId, current_layer: pathLayers(path)[0],
        path_type: path, path_layers: pathLayers(path), completed_layers: [], support_level: path === 'supported' ? 1 : 0,
      }).select('*').single();
      if (error || !created) throw new Error('Deepening progression could not be initialized.');
      state = created;
    }
    if (state.status === 'funnel_complete') return ok({ status: 'funnel_complete', session_id: sessionId, vertical_id: verticalId, path_type: state.path_type, layers_completed: state.completed_layers ?? [] });

    let task: Record<string, unknown> | null = null;
    let executionCount = 0;
    if (state.current_task_id) {
      const { data } = await svc.from('vertical_task_bank').select('id, vertical_id, layer_number, source_type, difficulty_tier, item_payload').eq('id', state.current_task_id).eq('session_id', sessionId).maybeSingle();
      task = data;
      const countRes = await svc.from('layer_task_execution').select('id', { count: 'exact', head: true }).eq('session_id', sessionId).eq('vertical_id', verticalId).eq('task_id', state.current_task_id);
      executionCount = countRes.count ?? 0;
    }
    if (!task) {
      const modality: Modality = state.current_layer === 5 ? 'visual' : 'visual';
      task = await buildTask(svc, childId, sessionId, verticalId, state.current_layer, config, modality);
      await svc.from('layer_progression_state').update({ current_task_id: task.id, status: 'in_progress', updated_at: new Date().toISOString() }).eq('id', state.id);
      executionCount = 0;
    }
    const required = requiredExecutions(Number(task.layer_number));
    await writeAudit({ action: 'engine2.deepening_task_issued', guardianId, childId, meta: { session_id: sessionId, vertical_id: verticalId, layer: task.layer_number } });
    return ok({
      status: 'in_progress', session_id: sessionId, vertical_id: verticalId, path_type: state.path_type,
      support_level: state.support_level, timing_variant: executionCount + 1, required_executions: required,
      ...publicTask(task),
    });
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[deepening-next-task] unexpected:', (err as Error).message);
    return internalError();
  }
});
