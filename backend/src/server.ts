import { createApp } from './app';
import { config } from './config';
import { prisma } from './lib/prisma';

const app = createApp();
const server = app.listen(config.port, () => console.info(`MindBridge API listening on ${config.port}`));

async function shutdown() {
  server.close();
  await prisma.$disconnect();
}
process.once('SIGINT', () => { void shutdown(); });
process.once('SIGTERM', () => { void shutdown(); });
