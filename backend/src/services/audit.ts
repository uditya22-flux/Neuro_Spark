import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import type { Principal } from '../auth/principal';

export async function writeAudit(input: { principal: Principal; action: string; childId?: string; metadata?: Record<string, unknown> }): Promise<void> {
  await prisma.auditLog.create({
    data: {
      guardianId: input.principal.role === 'guardian' ? input.principal.subject : undefined,
      childId: input.childId,
      actorType: input.principal.role,
      actorId: input.principal.subject,
      action: input.action,
      metadata: (input.metadata ?? {}) as Prisma.InputJsonValue,
    },
  });
}
