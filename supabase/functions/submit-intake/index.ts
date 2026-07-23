import { corsHeaders, requireAuth, badRequest, ok, internalError } from '../_shared/auth.ts';
import { writeAudit } from '../_shared/audit.ts';
import {
  ValidationError,
  requireString,
  requireUuid,
  requireOwnership,
  requireVerifiedGuardian,
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

const audioFeedbackValues = new Set(['mutedHaptics', 'calm', 'rhythmic']);
const toleranceValues = new Set(['low', 'medium', 'high']);
const interactionValues = new Set(['tapping', 'swiping', 'dragging']);
const communicationValues = new Set(['shortLiteral', 'visualSteps', 'symbolsOrAac']);
const sandboxValues = new Set(['calendar', 'constellation']);
const triggerValues = new Set([
  'timers',
  'loudAudio',
  'brightScreens',
  'busyScreens',
  'complexText',
  'unexpectedChanges',
]);
const familiarColorValues = new Set(['red', 'orange', 'yellow', 'green', 'blue', 'purple', 'pink']);
const visualStyleValues = new Set(['simpleShapes', 'illustratedObjects', 'realWorldObjects']);
const avoidableVisualValues = new Set(['faces', 'eyes', 'foodImages', 'crowdedGroups']);

function requireEnum(
  value: unknown,
  field: string,
  allowed: Set<string>,
): string {
  if (typeof value !== 'string' || !allowed.has(value)) {
    throw new ValidationError(`${field} is invalid.`);
  }
  return value;
}

function optionalString(value: unknown, field: string, maxLength: number): string {
  if (value === undefined || value === null) return '';
  if (typeof value !== 'string' || value.trim().length > maxLength) {
    throw new ValidationError(`${field} is invalid.`);
  }
  return value.trim();
}

function enumList(value: unknown, field: string, allowed: Set<string>): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > allowed.size) {
    throw new ValidationError(`${field} is invalid.`);
  }
  const items = [...new Set(value.map((item) => requireEnum(item, field, allowed)))].sort();
  if (items.length !== value.length) {
    throw new ValidationError(`${field} must not contain duplicates.`);
  }
  return items;
}

function validateExplorationPreferences(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ValidationError('explorationPreferences must be an object.');
  }
  const raw = value as Record<string, unknown>;
  const audioLimit = Number(raw.audio_limit);
  if (!Number.isInteger(audioLimit) || audioLimit < 0 || audioLimit > 100) {
    throw new ValidationError('audio_limit must be an integer between 0 and 100.');
  }
  const hyperFocusTheme = requireString(raw.hyper_focus_theme, 'hyper_focus_theme', 80);
  const rawTriggers = raw.known_triggers;
  if (!Array.isArray(rawTriggers) || rawTriggers.length > triggerValues.size) {
    throw new ValidationError('known_triggers is invalid.');
  }
  const knownTriggers = [...new Set(rawTriggers.map((trigger) =>
    requireEnum(trigger, 'known_triggers', triggerValues)
  ))].sort();
  if (knownTriggers.length !== rawTriggers.length) {
    throw new ValidationError('known_triggers must not contain duplicates.');
  }

  return {
    schema_version: 2,
    audio_limit: audioLimit,
    audio_feedback_preference: requireEnum(
      raw.audio_feedback_preference,
      'audio_feedback_preference',
      audioFeedbackValues,
    ),
    visual_clutter_tolerance: requireEnum(
      raw.visual_clutter_tolerance,
      'visual_clutter_tolerance',
      toleranceValues,
    ),
    brightness_tolerance: requireEnum(
      raw.brightness_tolerance,
      'brightness_tolerance',
      toleranceValues,
    ),
    motion_tolerance: requireEnum(
      raw.motion_tolerance,
      'motion_tolerance',
      toleranceValues,
    ),
    interaction_preference: requireEnum(
      raw.interaction_preference,
      'interaction_preference',
      interactionValues,
    ),
    visual_repetition_helpful: raw.visual_repetition_helpful === true,
    communication_preference: requireEnum(
      raw.communication_preference,
      'communication_preference',
      communicationValues,
    ),
    known_triggers: knownTriggers,
    hyper_focus_theme: hyperFocusTheme,
    sandbox_preference: requireEnum(
      raw.sandbox_preference,
      'sandbox_preference',
      sandboxValues,
    ),
    favourite_objects: optionalString(raw.favourite_objects, 'favourite_objects', 120),
    familiar_scenes: optionalString(raw.familiar_scenes, 'familiar_scenes', 100),
    familiar_colors: enumList(raw.familiar_colors, 'familiar_colors', familiarColorValues),
    visual_style_preference: raw.visual_style_preference === undefined
      ? 'illustratedObjects'
      : requireEnum(raw.visual_style_preference, 'visual_style_preference', visualStyleValues),
    avoidable_visual_elements: enumList(
      raw.avoidable_visual_elements,
      'avoidable_visual_elements',
      avoidableVisualValues,
    ),
  };
}

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

    // Business-rule checks
    await requireOwnership(db, guardianId, childId);
    await requireVerifiedGuardian(db, guardianId);
    await requireActiveConsent(db, guardianId);

    if (body.explorationPreferences !== undefined) {
      const configuration = validateExplorationPreferences(body.explorationPreferences);
      const expiresAt = new Date(Date.now() + RETENTION_DAYS * 86_400_000).toISOString();
      const { data, error } = await db
        .from('guardian_exploration_preferences')
        .upsert({
          child_id: childId,
          guardian_id: guardianId,
          configuration,
          expires_at: expiresAt,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'child_id' })
        .select('child_id, expires_at, created_at, updated_at')
        .single();

      if (error) {
        console.error('[submit-intake] preferences db error:', error.message);
        return internalError('Preferences could not be saved. Please try again.');
      }

      await writeAudit({
        action: 'save_exploration_preferences',
        guardianId,
        childId,
        meta: { expires_at: data.expires_at },
      });
      return ok({
        childId: data.child_id,
        expiresAt: data.expires_at,
        createdAt: data.created_at,
        updatedAt: data.updated_at,
      });
    }

    const rawText = requireString(body.text, 'text', MAX_TEXT);

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
