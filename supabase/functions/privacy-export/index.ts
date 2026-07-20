import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import { ValidationError, optionalUuid, requireOwnership } from '../_shared/validate.ts';

// Fields that must never appear in an export payload
const EXCLUDED_INTERNAL_FIELDS = ['raw_text', 'fcm_token', 'fcm_token_updated_at'];

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId, userClient: db } = auth;

  let body: Record<string, unknown>;
  try {
    body = await req.json().catch(() => ({}));
  } catch {
    body = {};
  }

  try {
    const childId = optionalUuid(body.childId, 'childId');
    if (childId) await requireOwnership(db, guardianId, childId);

    // ---- Collect authorized records ----------------------------------------

    const [
      profileRes,
      consentsRes,
      verificationsRes,
      childrenRes,
    ] = await Promise.all([
      db.from('profiles').select('id, role, preferred_name, created_at, updated_at').eq('id', guardianId).single(),
      db.from('guardian_consents').select('id, consent_version_id, status, accepted_at, revoked_at').eq('guardian_id', guardianId),
      db.from('parent_verifications').select('id, method, status, verified_at, created_at').eq('guardian_id', guardianId),
      childId
        ? db.from('children').select('id, preferred_name, birth_year, created_at').eq('id', childId).eq('guardian_id', guardianId)
        : db.from('children').select('id, preferred_name, birth_year, created_at').eq('guardian_id', guardianId),
    ]);

    const resolvedChildIds: string[] = childId
      ? [childId]
      : (childrenRes.data ?? []).map((c: { id: string }) => c.id);

    let sessions: unknown[] = [];
    let intakes: unknown[] = [];
    let sensoryConfigs: unknown[] = [];
    let purgeRequests: unknown[] = [];

    if (resolvedChildIds.length > 0) {
      const [sessRes, intakeRes, sensoryRes] = await Promise.all([
        db.from('sessions').select('id, child_id, expires_at, revoked_at, created_at').in('child_id', resolvedChildIds),
        // Return redacted_text only — raw_text is explicitly excluded
        db.from('discovery_intakes').select('id, child_id, redacted_text, expires_at, created_at').in('child_id', resolvedChildIds),
        db.from('sensory_configurations').select('id, child_id, config_version, key, proposed_value, status, reviewed_at, active').in('child_id', resolvedChildIds),
      ]);
      sessions = sessRes.data ?? [];
      intakes = intakeRes.data ?? [];
      sensoryConfigs = sensoryRes.data ?? [];
    }

    const purgeRes = await db
      .from('purge_requests')
      .select('id, child_id, status, requested_at, completed_at')
      .eq('guardian_id', guardianId);
    purgeRequests = purgeRes.data ?? [];

    // ---- Build export — adult_exploratory_note is intentionally excluded -----
    const exportPayload = {
      exportedAt: new Date().toISOString(),
      guardian: profileRes.data,
      consents: consentsRes.data ?? [],
      parentVerifications: verificationsRes.data ?? [],
      children: childrenRes.data ?? [],
      sessions,
      // Only redacted intake text is included
      discoveryIntakes: intakes,
      sensoryConfigurations: sensoryConfigs,
      purgeRequests,
      // adult_exploratory_note: intentionally omitted from export for child-safety compliance
    };

    // Audit: log that an export was requested, NOT what was exported
    await writeAudit({
      action: 'privacy_export_requested',
      guardianId,
      childId,
      meta: {
        scoped_to_child: !!childId,
        record_counts: {
          children: (childrenRes.data ?? []).length,
          sessions: sessions.length,
          intakes: intakes.length,
        },
      },
    });

    return ok(exportPayload);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[privacy-export] unexpected:', (err as Error).message);
    return internalError();
  }
});
