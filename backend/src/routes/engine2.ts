import { Engine2Phase, Engine2SessionStatus, Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { authenticate, HttpError, requiredRouteParam, requireChildAccess, requireRole } from '../auth/middleware';
import { prisma } from '../lib/prisma';
import { asyncRoute, parseBody } from './helpers';
import { childQuestion, engine2QuestionsSchema, type Engine2Question } from '../domain/engine2';
import { completeEngine2Session, finishBaselineAndCreateAdaptive, prepareEngine2Baseline } from '../services/engine2';
import { writeAudit } from '../services/audit';

const submitSchema = z.object({ questionId: z.string().min(1).max(64), optionIds: z.array(z.string().min(1).max(64)).min(1).max(4), clientSubmissionId: z.string().uuid() }).strict();
const skipSchema = z.object({ questionId: z.string().min(1).max(64), clientSubmissionId: z.string().uuid() }).strict();

function sessionQuestions(value: Prisma.JsonValue): Engine2Question[] { return engine2QuestionsSchema.parse(value); }
function childSet(session: { id: string; phase: Engine2Phase; status: Engine2SessionStatus; cursor: number; pauseOrSkipRun: number; questionSet: { questions: Prisma.JsonValue } }) {
  const questions = sessionQuestions(session.questionSet.questions);
  const start = session.cursor;
  return { sessionId: session.id, phase: session.phase, status: session.status, progress: { completed: start, total: questions.length, setSize: Math.min(7, Math.max(0, questions.length - start)) }, canPause: true, canSkip: true, cooldown: session.pauseOrSkipRun >= 3, questions: questions.slice(start, start + 7).map(childQuestion) };
}

async function currentSession(childId: string, sessionId: string) {
  const session = await prisma.engine2Session.findFirst({ where: { id: sessionId, childId }, include: { questionSet: true } });
  if (!session) throw new HttpError(404, 'Engine 2 session was not found', 'not_found');
  if (session.expiresAt <= new Date()) {
    await prisma.engine2Session.update({ where: { id: session.id }, data: { status: Engine2SessionStatus.EXPIRED } });
    throw new HttpError(410, 'This exploration session has expired', 'expired_session');
  }
  if (session.status === Engine2SessionStatus.REVOKED) throw new HttpError(401, 'This exploration session is no longer active', 'revoked_session');
  return session;
}

export const engine2Router = Router();
engine2Router.use(authenticate, requireChildAccess);

engine2Router.post('/children/:childId/engine-2/question-sets', requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const set = await prepareEngine2Baseline(childId);
  await writeAudit({ principal: request.principal!, action: 'engine2.baseline_prepared', childId, metadata: { questionSetId: set.id, fallbackUsed: set.fallbackUsed } });
  response.status(201).json({ questionSetId: set.id, stage: set.stage, questionCount: (set.questions as unknown[]).length, fallbackUsed: set.fallbackUsed });
}));

engine2Router.post('/children/:childId/engine-2/sessions', requireRole('guardian', 'child'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const existing = await prisma.engine2Session.findFirst({ where: { childId, status: { in: [Engine2SessionStatus.ACTIVE, Engine2SessionStatus.PAUSED] }, expiresAt: { gt: new Date() } }, include: { questionSet: true }, orderBy: { updatedAt: 'desc' } });
  if (existing) return response.json(childSet(existing));
  const set = request.principal!.role === 'guardian'
    ? await prepareEngine2Baseline(childId)
    : await prisma.engine2QuestionSet.findFirst({ where: { childId, stage: Engine2Phase.BASELINE }, orderBy: { createdAt: 'desc' } });
  if (!set) throw new HttpError(409, 'A guardian must prepare this exploration first', 'baseline_not_prepared');
  const session = await prisma.engine2Session.create({ data: { childId, questionSetId: set.id, expiresAt: set.expiresAt }, include: { questionSet: true } });
  await writeAudit({ principal: request.principal!, action: 'engine2.session_started', childId, metadata: { sessionId: session.id } });
  response.status(201).json(childSet(session));
}));

engine2Router.get('/children/:childId/engine-2/sessions/:sessionId/current', requireRole('child'), asyncRoute(async (request, response) => {
  const session = await currentSession(requiredRouteParam(request.params.childId, 'childId'), requiredRouteParam(request.params.sessionId, 'sessionId'));
  response.json(childSet(session));
}));

async function acknowledge(request: import('express').Request, kind: 'answer' | 'skip') {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const sessionId = requiredRouteParam(request.params.sessionId, 'sessionId');
  const body = parseBody(kind === 'answer' ? submitSchema : skipSchema, request.body);
  const session = await currentSession(childId, sessionId);
  if (session.status !== Engine2SessionStatus.ACTIVE) throw new HttpError(409, 'Resume before continuing', 'session_paused');
  const questions = sessionQuestions(session.questionSet.questions);
  const expected = questions[session.cursor];
  if (!expected || expected.id !== body.questionId) throw new HttpError(409, 'That question is not currently available', 'question_out_of_order');
  const optionIds = kind === 'answer' ? (body as z.infer<typeof submitSchema>).optionIds : [];
  if (kind === 'answer' && (optionIds.some((id) => !expected.options.some((option) => option.id === id)) || (expected.interactionType !== 'multiChoice' && optionIds.length !== 1))) throw new HttpError(400, 'That option is not available for this question', 'invalid_option');
  const prior = await prisma.engine2Answer.findFirst({ where: { sessionId, OR: [{ clientSubmissionId: body.clientSubmissionId }, { questionId: body.questionId }] } });
  if (prior) {
    const matches = prior.questionId === body.questionId && prior.skipped === (kind === 'skip') && JSON.stringify(prior.optionIds) === JSON.stringify(optionIds);
    if (!matches) throw new HttpError(409, 'This submission conflicts with an acknowledged answer', 'conflicting_submission');
    return { duplicate: true, session: await currentSession(childId, sessionId) };
  }
  const updated = await prisma.$transaction(async (tx) => {
    await tx.engine2Answer.create({ data: { sessionId, questionId: body.questionId, optionIds, skipped: kind === 'skip', clientSubmissionId: body.clientSubmissionId } });
    return tx.engine2Session.update({ where: { id: sessionId }, data: { cursor: { increment: 1 }, pauseOrSkipRun: kind === 'skip' ? { increment: 1 } : 0 }, include: { questionSet: true } });
  });
  return { duplicate: false, session: updated };
}

