import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import {
  ValidationError,
  requireString,
  requireInt,
  requireVerifiedGuardian,
  requireActiveConsent,
} from '../_shared/validate.ts';

const CURRENT_YEAR = new Date().getFullYear();

Deno.serve(async (req: Request): Promise<Response> => {
  // Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Auth
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
    // --- Input validation ---
    const preferredName = requireString(body.preferredName, 'preferredName', 80);
    const birthYear = requireInt(
      body.birthYear,
      'birthYear',
      CURRENT_YEAR - 18,   // children only; guardian minimum age 18
      CURRENT_YEAR - 2,    // must be at least 2 years old
    );

    // --- Business-rule checks ---
    await requireVerifiedGuardian(db, guardianId);
    await requireActiveConsent(db, guardianId);

    // --- Insert (RLS also enforces guardian ownership) ---
    const { data, error } = await db
      .from('children')
      .insert({ guardian_id: guardianId, preferred_name: preferredName, birth_year: birthYear })
      .select('id, preferred_name, birth_year, created_at')
      .single();

    if (error) {
      // Log technical detail server-side only
      console.error('[create-child] db error:', error.message);
      return internalError('Child profile could not be created. Please try again.');
    }

    await writeAudit({
      action: 'create_child',
      guardianId,
      childId: data.id,
      meta: { birth_year: birthYear },
    });

    return ok(data, 201);
  } catch (err) {
    if (err instanceof ValidationError) return badRequest(err.message);
    console.error('[create-child] unexpected:', (err as Error).message);
    return internalError();
  }
});
