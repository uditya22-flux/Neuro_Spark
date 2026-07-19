import { Router } from 'express';
import { ConfigItemStatus } from '@prisma/client';
import { z } from 'zod';
import { authenticate, HttpError, requiredRouteParam, requireChildAccess, requireRole } from '../auth/middleware';
import { prisma } from '../lib/prisma';
import { encryptString } from '../lib/crypto';
import { asyncRoute, parseBody } from './helpers';
import { redactPii, safeguardingReason } from '../services/pii';
import { createLlmProvider } from '../services/llm';
import { rawIntakeExpiry } from '../services/privacy';
import { writeAudit } from '../services/audit';

const intakeSchema = z.object({ text: z.string().trim().min(1).max(5000) });
const reviewSchema = z.object({ items: z.array(z.object({ key: z.enum(['soundEnabled', 'hapticsEnabled', 'reducedMotion', 'theme', 'contrast']), status: z.enum(['CONFIRMED', 'REJECTED']) })).min(1).max(5) });

export const discoveryRouter = Router();
discoveryRouter.use(authenticate, requireChildAccess);

discoveryRouter.post('/children/:childId/discovery/intake', requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const body = parseBody(intakeSchema, request.body);
  const redactedText = redactPii(body.text);
  const safetyReason = safeguardingReason(body.text);
  const maxVersion = await prisma.sensoryConfigItem.aggregate({ where: { childId }, _max: { configVersion: true } });
  const version = maxVersion._max.configVersion ?? 0;
  const configVersion = version + 1;
  const intake = await prisma.intake.create({ data: { guardianId: request.principal!.subject, childId, encryptedRawText: encryptString(body.text), redactedText, expiresAt: rawIntakeExpiry() } });
  if (safetyReason) {
    await prisma.safeguardingCase.create({ data: { childId, intakeId: intake.id, reasonCode: safetyReason } });
    await writeAudit({ principal: request.principal!, action: 'safeguarding.routed', childId, metadata: { intakeId: intake.id } });
    return response.status(202).json({ status: 'human_review', resourceScreen: 'Please use your local emergency or safeguarding resources if there is immediate danger.' });
  }
  const provider = createLlmProvider();
  const draft = await provider.draftSensoryConfiguration(redactedText);
  const prompt = await prisma.promptVersion.upsert({ where: { key_version: { key: 'sensory-hypothesis', version: '1' } }, create: { key: 'sensory-hypothesis', version: '1', template: 'Bounded sensory configuration draft from redacted guardian text.' }, update: {} });
  await prisma.$transaction(async (tx) => {
    await tx.llmOutput.create({ data: { childId, intakeId: intake.id, promptVersionId: prompt.id, channel: 'guardian_configuration_draft', modelConfig: provider.modelConfig, schemaVersion: '1', content: draft } });
    await tx.sensoryConfigItem.createMany({ data: draft.items.map((item) => ({ childId, configVersion, key: item.key, proposedValue: item.value })) });
  });
  await writeAudit({ principal: request.principal!, action: 'discovery.intake_submitted', childId, metadata: { configVersion } });
  response.status(201).json({ intakeId: intake.id, configVersion, items: draft.items.map(({ key, value, rationale }) => ({ key, value, rationale, status: 'PENDING' })) });
}));

discoveryRouter.patch('/children/:childId/discovery/configurations/:configVersion', requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const body = parseBody(reviewSchema, request.body);
  const configVersion = Number(requiredRouteParam(request.params.configVersion, 'configVersion'));
  if (!Number.isInteger(configVersion) || configVersion < 1) throw new HttpError(400, 'Configuration version is invalid', 'invalid_request');
  await prisma.$transaction(body.items.map((item) => prisma.sensoryConfigItem.updateMany({
    where: { childId, configVersion, key: item.key },
    data: { status: item.status as ConfigItemStatus, reviewedAt: new Date() },
  })));
  const items = await prisma.sensoryConfigItem.findMany({ where: { childId, configVersion }, select: { key: true, proposedValue: true, status: true } });
  if (items.length === 0) throw new HttpError(404, 'Configuration was not found', 'not_found');
  await writeAudit({ principal: request.principal!, action: 'discovery.configuration_reviewed', childId, metadata: { configVersion } });
  response.json({ configVersion, items });
}));

discoveryRouter.post('/children/:childId/discovery/configurations/:configVersion/activate', requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const configVersion = Number(requiredRouteParam(request.params.configVersion, 'configVersion'));
  if (!Number.isInteger(configVersion) || configVersion < 1) throw new HttpError(400, 'Configuration version is invalid', 'invalid_request');
  const items = await prisma.sensoryConfigItem.findMany({ where: { childId, configVersion } });
  if (!items.length || items.some((item) => item.status !== 'CONFIRMED')) throw new HttpError(409, 'Every configuration item must be confirmed before activation', 'configuration_unconfirmed');
  const configuration = Object.fromEntries(items.map((item) => [item.key, item.proposedValue]));
  try {
    const active = await prisma.activeSensoryConfiguration.upsert({
      where: { childId_configVersion: { childId, configVersion } },
      create: { childId, configVersion, configuration, active: true },
      update: { configuration, active: true, activatedAt: new Date() },
    });
    await writeAudit({ principal: request.principal!, action: 'discovery.configuration_activated', childId, metadata: { configVersion } });
    response.status(201).json({ id: active.id, configVersion, configuration: active.configuration });
  } catch {
    throw new HttpError(409, 'Configuration activation was rejected by the data safety rule', 'configuration_unconfirmed');
  }
}));
