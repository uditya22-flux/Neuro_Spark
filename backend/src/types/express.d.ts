import type { Principal } from '../auth/principal';

declare global {
  namespace Express {
    interface Request {
      principal?: Principal;
    }
  }
}

export {};
