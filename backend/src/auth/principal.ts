export type PrincipalRole = 'guardian' | 'child' | 'care_provider' | 'admin';

export type Principal = {
  subject: string;
  role: PrincipalRole;
  scopes: string[];
  guardianId?: string;
  childId?: string;
  sessionId?: string;
};
