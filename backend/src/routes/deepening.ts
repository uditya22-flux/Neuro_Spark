import { randomUUID } from 'node:crypto';
import { EventKind, Track } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { authenticate, HttpError, requiredRouteParam, requireChildAccess, requireRole } from '../auth/middleware';
import { prisma } from '../lib/prisma';
import { asyncRoute, parseBody } from './helpers';
import { buildExperience, evaluateFrictionCircuitBreaker, MAX_LAYER, normalizeSensoryConfiguration } from '../services/tasks';
import { telemetryExpiry } from '../services/privacy';
import { writeAudit } from '../services/audit';

const startSchema = z.object({ track: z.enum(['calendar-genius', 'constellation-mapper']) });
const eventSchema = z.object({
  kind: z.enum(['TASK_OPENED', 'TASK_SKIPPED', 'TASK_COMPLETED', 'PAUSE_REQUESTED', 'COOLDOWN_ENDED']),
  layer: z.number().int().min(1).max(MAX_LAYER),
  payload: z.object({ choiceId: z.string().max(100).optional() }).default({}),
});

async function activeSensory(childId: string): Promise<unknown> {
  const current = await prisma.activeSensoryConfiguration.findFirst({ where: { childId, active: true }, orderBy: { activatedAt: 'desc' } });
  return current?.configuration ?? normalizeSensoryConfiguration({});
}

export const deepeningRouter = Router();
deepeningRouter.use(authenticate, requireChildAccess, requireRole('child'));

deepeningRouter.post('/children/:childId/deepening/sessions', asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const body = parseBody(startSchema, request.body);
  const track: Track = body.track === 'calendar-genius' ? 'CALENDAR_GENIUS' : 'CONSTELLATION_MAPPER';
  const session = await prisma.playSession.create({ data: { childId, track, seed: randomUUID() } });
  const experience = buildExperience({ sessionId: session.id, seed: session.seed, track, layer: 1, sensory: await activeSensory(session.childId) });
  await prisma.playEvent.create({ data: { childId: session.childId, playSessionId: session.id, kind: 'TASK_OPENED', layer: 1, payload: {}, expiresAt: telemetryExpiry() } });
  await writeAudit({ principal: request.principal!, action: 'play.started', childId: session.childId, metadata: { track } });
  response.status(201).json(experience);
}));

deepeningRouter.get('/children/:childId/deepening/sessions/:sessionId/layers/:layer', asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const sessionId = requiredRouteParam(request.params.sessionId, 'sessionId');
  const layer = Number(requiredRouteParam(request.params.layer, 'layer'));
  if (!Number.isInteger(layer) || layer < 1 || layer > MAX_LAYER) throw new HttpError(400, 'Layer is invalid', 'invalid_layer');
  const session = await prisma.playSession.findFirst({ where: { id: sessionId, childId, endedAt: null } });
  if (!session) throw new HttpError(404, 'Play session was not found', 'not_found');
  response.json(buildExperience({ sessionId: session.id, seed: session.seed, track: session.track, layer, sensory: await activeSensory(session.childId) }));
}));

deepeningRouter.post('/children/:childId/deepening/sessions/:sessionId/events', asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const sessionId = requiredRouteParam(request.params.sessionId, 'sessionId');
  const body = parseBody(eventSchema, request.body);
  const session = await prisma.playSession.findFirst({ where: { id: sessionId, childId, endedAt: null } });
  if (!session) throw new HttpError(404, 'Play session was not found', 'not_found');
  const event = await prisma.playEvent.create({ data: { childId: session.childId, playSessionId: session.id, kind: body.kind as EventKind, layer: body.layer, payload: body.payload, expiresAt: telemetryExpiry() } });
  const recent = await prisma.playEvent.findMany({ where: { playSessionId: session.id }, orderBy: { occurredAt: 'desc' }, take: 3, select: { kind: true } });
  const circuit = evaluateFrictionCircuitBreaker([...recent].reverse());
  if (circuit.shouldOfferCooldown) {
    await prisma.playEvent.create({ data: { childId: session.childId, playSessionId: session.id, kind: 'COOLDOWN_STARTED', layer: body.layer, payload: { neutral: true }, expiresAt: telemetryExpiry() } });
  }
  const completed = await prisma.playEvent.count({ where: { childId: session.childId, playSession: { track: session.track }, kind: 'TASK_COMPLETED' } });
  const skipped = await prisma.playEvent.count({ where: { childId: session.childId, playSession: { track: session.track }, kind: 'TASK_SKIPPED' } });
  await prisma.explorationAggregate.upsert({
    where: { childId_track: { childId: session.childId, track: session.track } },
    create: { childId: session.childId, track: session.track, evidence: { completedActivities: completed, skippedActivities: skipped, mostRecentLayer: body.layer }, explorationInProgress: true },
    update: { evidence: { completedActivities: completed, skippedActivities: skipped, mostRecentLayer: body.layer }, explorationInProgress: true, calculatedAt: new Date() },
  });
  response.status(201).json({ eventId: event.id, cooldown: circuit.shouldOfferCooldown ? { available: true, message: 'You can pause in a quiet space whenever you like.' } : { available: false } });
}));

// A transparent alias for the two fixed MVP tracks; no adaptive ranking occurs.
export const sandboxRouter = deepeningRouter;
