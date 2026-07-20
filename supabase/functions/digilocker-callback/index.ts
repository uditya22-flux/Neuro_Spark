import { corsHeaders, notImplemented } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';

// ---------------------------------------------------------------------------
// DigiLocker callback — STUB
//
// verify_jwt = false in config.toml (this is an OAuth callback).
// Still not implemented pending provider contract and legal approval.
// ---------------------------------------------------------------------------

Deno.serve(async (_req: Request): Promise<Response> => {
  // No JWT available here (OAuth redirect callback)
  await writeAudit({
    action: 'digilocker_callback_received',
    meta: { status: 'not_implemented' },
  });

  return notImplemented('DigiLocker verification is not yet available.');
});
