import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { daysFromNow } from '../lib/dates';

export async function requestPurge(guardianId: string, childId?: string): Promise<string> {
  return prisma.$transaction(async (tx) => {
    const request = await tx.purgeRequest.create({ data: { guardianId, childId } });
    await tx.outboxEvent.create({
      data: { type: 'privacy.purge_requested', aggregateId: request.id, payload: { purgeRequestId: request.id, childId: childId ?? null } },
    });
    return request.id;
  });
}

export async function buildPrivacyExport(guardianId: string, childId?: string): Promise<Record<string, unknown>> {
  const where = childId ? { id: childId, guardianId } : { guardianId };
  const children = await prisma.childProfile.findMany({
    where,
    select: {
      id: true, preferredName: true, birthYear: true, createdAt: true,
      activeConfigs: { where: { active: true }, select: { configuration: true, activatedAt: true } },
      events: { select: { kind: true, layer: true, occurredAt: true }, orderBy: { occurredAt: 'asc' } },
      aggregates: { select: { track: true, evidence: true, explorationInProgress: true, calculatedAt: true } },
      childReveals: { select: { title: true, message: true, createdAt: true } },
      adultNotes: { select: { taxonomyKey: true, taxonomyVersion: true, observations: true, evidence: true, disclaimer: true, createdAt: true } },
    },
  });
  return { generatedAt: new Date().toISOString(), children };
}

export async function expireRetentionBoundRecords(): Promise<{ intakes: number; events: number }> {
  const now = new Date();
  const [intakes, events] = await prisma.$transaction([
    prisma.intake.deleteMany({ where: { expiresAt: { lte: now } } }),
    prisma.playEvent.deleteMany({ where: { expiresAt: { lte: now } } }),
  ]);
  return { intakes: intakes.count, events: events.count };
}

/** Runs only in the background worker. Object-store deletion is represented by references until an adapter is configured. */
export async function executePurge(purgeRequestId: string): Promise<void> {
  const request = await prisma.purgeRequest.findUnique({ where: { id: purgeRequestId } });
  if (!request || request.status === 'COMPLETED') return;
  await prisma.purgeRequest.update({ where: { id: request.id }, data: { status: 'PROCESSING' } });
  try {
    await prisma.$transaction(async (tx) => {
      if (request.childId) {
        await tx.auditLog.deleteMany({ where: { childId: request.childId } });
        await tx.outboxEvent.deleteMany({ where: { aggregateId: request.childId } });
        await tx.childProfile.delete({ where: { id: request.childId } });
      } else {
        await tx.auditLog.deleteMany({ where: { guardianId: request.guardianId } });
        await tx.outboxEvent.deleteMany({ where: { aggregateId: request.guardianId } });
        await tx.guardian.delete({ where: { id: request.guardianId } });
      }
      // The request is deleted by cascade when it is child-scoped; explicitly
      // remove it for guardian-wide purges before the guardian delete path exits.
      await tx.purgeRequest.deleteMany({ where: { id: request.id } });
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  } catch (error) {
    await prisma.purgeRequest.update({ where: { id: request.id }, data: { status: 'FAILED', failureReason: error instanceof Error ? error.message.slice(0, 500) : 'unknown' } }).catch(() => undefined);
    throw error;
  }
}

export function rawIntakeExpiry(): Date { return daysFromNow(Number(process.env.RAW_INTAKE_RETENTION_DAYS ?? 30)); }
export function telemetryExpiry(): Date { return daysFromNow(Number(process.env.EVENT_RETENTION_DAYS ?? 90)); }
