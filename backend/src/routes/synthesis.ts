import { Router } from 'express';
import { Track } from '@prisma/client';
import { z } from 'zod';
import { authenticate, HttpError, requiredRouteParam, requireChildAccess, requireRole } from '../auth/middleware';
import { prisma } from '../lib/prisma';
import { asyncRoute, parseBody } from './helpers';
import { createLlmProvider } from '../services/llm';
import { ADULT_NOTE_DISCLAIMER } from '../domain/adultExploratoryNote';
import { EXPLORATION_TAXONOMY } from '../domain/taxonomy';
import { writeAudit } from '../services/audit';

const synthesisSchema = z.object({ track: z.enum(['calendar-genius', 'constellation-mapper']) });
export const synthesisRouter = Router();
synthesisRouter.use(authenticate, requireChildAccess);

synthesisRouter.post('/children/:childId/synthesis', requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const body = parseBody(synthesisSchema, request.body);
  const track: Track = body.track === 'calendar-genius' ? 'CALENDAR_GENIUS' : 'CONSTELLATION_MAPPER';
  const aggregate = await prisma.explorationAggregate.findUnique({ where: { childId_track: { childId, track } } });
  const evidence = (aggregate?.evidence ?? { completedActivities: 0, skippedActivities: 0, explorationInProgress: true }) as Record<string, number | string | boolean>;
  const provider = createLlmProvider();
  const [childDraft, adultDraft] = await Promise.all([provider.createChildReveal(track), provider.createAdultNote(track, evidence)]);
  const result = await prisma.$transaction(async (tx) => {
    const childPrompt = await tx.promptVersion.upsert({ where: { key_version: { key: 'child-reveal', version: '1' } }, create: { key: 'child-reveal', version: '1', template: 'Warm non-clinical reflection only.' }, update: {} });
    const adultPrompt = await tx.promptVersion.upsert({ where: { key_version: { key: 'adult-exploratory-note', version: '1' } }, create: { key: 'adult-exploratory-note', version: '1', template: 'Closed taxonomy, illustrative guardian field note.' }, update: {} });
    const childOutput = await tx.llmOutput.create({ data: { childId, promptVersionId: childPrompt.id, channel: 'child_reveal', modelConfig: provider.modelConfig, schemaVersion: '1', content: childDraft } });
    const adultOutput = await tx.llmOutput.create({ data: { childId, promptVersionId: adultPrompt.id, channel: 'guardian_note', modelConfig: provider.modelConfig, schemaVersion: '1', content: adultDraft } });
    const reveal = await tx.childReveal.create({ data: { childId, title: childDraft.title, message: childDraft.message, llmOutputId: childOutput.id } });
    const note = await tx.adultExploratoryNote.create({ data: { childId, taxonomyKey: adultDraft.taxonomyKey, taxonomyVersion: EXPLORATION_TAXONOMY.version, observations: adultDraft.observations, evidence: adultDraft.evidence, disclaimer: ADULT_NOTE_DISCLAIMER, llmOutputId: adultOutput.id } });
    return { reveal, note };
  });
  await writeAudit({ principal: request.principal!, action: 'synthesis.created', childId, metadata: { track } });
  response.status(201).json({ note: { taxonomyKey: result.note.taxonomyKey, taxonomyVersion: result.note.taxonomyVersion, observations: result.note.observations, evidence: result.note.evidence, disclaimer: result.note.disclaimer, createdAt: result.note.createdAt } });
}));

synthesisRouter.get('/children/:childId/reveal/latest', requireRole('child'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const reveal = await prisma.childReveal.findFirst({ where: { childId }, orderBy: { createdAt: 'desc' } });
  if (!reveal) throw new HttpError(404, 'No reflection is available yet', 'not_found');
  response.json({ title: reveal.title, message: reveal.message, createdAt: reveal.createdAt });
}));

synthesisRouter.get('/children/:childId/adult-notes/latest', requireRole('guardian', 'care_provider'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  if (request.principal!.role === 'care_provider' && !request.principal!.scopes.includes('adult_notes')) throw new HttpError(403, 'This grant does not include field notes', 'insufficient_scope');
  const note = await prisma.adultExploratoryNote.findFirst({ where: { childId }, orderBy: { createdAt: 'desc' } });
  if (!note) throw new HttpError(404, 'No field note is available yet', 'not_found');
  response.json({ taxonomyKey: note.taxonomyKey, taxonomyVersion: note.taxonomyVersion, observations: note.observations, evidence: note.evidence, disclaimer: note.disclaimer, createdAt: note.createdAt });
}));
