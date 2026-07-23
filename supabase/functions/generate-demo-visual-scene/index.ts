import {
  badRequest,
  corsHeaders,
  forbidden,
  internalError,
  ok,
  requireAuth,
} from '../_shared/auth.ts';
import { ValidationError } from '../_shared/validate.ts';

const groqBaseUrl = Deno.env.get('GROQ_BASE_URL') ?? 'https://api.groq.com/openai/v1';
const scenarioSubjects = {
  vehicles: 'vehicles',
  rail: 'rail',
  space: 'space',
  pipes: 'pipes',
  animals: 'animals',
  garden: 'garden',
} as const;
const scenarioIds = new Set(Object.keys(scenarioSubjects));
const colors = new Set(['red', 'orange', 'yellow', 'green', 'blue', 'purple', 'pink', 'silver']);
const styles = new Set(['simpleShapes', 'illustratedObjects', 'realWorldObjects']);
const sceneTypes = new Set(['match', 'sort', 'connect', 'sequence', 'route', 'rotate']);
const layouts = new Set(['leftToRight', 'grid', 'path']);
const actions = new Set(['none', 'slide', 'roll', 'rotate', 'snap', 'gentlePulse']);
const requestKeys = new Set(['scenarioId', 'palette', 'objectStyle', 'motionAllowed', 'layer']);

type ScenarioId = keyof typeof scenarioSubjects;

type DemoSceneRequest = {
  scenarioId: ScenarioId;
  palette: string[];
  objectStyle: string;
  motionAllowed: boolean;
  layer: number;
};

function requireDemoRequest(value: unknown): DemoSceneRequest {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ValidationError('A demo scene request object is required.');
  }
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => !requestKeys.has(key))) {
    throw new ValidationError('The demo request contains an unsupported field.');
  }
  const scenarioId = body.scenarioId;
  if (typeof scenarioId !== 'string' || !scenarioIds.has(scenarioId)) {
    throw new ValidationError('scenarioId is not an allowed fictional demo world.');
  }
  const palette = body.palette;
  if (!Array.isArray(palette) || palette.length < 1 || palette.length > 3 ||
      palette.some((color) => typeof color !== 'string' || !colors.has(color)) ||
      new Set(palette).size !== palette.length) {
    throw new ValidationError('palette must contain one to three distinct allowed colours.');
  }
  const objectStyle = body.objectStyle;
  if (typeof objectStyle !== 'string' || !styles.has(objectStyle)) {
    throw new ValidationError('objectStyle is invalid.');
  }
  const motionAllowed = body.motionAllowed;
  if (typeof motionAllowed !== 'boolean') {
    throw new ValidationError('motionAllowed must be true or false.');
  }
  const layer = body.layer;
  if (typeof layer !== 'number' || !Number.isInteger(layer) || layer < 1 || layer > 10) {
    throw new ValidationError('layer must be an integer from 1 to 10.');
  }
  return {
    scenarioId: scenarioId as ScenarioId,
    palette: [...palette] as string[],
    objectStyle,
    motionAllowed,
    layer,
  };
}

function sceneSchema(motionAllowed: boolean): Record<string, unknown> {
  const permittedActions = motionAllowed ? [...actions] : ['none'];
  return {
    name: 'mindbridge_synthetic_demo_scene',
    strict: true,
    schema: {
      type: 'object',
      additionalProperties: false,
      required: ['scene_type', 'layout', 'item_count', 'animation'],
      properties: {
        scene_type: { type: 'string', enum: [...sceneTypes] },
        layout: { type: 'string', enum: [...layouts] },
        item_count: { type: 'integer', minimum: 3, maximum: 5 },
        animation: {
          type: 'object',
          additionalProperties: false,
          required: ['on_tap', 'success'],
          properties: {
            on_tap: { type: 'string', enum: permittedActions },
            success: { type: 'string', enum: permittedActions },
          },
        },
      },
    },
  };
}

