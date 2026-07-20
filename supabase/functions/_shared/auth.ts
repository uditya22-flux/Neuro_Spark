import { createClient, SupabaseClient, User } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from './cors.ts';

export { corsHeaders };

// ---------------------------------------------------------------------------
// Client builders
// ---------------------------------------------------------------------------

/** Anon-scoped client that inherits the caller's JWT for RLS enforcement. */
export function buildUserClient(authHeader: string): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
}

/**
 * Service-role client for privileged writes (audit_log, cascade deletes, etc.).
 * NEVER pass this to Flutter. Only used inside Edge Functions.
 */
export function buildServiceClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
}

// ---------------------------------------------------------------------------
// Auth extraction
// ---------------------------------------------------------------------------

export interface AuthContext {
  user: User;
  userClient: SupabaseClient;
  serviceClient: SupabaseClient;
  guardianId: string;
}

/**
 * Validates the JWT and returns a typed auth context.
 * Returns a 401 Response if the token is missing or invalid.
 */
export async function requireAuth(
  req: Request,
): Promise<AuthContext | Response> {
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return unauthorized('Missing or malformed Authorization header.');
  }

  const userClient = buildUserClient(authHeader);
  const {
    data: { user },
    error,
  } = await userClient.auth.getUser();

  if (error || !user) {
    return unauthorized('Invalid or expired token.');
  }

  return {
    user,
    userClient,
    serviceClient: buildServiceClient(),
    guardianId: user.id,
  };
}

// ---------------------------------------------------------------------------
// Safe error responses
// ---------------------------------------------------------------------------

export function unauthorized(msg = 'Unauthorized'): Response {
  return Response.json({ error: msg }, { status: 401, headers: corsHeaders });
}

export function forbidden(msg = 'Forbidden'): Response {
  return Response.json({ error: msg }, { status: 403, headers: corsHeaders });
}

export function badRequest(msg: string): Response {
  return Response.json({ error: msg }, { status: 400, headers: corsHeaders });
}

export function notFound(msg = 'Not found'): Response {
  return Response.json({ error: msg }, { status: 404, headers: corsHeaders });
}

export function conflict(msg: string): Response {
  return Response.json({ error: msg }, { status: 409, headers: corsHeaders });
}

export function locked(msg: string): Response {
  return Response.json({ error: msg }, { status: 423, headers: corsHeaders });
}

export function notImplemented(msg: string): Response {
  return Response.json({ error: msg }, { status: 501, headers: corsHeaders });
}

export function internalError(msg = 'An unexpected error occurred.'): Response {
  return Response.json({ error: msg }, { status: 500, headers: corsHeaders });
}

export function ok(data: unknown, status = 200): Response {
  return Response.json(data, { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
}
