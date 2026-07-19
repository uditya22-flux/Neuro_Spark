import { randomUUID } from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { authenticate, HttpError, requiredRouteParam, requireRole } from '../auth/middleware';
import { issueToken } from '../auth/tokens';
import { prisma } from '../lib/prisma';
import { daysFromNow } from '../lib/dates';
import { sha256 } from '../lib/crypto';
import { asyncRoute, parseBody } from './helpers';
import { writeAudit } from '../services/audit';

const verifySchema = z.object({
  email: z.string().email(),
  displayName: z.string().trim().min(1).max(100).optional(),
  consentVersion: z.string().trim().min(1).max(32),
  verificationReference: z.string().trim().min(6).max(200),
});
const childSchema = z.object({ preferredName: z.string().trim().min(1).max(80), birthYear: z.number().int().min(1900).max(new Date().getFullYear()) });

export const consentRouter = Router();

consentRouter.get('/consent-versions/current', asyncRoute(async (_request, response) => {
  const version = await prisma.consentVersion.findFirst({ where: { active: true }, orderBy: { createdAt: 'desc' }, select: { version: true, jurisdiction: true, documentUrl: true } });
  if (!version) throw new HttpError(503, 'Consent is not configured', 'consent_unavailable');
  response.json(version);
}));

consentRouter.post('/consents/verify-parent', authenticate, requireRole('guardian'), asyncRoute(async (request, response) => {
  const body = parseBody(verifySchema, request.body);
  const version = await prisma.consentVersion.findFirst({ where: { version: body.consentVersion, active: true } });
  if (!version) throw new HttpError(400, 'That consent version is not active', 'invalid_consent');
  // The production identity-verification adapter must validate this reference
  // before reaching this endpoint. The local development path is deliberately explicit.
  const guardian = await prisma.$transaction(async (tx) => {
    const account = await tx.guardian.upsert({
      where: { externalSubject: request.principal!.subject },
      create: { id: request.principal!.subject, externalSubject: request.principal!.subject, email: body.email, displayName: body.displayName, verifiedAt: new Date() },
      update: { email: body.email, displayName: body.displayName, verifiedAt: new Date() },
    });
    await tx.guardianConsent.upsert({
      where: { guardianId_consentVersionId: { guardianId: account.id, consentVersionId: version.id } },
      create: { guardianId: account.id, consentVersionId: version.id, status: 'ACTIVE', verificationRef: body.verificationReference, verifiedAt: new Date(), acceptedAt: new Date() },
      update: { status: 'ACTIVE', verificationRef: body.verificationReference, verifiedAt: new Date(), acceptedAt: new Date(), revokedAt: null },
    });
    return account;
  });
  await writeAudit({ principal: request.principal!, action: 'guardian.parent_verified', metadata: { consentVersion: version.version } });
  response.status(201).json({ guardianId: guardian.id, consentVersion: version.version, verifiedAt: guardian.verifiedAt });
}));

consentRouter.post('/children', authenticate, requireRole('guardian'), asyncRoute(async (request, response) => {
  const body = parseBody(childSchema, request.body);
  const guardian = await prisma.guardian.findUnique({ where: { id: request.principal!.subject }, include: { consents: { where: { status: 'ACTIVE', verifiedAt: { not: null }, consentVersion: { active: true } } } } });
  if (!guardian?.verifiedAt || guardian.consents.length === 0) throw new HttpError(403, 'Verified parent consent is required before a child profile can be created', 'consent_required');
  const child = await prisma.childProfile.create({ data: { guardianId: guardian.id, preferredName: body.preferredName, birthYear: body.birthYear } });
  await writeAudit({ principal: request.principal!, action: 'child.created', childId: child.id });
  response.status(201).json({ id: child.id, preferredName: child.preferredName, birthYear: child.birthYear });
}));

consentRouter.post('/children/:childId/sessions', authenticate, requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const child = await prisma.childProfile.findFirst({ where: { id: childId, guardianId: request.principal!.subject } });
  if (!child) throw new HttpError(404, 'Child profile was not found', 'not_found');
  const placeholder = await prisma.childSession.create({ data: { childId: child.id, tokenHash: `pending:${randomUUID()}`, expiresAt: daysFromNow(1) } });
  const token = issueToken({ subject: `child:${child.id}`, role: 'child', scopes: ['play'], childId: child.id, sessionId: placeholder.id }, '24h');
  await prisma.childSession.update({ where: { id: placeholder.id }, data: { tokenHash: sha256(token) } });
  await writeAudit({ principal: request.principal!, action: 'child_session.issued', childId: child.id });
  response.status(201).json({ childId: child.id, token, expiresAt: placeholder.expiresAt });
}));

consentRouter.delete('/children/:childId/sessions/:sessionId', authenticate, requireRole('guardian'), asyncRoute(async (request, response) => {
  const childId = requiredRouteParam(request.params.childId, 'childId');
  const sessionId = requiredRouteParam(request.params.sessionId, 'sessionId');
  const session = await prisma.childSession.findFirst({ where: { id: sessionId, childId, child: { guardianId: request.principal!.subject } } });
  if (!session) throw new HttpError(404, 'Child session was not found', 'not_found');
  await prisma.childSession.update({ where: { id: session.id }, data: { revokedAt: new Date(), revokeReason: 'guardian_revoked' } });
  await writeAudit({ principal: request.principal!, action: 'child_session.revoked', childId });
  response.status(204).end();
}));
