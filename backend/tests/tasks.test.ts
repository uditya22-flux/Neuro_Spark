import { describe, expect, it } from 'vitest';
import { buildExperience, evaluateFrictionCircuitBreaker } from '../src/services/tasks';

describe('deterministic accessible tasks', () => {
  it('creates the same bounded puzzle for the same seed', () => {
    const input = { sessionId: 'session', seed: 'stable-seed', track: 'CALENDAR_GENIUS' as const, layer: 99, sensory: {} };
    expect(buildExperience(input)).toEqual(buildExperience(input));
    expect(buildExperience(input).layer).toBe(10);
  });
  it('opens a neutral cooldown only after a repeated pause or skip pattern', () => {
    expect(evaluateFrictionCircuitBreaker([{ kind: 'PAUSE_REQUESTED' }, { kind: 'PAUSE_REQUESTED' }, { kind: 'PAUSE_REQUESTED' }])).toMatchObject({ shouldOfferCooldown: true });
    expect(evaluateFrictionCircuitBreaker([{ kind: 'TASK_COMPLETED' }, { kind: 'TASK_SKIPPED' }, { kind: 'TASK_SKIPPED' }])).toMatchObject({ shouldOfferCooldown: false });
  });
});
