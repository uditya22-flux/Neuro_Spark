export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

export function json(data: unknown, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  headers.set('content-type', 'application/json; charset=utf-8');
  for (const [key, value] of Object.entries(corsHeaders)) headers.set(key, value);
  return new Response(JSON.stringify(data), { ...init, headers });
}

export function empty(status = 204): Response {
  const headers = new Headers(corsHeaders);
  return new Response(null, { status, headers });
}

export async function readJson<T>(request: Request): Promise<T> {
  return await request.json() as T;
}

export function pathSegments(request: Request): string[] {
  return new URL(request.url).pathname.split('/').filter(Boolean);
}

export function routeAfterFunction(request: Request, functionName: string): string[] {
  const segments = pathSegments(request);
  const index = segments.lastIndexOf(functionName);
  return index >= 0 ? segments.slice(index + 1) : segments;
}

export function notFound(message = 'Route not found'): Response {
  return json({ error: message }, { status: 404 });
}

export function badRequest(message: string): Response {
  return json({ error: message }, { status: 400 });
}

export function unauthorized(message = 'Unauthorized'): Response {
  return json({ error: message }, { status: 401 });
}

export function accepted(data: unknown): Response {
  return json(data, { status: 202 });
}