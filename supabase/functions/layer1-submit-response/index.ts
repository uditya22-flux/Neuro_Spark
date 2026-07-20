import { corsHeaders, requireAuth, badRequest, conflict, internalError, ok } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import { ValidationError, requireActiveConsent, requireOwnership, requireUuid, requireInt } from '../_shared/validate.ts';
import { evaluateAnswer, scoreResponse, type SourceType } from '../_shared/engine2.ts';

function numberField(value: unknown, field: string, fallback = 0): number {
  if (value === undefined || value === null) return fallback;
  const n = Number(value);
  if (!Number.isFinite(n)) throw new ValidationError(`${field} must be numeric.`);
  return n;
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
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const { data: session } = await svc.from('layer1_sessions').select('id, status').eq('id', sessionId).eq('child_id', childId).eq('guardian_id', guardianId).maybeSingle();
    if (!session) return conflict('Layer 1 session is not available.');
    const { data: task } = await svc.from('vertical_task_bank').select('id, child_id, session_id, vertical_id, source_type, item_payload').eq('id', taskId).eq('session_id', sessionId).eq('child_id', childId).eq('layer_number', 1).maybeSingle();
    if (!task) return conflict('Layer 1 task is not available.');

    const response = body.response ?? body.user_response;
    const answerAccuracy = evaluateAnswer(task.item_payload as Record<string, unknown>, response);
    const timing = (body.timing ?? {}) as Record<string, unknown>;
    const behavior = (body.behavior ?? {}) as Record<string, unknown>;
    const scored = scoreResponse(
      answerAccuracy,
      numberField(timing.latency_ms ?? body.latency_ms, 'latency_ms'),
      Math.max(0, Math.floor(numberField(behavior.retry_count ?? body.recovery_count, 'retry_count'))),
      Math.max(0, Math.floor(numberField(behavior.hint_usage ?? (body.used_hint ? 1 : 0), 'hint_usage'))),
      behavior.skipped === true || body.skipped === true,
      task.source_type as SourceType,
    );
    const telemetryReference = `layer1:${sessionId}:${task.vertical_id}:${Date.now()}`;
    const { error: telemetryError } = await svc.from('sublayer_telemetry').insert({
      session_id: sessionId, child_id: childId, task_id: taskId, vertical_id: task.vertical_id,
      source_type: task.source_type, accuracy: scored.accuracy, latency_ms: scored.latencyMs,
      recovery: scored.recovery, engagement: scored.engagement, speed: scored.speed,
      source_confidence: scored.isolationScore === 0 ? 0 : scored.isolationScore / Math.max(0.0001, (0.4 * scored.accuracy) + (0.3 * scored.recovery) + (0.2 * scored.engagement) + (0.1 * scored.speed)),
      isolation_score: scored.isolationScore, telemetry_reference: telemetryReference,
    });
    if (telemetryError) {
      console.error('[layer1-submit-response] telemetry:', telemetryError.message);
      return internalError('Layer 1 response could not be recorded.');
    }

    const { data: sessionTasks } = await svc.from('vertical_task_bank').select('vertical_id').eq('session_id', sessionId).eq('layer_number', 1).eq('active', true);
    const expectedVerticals = new Set((sessionTasks ?? []).map((row: { vertical_id: string }) => row.vertical_id));
    const { data: allVerticals } = await svc.from('sublayer_telemetry').select('vertical_id, isolation_score, accuracy, recovery, engagement, speed, telemetry_reference').eq('session_id', sessionId);
    const latest = new Map<string, Record<string, unknown>>();
    for (const row of allVerticals ?? []) latest.set(row.vertical_id, row);
    const complete = expectedVerticals.size > 0 && [...expectedVerticals].every((vertical) => latest.has(vertical));
    if (complete) {
      for (const row of latest.values()) {
        await svc.from('stage2_handoffs').upsert({
          session_id: sessionId, child_id: childId, vertical_id: row.vertical_id,
          isolation_score: row.isolation_score, accuracy: row.accuracy, recovery: row.recovery,
          engagement: row.engagement, speed: row.speed, telemetry_reference: row.telemetry_reference,
        }, { onConflict: 'session_id,vertical_id' });
      }
      await svc.from('layer1_sessions').update({ status: 'complete', completed_at: new Date().toISOString() }).eq('id', sessionId);
    }
    await writeAudit({ action: 'engine2.layer1_response_recorded', guardianId, childId, meta: { session_id: sessionId, task_id: taskId, vertical_id: task.vertical_id, isolation_score: scored.isolationScore } });
    return ok({
      session_id: sessionId, vertical_id: task.vertical_id, accuracy: scored.accuracy,
      isolation_score: scored.isolationScore, layer1_complete: complete,
      next_phase: complete ? 'deepening' : 'layer1',
    }, 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[layer1-submit-response] unexpected:', (err as Error).message);
    return internalError();
  }
});
