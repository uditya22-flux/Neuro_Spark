import { badRequest, corsHeaders, internalError, ok, requireAuth } from '../_shared/auth.ts';
import {
  requireActiveConsent,
  requireOwnership,
  requireUuid,
  requireVerifiedGuardian,
  ValidationError,
} from '../_shared/validate.ts';

const groqBaseUrl = Deno.env.get('GROQ_BASE_URL') ?? 'https://api.groq.com/openai/v1';
const sceneTypes = new Set(['match', 'sort', 'connect', 'sequence', 'route', 'rotate']);
const styles = new Set(['simpleShapes', 'illustratedObjects', 'realWorldObjects']);
const colors = new Set(['red', 'orange', 'yellow', 'green', 'blue', 'purple', 'pink', 'silver']);
const actions = new Set(['none', 'slide', 'roll', 'rotate', 'snap', 'gentlePulse']);

type Preferences = {
  hyper_focus_theme?: unknown;
  favourite_objects?: unknown;
  familiar_scenes?: unknown;
  familiar_colors?: unknown;
  visual_style_preference?: unknown;
  motion_tolerance?: unknown;
  known_triggers?: unknown;
};

function boundedText(value: unknown, limit: number): string {
  return typeof value === 'string' ? value.trim().slice(0, limit) : '';
}

function stringList(value: unknown, allowed: Set<string>): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === 'string' && allowed.has(item));
}

function parseScene(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ValidationError('Generated scene is invalid.');
  }
  const raw = value as Record<string, unknown>;
  const sceneType = typeof raw.scene_type === 'string' ? raw.scene_type : '';
  const subject = typeof raw.subject === 'string' ? raw.subject : '';
  const objectStyle = typeof raw.object_style === 'string' ? raw.object_style : '';
  const itemCount = typeof raw.item_count === 'number' ? raw.item_count : Number.NaN;
  const animation = raw.animation;
  if (!sceneTypes.has(sceneType) || !/^[a-z0-9_]{3,60}$/.test(subject) ||
      !styles.has(objectStyle) || !Number.isInteger(itemCount) || itemCount < 3 || itemCount > 5 ||
      !animation || typeof animation !== 'object' || Array.isArray(animation)) {
    throw new ValidationError('Generated scene did not match the safe schema.');
  }
  const animationRaw = animation as Record<string, unknown>;
  const onTap = typeof animationRaw.on_tap === 'string' ? animationRaw.on_tap : '';
  const success = typeof animationRaw.success === 'string' ? animationRaw.success : '';
  if (!actions.has(onTap) || !actions.has(success)) {
    throw new ValidationError('Generated animation is invalid.');
  }
  return {
    scene_type: sceneType,
    subject,
    palette: stringList(raw.palette, colors).slice(0, 3),
    object_style: objectStyle,
    layout: typeof raw.layout === 'string' && ['leftToRight', 'grid', 'path'].includes(raw.layout)
        ? raw.layout
        : 'grid',
    item_count: itemCount,
    animation: { on_tap: onTap, success },
    show_text: false,
  };
}

function sceneSchema(motionAllowed: boolean): Record<string, unknown> {
  return {
    name: 'mindbridge_visual_scene',
    strict: true,
    schema: {
      type: 'object',
      additionalProperties: false,
      required: ['scene_type', 'subject', 'palette', 'object_style', 'layout', 'item_count', 'animation'],
      properties: {
        scene_type: { type: 'string', enum: [...sceneTypes] },
        subject: { type: 'string', pattern: '^[a-z0-9_]{3,60}$' },
        palette: { type: 'array', items: { type: 'string', enum: [...colors] }, minItems: 0, maxItems: 3 },
        object_style: { type: 'string', enum: [...styles] },
        layout: { type: 'string', enum: ['leftToRight', 'grid', 'path'] },
        item_count: { type: 'integer', minimum: 3, maximum: 5 },
        animation: {
          type: 'object',
          additionalProperties: false,
          required: ['on_tap', 'success'],
          properties: {
            on_tap: { type: 'string', enum: motionAllowed ? [...actions] : ['none'] },
            success: { type: 'string', enum: motionAllowed ? [...actions] : ['none'] },
          },
        },
      },
    },
  };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return badRequest('POST is required.');
  if (Deno.env.get('ALLOW_CLOUD_VISUAL_GENERATION') !== 'true') {
    return Response.json(
      { error: 'Cloud visual generation is not enabled for this project.' },
      { status: 503, headers: corsHeaders },
    );
  }

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  try {
    const body = await req.json() as Record<string, unknown>;
    const childId = requireUuid(body.childId, 'childId');
    const layer = Number(body.layer);
    if (!Number.isInteger(layer) || layer < 1 || layer > 10) {
      return badRequest('layer must be an integer from 1 to 10.');
    }
    await requireOwnership(auth.userClient, auth.guardianId, childId);
    await requireVerifiedGuardian(auth.userClient, auth.guardianId);
    await requireActiveConsent(auth.userClient, auth.guardianId);

    const { data, error } = await auth.userClient
      .from('guardian_exploration_preferences')
      .select('configuration')
      .eq('child_id', childId)
      .maybeSingle();
    if (error || !data) return badRequest('Guardian preferences are required.');

    const preferences = data.configuration as Preferences;
    const theme = boundedText(preferences.hyper_focus_theme, 80);
    if (!theme) return badRequest('A visual theme is required.');
    const motionAllowed = preferences.motion_tolerance !== 'low' &&
      !stringList(preferences.known_triggers, new Set(['unexpectedChanges'])).includes('unexpectedChanges');
    const apiKey = Deno.env.get('GROQ_API_KEY');
    if (!apiKey) return internalError('Visual generation is not configured.');

    const safePreferences = {
      theme,
      favourite_objects: boundedText(preferences.favourite_objects, 120),
      familiar_scenes: boundedText(preferences.familiar_scenes, 100),
      familiar_colors: stringList(preferences.familiar_colors, colors),
      visual_style: styles.has(String(preferences.visual_style_preference))
        ? preferences.visual_style_preference
        : 'illustratedObjects',
      motion_allowed: motionAllowed,
      layer,
    };
    const response = await fetch(`${groqBaseUrl.replace(/\/$/, '')}/chat/completions`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: Deno.env.get('GROQ_MODEL') ?? 'openai/gpt-oss-20b',
        temperature: 0.2,
        response_format: { type: 'json_schema', json_schema: sceneSchema(motionAllowed) },
        messages: [
          {
            role: 'system',
            content: 'Create a non-verbal child play scene. Return only the schema. Never include text, scores, diagnosis, assessment claims, people, faces, brands, copyrighted characters, weapons, or unsafe content.',
          },
          { role: 'user', content: JSON.stringify(safePreferences) },
        ],
      }),
    });
    if (!response.ok) {
      console.error('[generate-visual-scene] Groq error:', response.status);
      return internalError('Visual scene could not be prepared.');
    }
    const result = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    const content = result.choices?.[0]?.message?.content;
    if (!content) return internalError('Visual scene could not be prepared.');
    return ok({ scene: parseScene(JSON.parse(content)), source: 'groq' });
  } catch (error) {
    if (error instanceof ValidationError) return badRequest(error.message);
    console.error('[generate-visual-scene] unexpected error');
    return internalError('Visual scene could not be prepared.');
  }
});
