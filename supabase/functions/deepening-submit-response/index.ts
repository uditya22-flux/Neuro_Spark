import { corsHeaders, requireAuth, badRequest, conflict, internalError, ok } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import { ValidationError, requireActiveConsent, requireOwnership, requireUuid } from '../_shared/validate.ts';
import {
  evaluateAnswer, pathLayers, requiredExecutions, scoreResponse, supportTransition,
  type PathType, type SourceType,
} from '../_shared/engine2.ts';

function numberField(value: unknown, field: string, fallback = 0): number {
  if (value === undefined || value === null) return fallback;
  const n = Number(value);
  if (!Number.isFinite(n)) throw new ValidationError(`${field} must be numeric.`);
  return n;
}

function average(values: number[]): number { return values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0; }

async function createProfile(svc: ReturnType<typeof import('../_shared/auth.ts').buildServiceClient>, sessionId: string, childId: string, verticalId: string): Promise<Record<string, unknown>> {
  const { data: executions } = await svc.from('layer_task_execution').select('*').eq('session_id', sessionId).eq('vertical_id', verticalId).order('layer_number', { ascending: true });
  const rows = executions ?? [];
  const layerScores: Record<string, unknown> = {};
  for (let layer = 2; layer <= 10; layer++) {
    const layerRows = rows.filter((row: Record<string, unknown>) => row.layer_number === layer);
    if (layerRows.length) {
      layerScores[`layer_${layer}`] = {
        accuracy: average(layerRows.map((r: Record<string, unknown>) => Number(r.accuracy))),
        recovery: average(layerRows.map((r: Record<string, unknown>) => Number(r.recovery))),
        engagement: average(layerRows.map((r: Record<string, unknown>) => Number(r.engagement))),
        speed: average(layerRows.map((r: Record<string, unknown>) => 1 - Math.min(Number(r.latency_ms), 60_000) / 60_000)),
        metric_values: layerRows.map((r: Record<string, unknown>) => r.metric_values),
      };
    }
  }
  const { data: logs } = await svc.from('support_ladder_log').select('support_level, outcome').eq('session_id', sessionId).eq('vertical_id', verticalId);
  const { data: windows } = await svc.from('consistency_window').select('accuracy_stability_score, fatigue_score').eq('session_id', sessionId).eq('vertical_id', verticalId).order('window_index');
  const modalityCounts = new Map<string, number>();
  for (const row of rows) modalityCounts.set(row.modality, (modalityCounts.get(row.modality) ?? 0) + 1);
  const modalityPreference = [...modalityCounts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'visual';
  const supportLevels = rows.map((r: Record<string, unknown>) => Number(r.support_level));
  const profile = {
    vertical_id: verticalId,
    path_type: 'fixed_mvp',
    layers_completed: [2, 3, 4, 5, 6, 7, 8, 9, 10].filter((layer) => !!layerScores[`layer_${layer}`]),
    layer_scores: layerScores,
    support_ladder_summary: {
      avg_support_level: average(supportLevels),
      escalation_count: (logs ?? []).filter((l: Record<string, unknown>) => l.outcome === 'escalated_further').length,
      modality_preference: modalityPreference,
    },
    behavioral_signals: {
      strategy_tag: supportLevels.some((level) => level >= 3) ? 'benefits_from_demonstration' : 'independent_strategy_use',
      retry_rate: average(rows.map((r: Record<string, unknown>) => Number(r.retry_count) > 0 ? 1 : 0)),
      hint_dependency: average(rows.map((r: Record<string, unknown>) => Number(r.hint_usage) > 0 ? 1 : 0)),
    },
    consistency_score: average((windows ?? []).map((w: Record<string, unknown>) => Number(w.accuracy_stability_score))),
    transfer_score: Number((layerScores.layer_7 as Record<string, unknown> | undefined)?.accuracy ?? 0),
    real_world_readiness_score: Number((layerScores.layer_10 as Record<string, unknown> | undefined)?.accuracy ?? 0),
    telemetry_reference: `deepening:${sessionId}:${verticalId}`,
  };
  await svc.from('deepening_profiles').upsert({ session_id: sessionId, child_id: childId, vertical_id: verticalId, profile, telemetry_reference: profile.telemetry_reference }, { onConflict: 'session_id,vertical_id' });
  return profile;
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
    const taskId = requireUuid(body.task_id ?? body.taskId, 'task_id');
    const verticalId = body.vertical_id ?? body.verticalId;
    if (verticalId !== 'calendar_genius' && verticalId !== 'constellation_mapper') throw new ValidationError('vertical_id is required.');
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);
    const { data: state } = await svc.from('layer_progression_state').select('*').eq('session_id', sessionId).eq('child_id', childId).eq('vertical_id', verticalId).maybeSingle();
    if (!state) return conflict('Deepening progression is not initialized.');
    const { data: task } = await svc.from('vertical_task_bank').select('*').eq('id', taskId).eq('session_id', sessionId).eq('child_id', childId).eq('vertical_id', verticalId).maybeSingle();
    if (!task || task.id !== state.current_task_id) return conflict('This task is not the active task.');
    const timing = (body.timing ?? {}) as Record<string, unknown>;
    const behavior = (body.behavior ?? {}) as Record<string, unknown>;
    const retryCount = Math.max(0, Math.floor(numberField(behavior.retry_count ?? body.recovery_count, 'retry_count')));
    const hintUsage = Math.max(0, Math.floor(numberField(behavior.hint_usage ?? (body.used_hint ? 1 : 0), 'hint_usage')));
    const skipped = behavior.skipped === true || body.skipped === true;
    const response = body.response ?? body.user_response;
    const accuracy = evaluateAnswer(task.item_payload as Record<string, unknown>, response);
    const scored = scoreResponse(accuracy, numberField(timing.latency_ms ?? body.latency_ms, 'latency_ms'), retryCount, hintUsage, skipped, task.source_type as SourceType);
    const path = state.path_type as PathType;
    const suppliedSupport = Math.max(0, Math.min(5, Math.floor(numberField(body.support_level_used ?? body.supportLevel, 'support_level_used', Number(state.support_level) || 0))));
    const transition = supportTransition(Math.max(Number(state.support_level) || 0, suppliedSupport), { accuracy: scored.accuracy, latencyMs: scored.latencyMs, retryCount, skipped, path });
    const supportLevel = transition.level;
    const metricValues: Record<string, unknown> = { objective: (task.item_payload as Record<string, unknown>).public_payload ? ((task.item_payload as Record<string, unknown>).public_payload as Record<string, unknown>).objective : null };
    if (Number(task.layer_number) === 4) metricValues.timing_variant = Number(body.timing_variant ?? 1);
    if (Number(task.layer_number) === 5) metricValues.modality = body.modality ?? 'visual';
    if (Number(task.layer_number) === 7) metricValues.transfer = scored.accuracy;
    if (Number(task.layer_number) === 9) metricValues.consistency = scored.accuracy;
    const { error: executionError } = await svc.from('layer_task_execution').insert({
      task_id: taskId, session_id: sessionId, child_id: childId, vertical_id: verticalId, layer_number: task.layer_number,
      source_type: task.source_type, modality: body.modality ?? 'visual', support_level: suppliedSupport,
      accuracy: scored.accuracy, latency_ms: scored.latencyMs, recovery: scored.recovery, engagement: scored.engagement,
      retry_count: retryCount, hint_usage: hintUsage, answer_changes: Math.max(0, Math.floor(numberField(behavior.answer_changes, 'answer_changes'))),
      skipped, metric_values: metricValues, response: typeof response === 'object' && response !== null ? response : { value: response },
    });
    if (executionError) {
      console.error('[deepening-submit-response] execution:', executionError.message);
      return internalError('Response could not be recorded.');
    }
    if (transition.reason && transition.level !== Number(state.support_level)) {
      await svc.from('support_ladder_log').insert({
        session_id: sessionId, task_id: taskId, child_id: childId, vertical_id: verticalId,
        support_level: transition.level, trigger_reason: transition.reason,
        outcome: transition.level > Number(state.support_level) ? 'escalated_further' : 'de_escalated',
      });
    }

    const { count } = await svc.from('layer_task_execution').select('id', { count: 'exact', head: true }).eq('task_id', taskId).eq('session_id', sessionId);
    const required = requiredExecutions(Number(task.layer_number));
    const layerComplete = (count ?? 0) >= required;
    let funnelComplete = false;
    let nextLayer: number | null = null;
    let profile: Record<string, unknown> | null = null;
    if (layerComplete) {
      const completed = Array.isArray(state.completed_layers) ? [...state.completed_layers, Number(task.layer_number)] : [Number(task.layer_number)];
      const uniqueCompleted = [...new Set(completed)].sort((a, b) => Number(a) - Number(b));
      const layers = (Array.isArray(state.path_layers) ? state.path_layers : pathLayers(path)).map(Number);
      const index = layers.indexOf(Number(task.layer_number));
      funnelComplete = index < 0 || index >= layers.length - 1;
      nextLayer = funnelComplete ? null : layers[index + 1];
      await svc.from('layer_progression_state').update({
        current_layer: funnelComplete ? Number(task.layer_number) : nextLayer,
        completed_layers: uniqueCompleted, status: funnelComplete ? 'funnel_complete' : 'in_progress',
        current_task_id: funnelComplete ? null : null, support_level: supportLevel, updated_at: new Date().toISOString(),
      }).eq('id', state.id);
      if (Number(task.layer_number) === 9) {
        await svc.from('consistency_window').upsert({ session_id: sessionId, child_id: childId, vertical_id: verticalId, window_index: count ?? 0, accuracy_stability_score: scored.accuracy, fatigue_score: 1 - scored.speed }, { onConflict: 'session_id,vertical_id,window_index' });
      }
      if (funnelComplete) profile = await createProfile(svc, sessionId, childId, verticalId);
    } else {
      await svc.from('layer_progression_state').update({ support_level: supportLevel, updated_at: new Date().toISOString() }).eq('id', state.id);
    }
    await writeAudit({ action: 'engine2.deepening_response_recorded', guardianId, childId, meta: { session_id: sessionId, vertical_id: verticalId, layer: task.layer_number, support_level: supportLevel, layer_complete: layerComplete } });
    return ok({
      session_id: sessionId, vertical_id: verticalId, layer: task.layer_number, accuracy: scored.accuracy,
      support_level: supportLevel, layer_complete: layerComplete, funnel_complete: funnelComplete,
      next_layer: nextLayer, profile,
    }, 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[deepening-submit-response] unexpected:', (err as Error).message);
    return internalError();
  }
});
