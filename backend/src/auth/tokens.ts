import jwt, { type SignOptions } from 'jsonwebtoken';
import { config } from '../config';
import type { Principal } from './principal';

export function issueToken(principal: Principal, expiresIn: SignOptions['expiresIn'] = '1h'): string {
  return jwt.sign(principal, config.jwtSecret, {
    algorithm: 'HS256',
    subject: principal.subject,
    expiresIn,
  });
}

export function verifyToken(token: string): Principal {
  const decoded = jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] });
  if (typeof decoded === 'string' || !decoded.role || !decoded.sub) throw new Error('Invalid token claims');
  return {
    subject: decoded.sub,
    role: decoded.role as Principal['role'],
    scopes: Array.isArray(decoded.scopes) ? decoded.scopes.map(String) : [],
    guardianId: typeof decoded.guardianId === 'string' ? decoded.guardianId : undefined,
    childId: typeof decoded.childId === 'string' ? decoded.childId : undefined,
    sessionId: typeof decoded.sessionId === 'string' ? decoded.sessionId : undefined,
  };
}
