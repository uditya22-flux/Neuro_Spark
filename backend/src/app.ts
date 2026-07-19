import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import helmet from 'helmet';
import pino from 'pino';
import pinoHttp from 'pino-http';
import { ZodError } from 'zod';
import { config } from './config';
import { HttpError } from './auth/middleware';
import { consentRouter } from './routes/consent';
import { discoveryRouter } from './routes/discovery';
import { deepeningRouter } from './routes/deepening';
import { synthesisRouter } from './routes/synthesis';
import { privacyRouter } from './routes/privacy';

const logger = pino({ level: process.env.LOG_LEVEL ?? 'info', redact: ['req.headers.authorization', 'req.body.text', 'req.body.verificationReference'] });

export function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'same-site' } }));
  app.use(cors({ origin: config.corsOrigin, credentials: false }));
  app.use(express.json({ limit: '32kb' }));
  app.use(pinoHttp({ logger }));
  app.get('/healthz', (_request, response) => response.json({ status: 'ok' }));
  app.use('/v1', consentRouter, discoveryRouter, deepeningRouter, synthesisRouter, privacyRouter);
  app.use((request: Request, _response: Response, next: NextFunction) => next(new HttpError(404, `No route for ${request.method} ${request.path}`, 'not_found')));
  app.use((error: unknown, request: Request, response: Response, _next: NextFunction) => {
    const mapped = error instanceof HttpError
      ? error
      : error instanceof ZodError
        ? new HttpError(400, 'Request is invalid', 'invalid_request')
        : new HttpError(500, 'An unexpected error occurred', 'internal_error');
    if (mapped.status >= 500) request.log.error({ err: error, code: mapped.code }, 'request failed');
    response.status(mapped.status).json({ error: { code: mapped.code, message: mapped.status >= 500 ? 'An unexpected error occurred' : mapped.message } });
  });
  return app;
}
