import type { NextFunction, Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { sha256 } from '../lib/crypto';
import { verifyToken } from './tokens';
import type { PrincipalRole } from './principal';

export class HttpError extends Error {
  constructor(public status: number, message: string, public code = 'request_failed') {
    super(message);
  }
}

/** Reject array-valued or missing Express parameters at the HTTP boundary. */
export function requiredRouteParam(value: unknown, name: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpError(400, `${name} is required`, 'invalid_parameter');
  }
  return value;
}

export async function authenticate(request: Request, _response: Response, next: NextFunction): Promise<void> {
  try {
    const header = request.header('authorization');
    if (!header?.startsWith('Bearer ')) throw new HttpError(401, 'Authentication is required', 'unauthenticated');
    const token = header.slice('Bearer '.length);
    const principal = verifyToken(token);
    if (principal.role === 'child') {
      if (!principal.sessionId || !principal.childId) throw new HttpError(401, 'Child session is invalid', 'invalid_session');
      const session = await prisma.childSession.findUnique({ where: { id: principal.sessionId } });
      if (!session || session.childId !== principal.childId || session.tokenHash !== sha256(token) || session.revokedAt || session.expiresAt <= new Date()) {
        throw new HttpError(401, 'Child session is no longer active', 'revoked_session');
      }
    }
    request.principal = principal;
    next();
  } catch (error) {
    next(error instanceof HttpError ? error : new HttpError(401, 'Authentication is invalid', 'invalid_token'));
  }
}

export function requireRole(...roles: PrincipalRole[]) {
  return (request: Request, _response: Response, next: NextFunction): void => {
    if (!request.principal) return next(new HttpError(401, 'Authentication is required', 'unauthenticated'));
    if (!roles.includes(request.principal.role)) return next(new HttpError(403, 'This action is not permitted', 'forbidden'));
    next();
  };
}

export function requireScope(scope: string) {
  return (request: Request, _response: Response, next: NextFunction): void => {
    if (!request.principal) return next(new HttpError(401, 'Authentication is required', 'unauthenticated'));
    if (request.principal.role !== 'admin' && !request.principal.scopes.includes(scope)) {
      return next(new HttpError(403, 'This action is not permitted', 'insufficient_scope'));
    }
    next();
  };
}

/** Confirms child access from a guardian, the child session itself, or an active provider grant. */
export async function requireChildAccess(request: Request, _response: Response, next: NextFunction): Promise<void> {
  try {
    const principal = request.principal;
    const childId = requiredRouteParam(request.params.childId, 'childId');
    if (!principal) throw new HttpError(401, 'Authentication is required', 'unauthenticated');
    if (principal.role === 'admin') return next();
    if (principal.role === 'child') {
      if (principal.childId !== childId) throw new HttpError(403, 'This child session cannot access another profile', 'forbidden');
      return next();
    }
    if (principal.role === 'guardian') {
      const child = await prisma.childProfile.findFirst({ where: { id: childId, guardianId: principal.subject }, select: { id: true } });
      if (!child) throw new HttpError(404, 'Child profile was not found', 'not_found');
      return next();
    }
    const grant = await prisma.careProviderGrant.findFirst({
      where: { childId, careProvider: { externalSubject: principal.subject }, revokedAt: null, expiresAt: { gt: new Date() } },
      select: { id: true },
    });
    if (!grant) throw new HttpError(404, 'Child profile was not found', 'not_found');
    next();
  } catch (error) {
    next(error);
  }
}
