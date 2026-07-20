import { corsHeaders, requireAuth, notImplemented } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';

// ---------------------------------------------------------------------------
// DigiLocker integration — STUB
//
// This function requires a signed DigiLocker provider contract,
// legal approval, and privacy copy review before implementation.
// Returning 501 until those conditions are met.
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const { guardianId } = auth;

  await writeAudit({
    action: 'digilocker_init_attempted',
    guardianId,
    meta: { status: 'not_implemented' },
  });

  return notImplemented('DigiLocker verification is not yet available. Please use email or phone OTP verification.');
});
