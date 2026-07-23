import { Engine2Phase, Engine2SessionStatus, Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { createLlmProvider } from './llm';
import { ENGINE2_DOMAINS, ENGINE2_OBSERVED_PROFILE_DISCLAIMER, ENGINE2_PROMPT_VERSION, ENGINE2_SCHEMA_VERSION, type Engine2Domain, type Engine2Question, validateAdaptiveQuestions, validateBaselineQuestions } from '../domain/engine2';
import { safeEngine2Fallback } from './llm';
import { daysFromNow } from '../lib/dates';

const json = (value: unknown) => value as Prisma.InputJsonValue;

async function generationContext(childId: string) {
  const child = await prisma.childProfile.findUnique({ where: { id: childId }, select: { birthYear: true } });
  if (!child) throw new Error('Child profile was not found');
  const intake = await prisma.intake.findFirst({ where: { childId, expiresAt: { gt: new Date() } }, orderBy: { createdAt: 'desc' }, select: { id: true, redactedText: true, createdAt: true } });
  const sensory = await prisma.activeSensoryConfiguration.findFirst({ where: { childId, active: true }, orderBy: { activatedAt: 'desc' }, select: { id: true, configuration: true, configVersion: true } });
  return {
    age: Math.max(7, Math.min(12, new Date().getFullYear() - child.birthYear)),
    redactedContext: intake?.redactedText ?? '',
    sensory: (sensory?.configuration ?? {}) as Record<string, unknown>,
    provenance: { intakeId: intake?.id ?? null, redactedAt: intake?.createdAt.toISOString() ?? null, sensoryConfigId: sensory?.id ?? null, sensoryConfigVersion: sensory?.configVersion ?? null },
  };
}

async function validatedBaseline(context: Awaited<ReturnType<typeof generationContext>>) {
  const provider = createLlmProvider();
  try {
    return { questions: validateBaselineQuestions(await provider.createEngine2Baseline(context)), provider, fallbackUsed: false };
  } catch {
    try {
      return { questions: validateBaselineQuestions(await provider.createEngine2Baseline(context)), provider, fallbackUsed: false };
    } catch {
      return { questions: safeEngine2Fallback(context.age), provider, fallbackUsed: true };
    }
  }
}

export async function prepareEngine2Baseline(childId: string) {
  const current = await prisma.engine2QuestionSet.findFirst({ where: { childId, stage: Engine2Phase.BASELINE }, orderBy: { createdAt: 'desc' } });
  if (current) return current;
  const context = await generationContext(childId);
  const result = await validatedBaseline(context);
  return prisma.engine2QuestionSet.create({ data: {
    childId, stage: Engine2Phase.BASELINE, version: '1', schemaVersion: ENGINE2_SCHEMA_VERSION,
    promptVersion: ENGINE2_PROMPT_VERSION, modelConfig: json(result.provider.modelConfig), redactedProvenance: json(context.provenance), sensorySnapshot: json(context.sensory), questions: json(result.questions), generatedSnapshot: json(result.questions), fallbackUsed: result.fallbackUsed, expiresAt: daysFromNow(90),
  } });
}

export function coverageFor(questions: Engine2Question[], answers: Array<{ questionId: string; skipped: boolean }>) {
  return Object.fromEntries(ENGINE2_DOMAINS.map((domain) => {
    const ids = questions.filter((question) => question.domain === domain).map((question) => question.id);
    const acknowledged = answers.filter((answer) => ids.includes(answer.questionId));
    const answered = acknowledged.filter((answer) => !answer.skipped).length;
    return [domain, { presented: ids.length, answered, skipped: acknowledged.length - answered, coverage: ids.length ? answered / ids.length : 0, uncertainty: ids.length ? 1 - (answered / ids.length) : 1 }];
  }));
}

export async function finishBaselineAndCreateAdaptive(sessionId: string) {
  const session = await prisma.engine2Session.findUnique({ where: { id: sessionId }, include: { questionSet: true, answers: true, child: { select: { id: true } } } });
  if (!session) throw new Error('Engine 2 session was not found');
  const baseline = session.questionSet.questions as unknown as Engine2Question[];
  const evidence = coverageFor(baseline, session.answers);
  const needed = ENGINE2_DOMAINS.filter((domain) => (evidence[domain] as { coverage: number }).coverage < 0.6);
  if (!needed.length) return completeEngine2Session(session.id, evidence);
  const existing = await prisma.engine2QuestionSet.findFirst({ where: { childId: session.childId, stage: Engine2Phase.ADAPTIVE }, orderBy: { createdAt: 'desc' } });
  const set = existing ?? await createAdaptiveSet(session.childId, needed);
  await prisma.engine2Session.update({ where: { id: session.id }, data: { phase: Engine2Phase.ADAPTIVE, questionSetId: set.id, cursor: 0, pauseOrSkipRun: 0, status: Engine2SessionStatus.ACTIVE } });
  return { phase: 'ADAPTIVE' as const, evidence, questionSetId: set.id };
}

async function createAdaptiveSet(childId: string, neededDomains: Engine2Domain[]) {
  const context = await generationContext(childId);
  const provider = createLlmProvider();
  let questions: Engine2Question[];
  let fallbackUsed = false;
  try { questions = validateAdaptiveQuestions(await provider.createEngine2FollowUps({ ...context, neededDomains }), neededDomains); }
  catch { try { questions = validateAdaptiveQuestions(await provider.createEngine2FollowUps({ ...context, neededDomains }), neededDomains); } catch { questions = safeEngine2Fallback(context.age, neededDomains); fallbackUsed = true; } }
  return prisma.engine2QuestionSet.create({ data: { childId, stage: Engine2Phase.ADAPTIVE, version: '1', schemaVersion: ENGINE2_SCHEMA_VERSION, promptVersion: 'engine2-adaptive-v1', modelConfig: json(provider.modelConfig), redactedProvenance: json(context.provenance), sensorySnapshot: json(context.sensory), questions: json(questions), generatedSnapshot: json(questions), fallbackUsed, expiresAt: daysFromNow(90) } });
}

export async function completeEngine2Session(sessionId: string, initialEvidence?: Record<string, unknown>) {
  const session = await prisma.engine2Session.findUnique({ where: { id: sessionId }, include: { questionSet: true, answers: true } });
  if (!session) throw new Error('Engine 2 session was not found');
  const baseline = session.phase === Engine2Phase.ADAPTIVE
    ? await prisma.engine2QuestionSet.findFirst({ where: { childId: session.childId, stage: Engine2Phase.BASELINE }, orderBy: { createdAt: 'desc' } })
    : null;
  const allQuestions = [
    ...(baseline ? baseline.questions as unknown as Engine2Question[] : []),
    ...session.questionSet.questions as unknown as Engine2Question[],
  ];
  const evidence = initialEvidence ?? coverageFor(allQuestions, session.answers);
  const observations = Object.entries(evidence).map(([domain, value]) => ({ domain, observed: 'The child explored choices in this area.', ...(value as object) }));
  const profile = await prisma.engine2ObservedProfile.upsert({ where: { sessionId }, create: { childId: session.childId, sessionId, profileVersion: '1', schemaVersion: ENGINE2_SCHEMA_VERSION, evidence: json(evidence), observations: json(observations), provenance: json({ questionSetId: session.questionSetId, promptVersion: session.questionSet.promptVersion, schemaVersion: session.questionSet.schemaVersion, redactedProvenance: session.questionSet.redactedProvenance }), childReveal: json({ title: 'Thanks for exploring', message: 'You shared some ways you like to look at ideas. You can take a break or come back another time.' }) }, update: {} });
  await prisma.engine2Session.update({ where: { id: sessionId }, data: { phase: Engine2Phase.COMPLETE, status: Engine2SessionStatus.COMPLETE, completedAt: new Date() } });
  return { phase: 'COMPLETE' as const, evidence, profile, disclaimer: ENGINE2_OBSERVED_PROFILE_DISCLAIMER };
}
