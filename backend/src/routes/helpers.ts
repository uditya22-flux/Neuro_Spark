import type { NextFunction, Request, RequestHandler, Response } from 'express';
import { ZodError } from 'zod';
import { HttpError } from '../auth/middleware';

export const asyncRoute = (handler: (request: Request, response: Response, next: NextFunction) => Promise<unknown>): RequestHandler =>
  (request, response, next) => { void handler(request, response, next).catch(next); };

export function parseBody<T>(parser: { parse: (value: unknown) => T }, body: unknown): T {
  try { return parser.parse(body); } catch (error) {
    if (error instanceof ZodError) throw new HttpError(400, 'Request body is invalid', 'invalid_request');
    throw error;
  }
}
