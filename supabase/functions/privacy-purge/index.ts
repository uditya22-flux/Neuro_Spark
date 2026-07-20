import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import {
  ValidationError,
  optionalUuid,
  requireOwnership,
} from '../_shared/validate.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db, serviceClient } = auth;

  let body: Record<string, unknown>;
  try {
    body = await req.json().catch(() => ({}));
  } catch {
    body = {};
  }

  try {
    const childId = optionalUuid(body.childId, 'childId');

    // If scoped to a specific child, verify ownership first
    if (childId) {
      await requireOwnership(db, guardianId, childId);
    }

    // Idempotency: return existing open purge request if one already exists
    const { data: existing } = await db
      .from('purge_requests')
      .select('id, status, requested_at')
      .eq('guardian_id', guardianId)
      .in('status', ['requested', 'in_progress'])
      .maybeSingle();

    if (existing) {
      return ok({ id: existing.id, status: existing.status, requestedAt: existing.requested_at }, 202);
    }

    // Create the purge request
    const { data: purge, error: purgeErr } = await db
      .from('purge_requests')
      .insert({ guardian_id: guardianId, child_id: childId ?? null, status: 'requested' })
      .select('id, status, requested_at')
      .single();

    if (purgeErr || !purge) {
      console.error('[privacy-purge] purge insert error:', purgeErr?.message);
      return internalError('Purge request could not be created.');
    }

    await writeAudit({
      action: 'purge_requested',
      guardianId,
      childId,
      meta: { purge_id: purge.id },
    });

    // Perform the cascade deletion using the service client so RLS does not block
    const purgeError = await performCascadeDelete(serviceClient, guardianId, childId, purge.id);

    if (purgeError) {
      await serviceClient
        .from('purge_requests')
        .update({ status: 'failed' })
        .eq('id', purge.id);
      await writeAudit({
        action: 'purge_failed',
        guardianId,
        childId,
        meta: { purge_id: purge.id, error: purgeError },
      });
      return internalError('Purge could not be completed. The request has been logged.');
    }

    // Mark complete
    await serviceClient
      .from('purge_requests')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', purge.id);

    await writeAudit({
      action: 'purge_completed',
      guardianId,
      childId,
      meta: { purge_id: purge.id },
    });

    return ok({ id: purge.id, status: 'completed' }, 202);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[privacy-purge] unexpected:', (err as Error).message);
    return internalError();
  }
});

// ---------------------------------------------------------------------------
// Cascade deletion helper — service-role only
// ---------------------------------------------------------------------------
async function performCascadeDelete(
  svc: ReturnType<typeof import('../_shared/auth.ts').buildServiceClient>,
  guardianId: string,
  childId: string | null,
  _purgeId: string,
): Promise<string | null> {
  try {
    if (childId) {
      // Child-scoped purge
      await svc.from('discovery_intakes').delete().eq('child_id', childId);
      await svc.from('sensory_configurations').delete().eq('child_id', childId);
      await svc.from('child_experience').delete().eq('child_id', childId);
      await svc.from('adult_exploratory_note').delete().eq('child_id', childId);
      await svc.from('sessions').delete().eq('child_id', childId);
      await svc.from('children').delete().eq('id', childId).eq('guardian_id', guardianId);
    } else {
      // Full account purge — all children of this guardian
      const { data: children } = await svc
        .from('children')
        .select('id')
        .eq('guardian_id', guardianId);

      const childIds = (children ?? []).map((c: { id: string }) => c.id);
      if (childIds.length > 0) {
        await svc.from('discovery_intakes').delete().in('child_id', childIds);
        await svc.from('sensory_configurations').delete().in('child_id', childIds);
        await svc.from('child_experience').delete().in('child_id', childIds);
        await svc.from('adult_exploratory_note').delete().in('child_id', childIds);
        await svc.from('sessions').delete().in('child_id', childIds);
        await svc.from('children').delete().eq('guardian_id', guardianId);
      }

      // Guardian-level data
      await svc.from('guardian_consents').delete().eq('guardian_id', guardianId);
      await svc.from('parent_verifications').delete().eq('guardian_id', guardianId);
      await svc.from('device_tokens').delete().eq('user_id', guardianId);
      await svc.from('trigger_instances').delete().eq('user_id', guardianId);
      await svc.from('trigger_dispatch_queue').delete().eq('user_id', guardianId);
      await svc.from('pending_triggers').delete().eq('guardian_id', guardianId);
      await svc.from('trigger_guardrails').delete().eq('guardian_id', guardianId);
      await svc.from('profiles').delete().eq('id', guardianId);
    }
    return null;
  } catch (err) {
    return (err as Error).message;
  }
}
