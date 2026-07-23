import { describe, expect, it } from 'vitest';
import { ENGINE2_DOMAINS, validateAdaptiveQuestions, validateBaselineQuestions } from '../src/domain/engine2';
import { FakeLlmProvider, safeEngine2Fallback } from '../src/services/llm';
import { coverageFor } from '../src/services/engine2';

describe('Engine 2 generation and evidence boundaries', () => {
  it('generates exactly five validated baseline questions for every versioned domain', async () => {
    const questions = await new FakeLlmProvider().createEngine2Baseline({ age: 10, redactedContext: '[email removed]', sensory: { reducedMotion: true } });
    expect(validateBaselineQuestions(questions)).toHaveLength(30);
    for (const domain of ENGINE2_DOMAINS) expect(questions.filter((question) => question.domain === domain)).toHaveLength(5);
    expect(questions.every((question) => question.options.length >= 3 && question.options.length <= 4)).toBe(true);
  });

  it('rejects duplicate content and prohibited child-facing language', () => {
    const questions = safeEngine2Fallback(9);
    questions[1] = { ...questions[1], prompt: questions[0].prompt };
    expect(() => validateBaselineQuestions(questions)).toThrow(/duplicate/i);
    const unsafe = safeEngine2Fallback(9);
    unsafe[0] = { ...unsafe[0], prompt: 'This is a diagnostic test' };
    expect(() => validateBaselineQuestions(unsafe)).toThrow();
  });

  it('bounds adaptive output and only permits domains needing more exploration', () => {
    const followUps = safeEngine2Fallback(11, ['visual-pattern-reasoning']);
    expect(validateAdaptiveQuestions(followUps, ['visual-pattern-reasoning'])).toHaveLength(6);
    expect(() => validateAdaptiveQuestions(followUps, ['sequencing-and-planning'])).toThrow();
  });

  it('keeps skips neutral while making uncertainty visible', () => {
    const questions = safeEngine2Fallback(10);
    const evidence = coverageFor(questions, [{ questionId: questions[0].id, skipped: true }]);
    expect(evidence['visual-pattern-reasoning']).toMatchObject({ answered: 0, skipped: 1, coverage: 0, uncertainty: 1 });
  });
});
