import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import {
  ValidationError,
  requireString,
  requireUuid,
  requireOwnership,
  requireActiveConsent,
} from '../_shared/validate.ts';

// ---------------------------------------------------------------------------
// PII redaction — extended patterns for India-region deployment
// ---------------------------------------------------------------------------
function redactPii(text: string): string {
  return text
    // Email addresses
    .replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[redacted-email]')
    // Phone numbers (10-digit Indian / 12-digit with country code)
    .replace(/(?<!\d)(\+91[-\s]?)?[6-9]\d{9}(?!\d)/g, '[redacted-phone]')
    // Aadhaar (12 digits, often space-separated)
    .replace(/\b\d{4}\s?\d{4}\s?\d{4}\b/g, '[redacted-aadhaar]')
    // PAN card
    .replace(/\b[A-Z]{5}\d{4}[A-Z]\b/g, '[redacted-pan]')
    // Generic long numeric IDs (9+ digits)
    .replace(/\b\d{9,}\b/g, '[redacted-id]')
    // Indian pincodes (6-digit)
    .replace(/\b\d{6}\b/g, '[redacted-pincode]');
}

const MAX_TEXT = 4000;
const RETENTION_DAYS = 30;

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
    const rawText = requireString(body.text, 'text', MAX_TEXT);

    // Business-rule checks
    await requireOwnership(db, guardianId, childId);
    await requireActiveConsent(db, guardianId);

    const redactedText = redactPii(rawText);
    const expiresAt = new Date(Date.now() + RETENTION_DAYS * 86_400_000).toISOString();

    const { data, error } = await db
      .from('discovery_intakes')
      .insert({
        guardian_id: guardianId,
        child_id: childId,
        raw_text: rawText,
        redacted_text: redactedText,
        expires_at: expiresAt,
      })
      .select('id, child_id, redacted_text, expires_at, created_at')
      .single();

    if (error) {
      console.error('[submit-intake] db error:', error.message);
      return internalError('Intake could not be saved. Please try again.');
    }

    await writeAudit({
      action: 'submit_intake',
      guardianId,
      childId,
      meta: { intake_id: data.id, expires_at: expiresAt },
    });

    // Return redacted copy only — never echo raw_text back
    return ok(
      {
        id: data.id,
        childId: data.child_id,
        expiresAt: data.expires_at,
        createdAt: data.created_at,
      },
      201,
    );
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[submit-intake] unexpected:', (err as Error).message);
    return internalError();
  }
});