engine2Router.post('/children/:childId/engine-2/sessions/:sessionId/answers', requireRole('child'), asyncRoute(async (request, response) => {
  const result = await acknowledge(request, 'answer');
  response.status(result.duplicate ? 200 : 201).json(childSet(result.session));
}));
engine2Router.post('/children/:childId/engine-2/sessions/:sessionId/skips', requireRole('child'), asyncRoute(async (request, response) => {
  const result = await acknowledge(request, 'skip');
  response.status(result.duplicate ? 200 : 201).json(childSet(result.session));
}));

engine2Router.post('/children/:childId/engine-2/sessions/:sessionId/pause', requireRole('child'), asyncRoute(async (request, response) => {
  const session = await currentSession(requiredRouteParam(request.params.childId, 'childId'), requiredRouteParam(request.params.sessionId, 'sessionId'));
  const paused = await prisma.engine2Session.update({ where: { id: session.id }, data: { status: Engine2SessionStatus.PAUSED, pausedAt: new Date(), pauseOrSkipRun: { increment: 1 } }, include: { questionSet: true } });
  response.json(childSet(paused));
}));
engine2Router.post('/children/:childId/engine-2/sessions/:sessionId/resume', requireRole('child', 'guardian'), asyncRoute(async (request, response) => {
  const session = await currentSession(requiredRouteParam(request.params.childId, 'childId'), requiredRouteParam(request.params.sessionId, 'sessionId'));
  const resumed = await prisma.engine2Session.update({ where: { id: session.id }, data: { status: Engine2SessionStatus.ACTIVE, pausedAt: null }, include: { questionSet: true } });
  response.json(childSet(resumed));
}));

engine2Router.post('/children/:childId/engine-2/sessions/:sessionId/adaptive', requireRole('guardian', 'child'), asyncRoute(async (request, response) => {
  const session = await currentSession(requiredRouteParam(request.params.childId, 'childId'), requiredRouteParam(request.params.sessionId, 'sessionId'));
  const count = await prisma.engine2Answer.count({ where: { sessionId: session.id } });
  if (session.phase !== Engine2Phase.BASELINE || count < (session.questionSet.questions as unknown[]).length) throw new HttpError(409, 'Complete the baseline before follow-up questions', 'baseline_incomplete');
  response.json(await finishBaselineAndCreateAdaptive(session.id));
}));

engine2Router.post('/children/:childId/engine-2/sessions/:sessionId/complete', requireRole('guardian', 'child'), asyncRoute(async (request, response) => {
  const session = await currentSession(requiredRouteParam(request.params.childId, 'childId'), requiredRouteParam(request.params.sessionId, 'sessionId'));
  const count = await prisma.engine2Answer.count({ where: { sessionId: session.id } });
  if (session.phase !== Engine2Phase.ADAPTIVE || count < (session.questionSet.questions as unknown[]).length) throw new HttpError(409, 'Finish the available questions first', 'session_incomplete');
  response.json(await completeEngine2Session(session.id));
}));

engine2Router.get('/children/:childId/engine-2/sessions/:sessionId/progress', requireRole('guardian', 'child'), asyncRoute(async (request, response) => {
  const session = await currentSession(requiredRouteParam(request.params.childId, 'childId'), requiredRouteParam(request.params.sessionId, 'sessionId'));
  response.json({ sessionId: session.id, phase: session.phase, status: session.status, completed: session.cursor, total: (session.questionSet.questions as unknown[]).length, canPause: true, canSkip: true });
}));

engine2Router.get('/children/:childId/engine-2/profiles/latest', requireRole('guardian', 'care_provider'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const profile = await prisma.engine2ObservedProfile.findFirst({ where: { childId }, orderBy: { createdAt: 'desc' } });
  if (!profile) throw new HttpError(404, 'No observed profile is available yet', 'not_found');
  response.json({ profileVersion: profile.profileVersion, schemaVersion: profile.schemaVersion, observations: profile.observations, evidence: profile.evidence, provenance: profile.provenance, disclaimer: 'These are observations from this exploration, not a diagnosis, screening result, comparison, prediction, or clinical advice.', createdAt: profile.createdAt });
}));
engine2Router.get('/children/:childId/engine-2/reveal/latest', requireRole('child'), asyncRoute(async (request, response) => {
  const profile = await prisma.engine2ObservedProfile.findFirst({ where: { childId: requiredRouteParam(request.params.childId, 'childId') }, orderBy: { createdAt: 'desc' } });
  if (!profile) throw new HttpError(404, 'No warm reflection is available yet', 'not_found');
  response.json(profile.childReveal);
}));
