const SAFEGUARDING_PATTERNS: Array<[string, RegExp]> = [
  ['immediate-danger', /\b(being hurt|hurt me|hurt him|hurt her|unsafe at home)\b/i],
  ['self-harm-concern', /\b(kill myself|suicide|self harm|self-harm)\b/i],
  ['abuse-concern', /\b(abuse|molest|touching me|hit me)\b/i],
];

export function redactPii(input: string): string {
  return input
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email removed]')
    .replace(/\b(?:\+?91[\s-]?)?[6-9]\d{9}\b/g, '[phone removed]')
    .replace(/\b\d{12}\b/g, '[identifier removed]')
    .replace(/\b\d{1,5}\s+[A-Za-z][A-Za-z\s]{2,}\b/g, '[address removed]');
}

export function safeguardingReason(input: string): string | null {
  return SAFEGUARDING_PATTERNS.find(([, pattern]) => pattern.test(input))?.[0] ?? null;
}
