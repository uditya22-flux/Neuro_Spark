import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { buildServiceClient } from './auth.ts';

export interface AuditParams {
  action: string;
  guardianId?: string | null;
  childId?: string | null;
  actorId?: string | null;
  meta?: Record<string, unknown>;
}

/**
 * Writes a row to audit_log using the service-role client so it always
 * succeeds regardless of the caller's RLS context.
 * Failures are swallowed after logging to stderr so they never block the
 * main response path — but you should alert on missing audit rows.
 */
export async function writeAudit(params: AuditParams): Promise<void> {
  try {
    const svc: SupabaseClient = buildServiceClient();
    const { error } = await svc.from('audit_log').insert({
      action: params.action,
      guardian_id: params.guardianId ?? null,
      child_id: params.childId ?? null,
      actor_id: params.actorId ?? params.guardianId ?? null,
      metadata: params.meta ?? {},
    });
    if (error) {
      console.error('[audit] write failed:', error.message);
    }
  } catch (err) {
    console.error('[audit] unexpected error:', (err as Error).message);
  }
}
