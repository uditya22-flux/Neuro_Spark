import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ---------------------------------------------------------------------------
// Validation error
// ---------------------------------------------------------------------------

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

// ---------------------------------------------------------------------------
// Primitive validators
// ---------------------------------------------------------------------------

export function requireString(
  value: unknown,
  field: string,
  maxLen = 500,
  minLen = 1,
): string {
  if (typeof value !== 'string' || value.trim().length < minLen) {
    throw new ValidationError(`${field} is required and must be a non-empty string.`);
  }
  if (value.trim().length > maxLen) {
    throw new ValidationError(`${field} must be at most ${maxLen} characters.`);
  }
  return value.trim();
}

export function requireInt(
  value: unknown,
  field: string,
  min: number,
  max: number,
): number {
  const n = Number(value);
  if (!Number.isInteger(n)) {
    throw new ValidationError(`${field} must be an integer.`);
  }
  if (n < min || n > max) {
    throw new ValidationError(`${field} must be between ${min} and ${max}.`);
  }
  return n;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function requireUuid(value: unknown, field: string): string {
  if (typeof value !== 'string' || !UUID_RE.test(value)) {
    throw new ValidationError(`${field} must be a valid UUID.`);
  }
  return value;
}

export function optionalUuid(value: unknown, field: string): string | null {
  if (value === undefined || value === null || value === '') return null;
  return requireUuid(value, field);
}

// ---------------------------------------------------------------------------
// Business-rule validators (DB queries)
// ---------------------------------------------------------------------------

/**
 * Confirms that the given child belongs to the given guardian.
 * Throws ValidationError (403-class) if not found.
 */
export async function requireOwnership(
  db: SupabaseClient,
  guardianId: string,
  childId: string,
): Promise<void> {
  const { data, error } = await db
    .from('children')
    .select('id')
    .eq('id', childId)
    .eq('guardian_id', guardianId)
    .maybeSingle();
  if (error || !data) {
    throw new ValidationError('Child not found or does not belong to this guardian.');
  }
}

/**
 * Confirms the guardian has at least one active consent record.
 * Throws ValidationError if consent is missing or revoked.
 */
export async function requireActiveConsent(
  db: SupabaseClient,
  guardianId: string,
): Promise<void> {
  const { data, error } = await db
    .from('guardian_consents')
    .select('id')
    .eq('guardian_id', guardianId)
    .eq('status', 'active')
    .maybeSingle();
  if (error || !data) {
    throw new ValidationError(
      'Active consent is required. Please accept the current consent version.',
    );
  }
}

/**
 * Confirms the guardian has a verified parent_verification record.
 * Throws ValidationError if verification is missing or not verified.
 */
export async function requireVerifiedGuardian(
  db: SupabaseClient,
  guardianId: string,
): Promise<void> {
  const { data, error } = await db
    .from('parent_verifications')
    .select('id')
    .eq('guardian_id', guardianId)
    .eq('status', 'verified')
    .maybeSingle();
  if (error || !data) {
    throw new ValidationError(
      'Guardian identity verification is required before this action.',
    );
  }
}

/**
 * Confirms a session exists, belongs to the given guardian,
 * has not expired, and has not been revoked.
 */
export async function requireActiveSession(
  db: SupabaseClient,
  guardianId: string,
  sessionId: string,
): Promise<{ child_id: string }> {
  const { data, error } = await db
    .from('sessions')
    .select('id, child_id, expires_at, revoked_at')
    .eq('id', sessionId)
    .eq('guardian_id', guardianId)
    .maybeSingle();

  if (error || !data) {
    throw new ValidationError('Session not found or does not belong to this guardian.');
  }
  if (data.revoked_at) {
    throw new ValidationError('Session has been revoked.');
  }
  if (new Date(data.expires_at) < new Date()) {
    throw new ValidationError('Session has expired.');
  }
  return { child_id: data.child_id };
}
