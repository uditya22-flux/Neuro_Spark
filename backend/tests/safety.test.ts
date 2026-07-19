import { describe, expect, it } from 'vitest';
import { assertSafeChildExperience } from '../src/domain/childExperience';
import { FakeLlmProvider } from '../src/services/llm';
import { redactPii, safeguardingReason } from '../src/services/pii';

describe('child-facing and intake safety', () => {
  it('removes direct identifiers before fake AI processing', () => {
    expect(redactPii('Call 9876543210 or hello@example.com')).not.toContain('9876543210');
  });
  it('routes safeguarding phrases away from sensory inference', () => {
    expect(safeguardingReason('I am unsafe at home')).toBeTruthy();
  });
  it('rejects prohibited content from ChildExperience', () => {
    expect(() => assertSafeChildExperience({ sessionId: 'x', layer: 1, track: 'calendar-genius', sensory: { soundEnabled: false, hapticsEnabled: false, reducedMotion: true, theme: 'calm', contrast: 'standard' }, puzzle: { kind: 'calendar-order', prompt: 'Choose a career', cards: [] }, celebration: 'Nice work', canSkip: true, canPause: true })).toThrow(/prohibited/i);
  });
  it('fake provider produces a schema-safe child reveal', async () => {
    await expect(new FakeLlmProvider().createChildReveal('CALENDAR_GENIUS')).resolves.toMatchObject({ title: expect.any(String) });
  });
});
