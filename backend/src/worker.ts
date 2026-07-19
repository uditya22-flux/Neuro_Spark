import { prisma } from './lib/prisma';
import { executePurge, expireRetentionBoundRecords } from './services/privacy';

const POLL_MS = 5_000;

async function processOutbox(): Promise<void> {
  const event = await prisma.outboxEvent.findFirst({ where: { processedAt: null, availableAt: { lte: new Date() } }, orderBy: { createdAt: 'asc' } });
  if (!event) return;
  await prisma.outboxEvent.update({ where: { id: event.id }, data: { attempts: { increment: 1 } } });
  try {
    if (event.type === 'privacy.purge_requested') {
      const payload = event.payload as { purgeRequestId?: string };
      if (!payload.purgeRequestId) throw new Error('Purge event does not contain a request id');
      await executePurge(payload.purgeRequestId);
    }
    await prisma.outboxEvent.update({ where: { id: event.id }, data: { processedAt: new Date() } }).catch(() => undefined);
  } catch (error) {
    // Retry with bounded, database-visible delay. No payload contents are logged.
    const delay = Math.min(60_000, 1_000 * 2 ** Math.min(event.attempts, 6));
    await prisma.outboxEvent.update({ where: { id: event.id }, data: { availableAt: new Date(Date.now() + delay) } });
    console.error('Outbox event failed', { eventId: event.id, type: event.type, error: error instanceof Error ? error.message : 'unknown' });
  }
}

async function tick(): Promise<void> {
  await expireRetentionBoundRecords();
  await processOutbox();
}

void tick();
setInterval(() => { void tick(); }, POLL_MS);
