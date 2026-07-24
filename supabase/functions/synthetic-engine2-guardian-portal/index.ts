import {
  badRequest,
  corsHeaders,
  forbidden,
  internalError,
  notFound,
  ok,
  requireAuth,
} from '../_shared/auth.ts';

// A short-lived, fictional-demo viewer endpoint. The synthetic session UUID
// itself is an opaque 128-bit share code and expires with its anonymous demo
// session. This endpoint never joins a synthetic run to a guardian, child,
// intake, profile, or production Engine 2 record.

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const syntheticDemoSessionLifetimeMs = 24 * 60 * 60 * 1000;

type SnapshotRequest = {
  action: 'snapshot';
  sessionId: string;
};

type SessionRow = {
  id: string;
  status: 'in_progress' | 'complete' | 'expired';
  current_layer: number;
  active_sectors: unknown;
  final_sector: string | null;
  final_sandbox: string | null;
  expires_at: string;
  created_at: string;
  updated_at: string;
};

type EventRow = {
  task_id: string;
  layer: number;
  sector: string;
  correct: boolean;
  latency_ms: number;
  misclicks: number;
  recovered_errors: number;
  interactions: number;
  support_level: number;
  accuracy: number;
  recovery: number;
  engagement: number;
  speed: number;
  isolation_score: number;
  created_at: string;
};

function parseRequest(raw: unknown): SnapshotRequest {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new Error('Request body must be an object.');
  }
  const body = raw as Record<string, unknown>;
  const keys = Object.keys(body).sort();
  if (keys.length !== 2 || keys[0] !== 'action' || keys[1] !== 'session_id') {
    throw new Error('Only action and session_id are allowed.');
  }
  if (body.action !== 'snapshot') {
    throw new Error('action must be snapshot.');
  }
  if (typeof body.session_id !== 'string' || !uuidPattern.test(body.session_id)) {
    throw new Error('session_id must be an opaque session UUID.');
  }
  return { action: 'snapshot', sessionId: body.session_id };
}

function sectorList(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((value): value is string => typeof value === 'string').slice(0, 30);
}

function asFiniteNumber(value: unknown): number {
  const number = typeof value === 'number'
    ? value
    : typeof value === 'string'
    ? Number(value)
    : Number.NaN;
  return Number.isFinite(number) ? number : 0;
}

function expiryFromCreatedAt(createdAt: string): string | null {
  const createdAtMs = new Date(createdAt).getTime();
  if (!Number.isFinite(createdAtMs)) return null;
  return new Date(createdAtMs + syntheticDemoSessionLifetimeMs).toISOString();
}

async function extendDemoLifetimeIfNeeded(
  serviceClient: ReturnType<typeof import('../_shared/auth.ts').buildServiceClient>,
  session: SessionRow,
): Promise<SessionRow> {
  const extendedExpiresAt = expiryFromCreatedAt(session.created_at);
  if (extendedExpiresAt == null ||
      new Date(session.expires_at).getTime() >= new Date(extendedExpiresAt).getTime()) {
    return session;
  }
  const { data, error } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .update({ expires_at: extendedExpiresAt, updated_at: new Date().toISOString() })
    .eq('id', session.id)
    .in('status', ['in_progress', 'complete'])
    .select(
      'id,status,current_layer,active_sectors,final_sector,final_sandbox,expires_at,created_at,updated_at',
    )
    .maybeSingle();
  if (error || !data) {
    throw new Error('Synthetic guardian snapshot lifetime could not be extended.');
  }
  return data as SessionRow;
}

