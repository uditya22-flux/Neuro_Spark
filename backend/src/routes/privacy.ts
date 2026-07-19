import { Router } from 'express';
import { z } from 'zod';
import { authenticate, HttpError, requireRole } from '../auth/middleware';
import { prisma } from '../lib/prisma';
import { asyncRoute, parseBody } from './helpers';
import { buildPrivacyExport, requestPurge } from '../services/privacy';
import { writeAudit } from '../services/audit';

const exportQuery = z.object({ childId: z.string().min(1).optional() });
const purgeSchema = z.object({ childId: z.string().min(1).optional(), confirm: z.literal(true) });
export const privacyRouter = Router();
privacyRouter.use(authenticate, requireRole('guardian'));

privacyRouter.get('/privacy/export', asyncRoute(async (request, response) => {
  const query = parseBody(exportQuery, request.query);
  if (query.childId) {
    const child = await prisma.childProfile.findFirst({ where: { id: query.childId, guardianId: request.principal!.subject }, select: { id: true } });
    if (!child) throw new HttpError(404, 'Child profile was not found', 'not_found');
  }
  const payload = await buildPrivacyExport(request.principal!.subject, query.childId);
  await writeAudit({ principal: request.principal!, action: 'privacy.exported', childId: query.childId });
  response.setHeader('Content-Disposition', 'attachment; filename="mindbridge-export.json"').json(payload);
}));

privacyRouter.post('/privacy/purge', asyncRoute(async (request, response) => {
  const body = parseBody(purgeSchema, request.body);
  if (body.childId) {
    const child = await prisma.childProfile.findFirst({ where: { id: body.childId, guardianId: request.principal!.subject }, select: { id: true } });
    if (!child) throw new HttpError(404, 'Child profile was not found', 'not_found');
  }
  const purgeRequestId = await requestPurge(request.principal!.subject, body.childId);
  await writeAudit({ principal: request.principal!, action: 'privacy.purge_requested', childId: body.childId, metadata: { purgeRequestId } });
  response.status(202).json({ purgeRequestId, status: 'REQUESTED' });
}));