function parseScene(value: unknown, request: DemoSceneRequest): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ValidationError('Generated demo scene is invalid.');
  }
  const raw = value as Record<string, unknown>;
  const sceneType = raw.scene_type;
  const layout = raw.layout;
  const itemCount = raw.item_count;
  const animation = raw.animation;
  if (typeof sceneType !== 'string' || !sceneTypes.has(sceneType) ||
      typeof layout !== 'string' || !layouts.has(layout) ||
      typeof itemCount !== 'number' || !Number.isInteger(itemCount) || itemCount < 3 || itemCount > 5 ||
      !animation || typeof animation !== 'object' || Array.isArray(animation)) {
    throw new ValidationError('Generated demo scene did not match the safe schema.');
  }
  const animationRaw = animation as Record<string, unknown>;
  const onTap = animationRaw.on_tap;
  const success = animationRaw.success;
  const permittedActions = request.motionAllowed ? actions : new Set(['none']);
  if (typeof onTap !== 'string' || !permittedActions.has(onTap) ||
      typeof success !== 'string' || !permittedActions.has(success)) {
    throw new ValidationError('Generated demo animation is invalid.');
  }
  return {
    scene_type: sceneType,
    subject: scenarioSubjects[request.scenarioId],
    palette: request.palette,
    object_style: request.objectStyle,
    layout,
    item_count: itemCount,
    animation: { on_tap: onTap, success },
    show_text: false,
  };
}

function quotaLimit(): number {
  const raw = Number(Deno.env.get('DEMO_VISUAL_RATE_LIMIT_PER_HOUR') ?? '24');
  return Number.isInteger(raw) && raw >= 1 && raw <= 100 ? raw : 24;
}

async function consumeQuota(
  serviceClient: { rpc: Function },
  anonymousUserId: string,
): Promise<boolean> {
  const { data, error } = await serviceClient.rpc('consume_synthetic_demo_scene_quota', {
    p_user_id: anonymousUserId,
    p_limit: quotaLimit(),
  });
  if (error) {
    console.error('[generate-demo-visual-scene] quota check failed');
    throw new Error('quota check failed');
  }
  return data === true;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return badRequest('POST is required.');
  if (Deno.env.get('DEMO_VISUAL_GENERATION_ENABLED') !== 'true') {
    return Response.json(
      { error: 'Synthetic demo visual generation is not enabled for this project.' },
      { status: 503, headers: corsHeaders },
    );
  }

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  if ((auth.user as { is_anonymous?: unknown }).is_anonymous !== true) {
    return forbidden('This endpoint is available only to anonymous synthetic demo sessions.');
  }

  try {
    const request = requireDemoRequest(await req.json());
    if (!await consumeQuota(auth.serviceClient, auth.user.id)) {
      return Response.json(
        { error: 'The synthetic demo request limit has been reached. Please try again later.' },
        { status: 429, headers: corsHeaders },
      );
    }
    const apiKey = Deno.env.get('GROQ_API_KEY');
    if (!apiKey) return internalError('Synthetic demo visual generation is not configured.');

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    let response: Response;
    try {
      response = await fetch(`${groqBaseUrl.replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        signal: controller.signal,
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: Deno.env.get('GROQ_MODEL') ?? 'openai/gpt-oss-20b',
          temperature: 0.2,
          max_tokens: 300,
          response_format: { type: 'json_schema', json_schema: sceneSchema(request.motionAllowed) },
          messages: [
            {
              role: 'system',
              content: 'Create a calm, non-verbal play layout from the fixed fictional demo settings. Return only the requested JSON. Never include text, scores, people, faces, brands, copyrighted characters, weapons, unsafe content, or assessment claims.',
            },
            {
              role: 'user',
              content: JSON.stringify({
                fictional_world: request.scenarioId,
                layer: request.layer,
                motion_allowed: request.motionAllowed,
              }),
            },
          ],
        }),
      });
    } finally {
      clearTimeout(timeout);
    }
    if (!response.ok) {
      console.error('[generate-demo-visual-scene] Groq request failed:', response.status);
      return internalError('Synthetic demo visual scene could not be prepared.');
    }
    const result = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    const content = result.choices?.[0]?.message?.content;
    if (!content) return internalError('Synthetic demo visual scene could not be prepared.');
    return ok({ scene: parseScene(JSON.parse(content), request), source: 'groq-demo' });
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    console.error('[generate-demo-visual-scene] unexpected error');
    return internalError('Synthetic demo visual scene could not be prepared.');
  }
});