async function snapshot(
  serviceClient: ReturnType<typeof import('../_shared/auth.ts').buildServiceClient>,
  sessionId: string,
): Promise<Response> {
  const { data: rawSession, error: sessionError } = await serviceClient
    .from('synthetic_engine2_demo_sessions')
    .select(
      'id,status,current_layer,active_sectors,final_sector,final_sandbox,expires_at,created_at,updated_at',
    )
    .eq('id', sessionId)
    .maybeSingle();
  if (sessionError) throw new Error('Synthetic guardian snapshot could not be read.');

  // Avoid confirming whether an expired or unknown share code once existed.
  if (!rawSession) return notFound('Synthetic demo session is unavailable.');
  let session = rawSession as SessionRow;
  if (session.status === 'expired' || new Date(session.expires_at) <= new Date()) {
    return notFound('Synthetic demo session is unavailable.');
  }
  session = await extendDemoLifetimeIfNeeded(serviceClient, session);

  const [eventsResult, attemptsResult] = await Promise.all([
    serviceClient
      .from('synthetic_engine2_demo_events')
      .select(
        'task_id,layer,sector,correct,latency_ms,misclicks,recovered_errors,interactions,support_level,accuracy,recovery,engagement,speed,isolation_score,created_at',
      )
      .eq('session_id', session.id)
      .order('layer', { ascending: true })
      .order('created_at', { ascending: true }),
    serviceClient
      .from('synthetic_engine2_demo_attempts')
      .select('task_id')
      .eq('session_id', session.id),
  ]);
  if (eventsResult.error || attemptsResult.error) {
    throw new Error('Synthetic guardian snapshot events could not be read.');
  }

  const attemptedTaskIds = new Set(
    (attemptsResult.data ?? [])
      .map((row: { task_id?: unknown }) => row.task_id)
      .filter((taskId): taskId is string => typeof taskId === 'string'),
  );
  const completedEvents = ((eventsResult.data ?? []) as EventRow[]).map((event) => ({
    layer: asFiniteNumber(event.layer),
    sector: event.sector,
    correct: event.correct === true,
    latency_ms: asFiniteNumber(event.latency_ms),
    misclicks: asFiniteNumber(event.misclicks),
    recovered_errors: asFiniteNumber(event.recovered_errors),
    interactions: asFiniteNumber(event.interactions),
    support_level: asFiniteNumber(event.support_level),
    accuracy: asFiniteNumber(event.accuracy),
    recovery: asFiniteNumber(event.recovery),
    engagement: asFiniteNumber(event.engagement),
    speed: asFiniteNumber(event.speed),
    isolation_score: asFiniteNumber(event.isolation_score),
    created_at: event.created_at,
    // A completed task with no selection attempt was finalized by the
    // Support Ladder inactivity path. No inferred answer is returned.
    skipped: !attemptedTaskIds.has(event.task_id),
  }));

  return ok({
    session: {
      session_id: session.id,
      status: session.status,
      current_layer: asFiniteNumber(session.current_layer),
      active_sectors: sectorList(session.active_sectors),
      final_sector: session.final_sector,
      final_sandbox: session.final_sandbox,
      expires_at: session.expires_at,
      created_at: session.created_at,
      updated_at: session.updated_at,
      completed_task_count: completedEvents.length,
    },
    completed_events: completedEvents,
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return badRequest('POST is required.');
  if (Deno.env.get('SYNTHETIC_ENGINE2_CLOUD_ENABLED') !== 'true') {
    return Response.json(
      { error: 'Synthetic cloud Engine 2 is not enabled for this project.' },
      { status: 503, headers: corsHeaders },
    );
  }

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  if ((auth.user as { is_anonymous?: unknown }).is_anonymous !== true) {
    return forbidden('This endpoint is available only to anonymous synthetic demo sessions.');
  }

  try {
    return await snapshot(auth.serviceClient, parseRequest(await req.json()).sessionId);
  } catch (error) {
    // Neither input nor telemetry values are logged from this share endpoint.
    if (error instanceof Error && error.message.startsWith('Request body')) {
      return badRequest(error.message);
    }
    if (error instanceof Error && (
      error.message.startsWith('Only action') ||
      error.message.startsWith('action must') ||
      error.message.startsWith('session_id must')
    )) {
      return badRequest(error.message);
    }
    console.error('[synthetic-engine2-guardian-portal] snapshot unavailable');
    return internalError('Synthetic guardian snapshot could not be prepared.');
  }
});
