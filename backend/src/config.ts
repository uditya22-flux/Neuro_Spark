import 'dotenv/config';

function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

export const config = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 3000),
  databaseUrl: required('DATABASE_URL', 'postgresql://mindbridge:mindbridge@localhost:5432/mindbridge?schema=public'),
  jwtSecret: required('JWT_SECRET', 'development-only-secret-change-me'),
  intakeEncryptionKey: required('INTAKE_ENCRYPTION_KEY_BASE64', Buffer.alloc(32, 1).toString('base64')),
  corsOrigin: process.env.CORS_ORIGIN ?? 'http://localhost:5173',
  llmProvider: process.env.LLM_PROVIDER ?? 'fake',
  openAiApiKey: process.env.OPENAI_API_KEY,
  openAiModel: process.env.OPENAI_MODEL ?? 'gpt-4.1-mini',
  parentVerificationProvider: process.env.PARENT_VERIFICATION_PROVIDER ?? 'development-fixture',
  rawIntakeRetentionDays: Number(process.env.RAW_INTAKE_RETENTION_DAYS ?? 30),
  eventRetentionDays: Number(process.env.EVENT_RETENTION_DAYS ?? 90),
} as const;

if (config.nodeEnv === 'production') {
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL must be configured in production');
  if (config.jwtSecret === 'development-only-secret-change-me') {
    throw new Error('JWT_SECRET must be configured in production');
  }
  if (config.llmProvider !== 'openai') {
    throw new Error('Production requires the approved OpenAI API provider and its data-retention approval');
  }
  if (!config.openAiApiKey) {
    throw new Error('OPENAI_API_KEY must be configured in production');
  }
  if (config.parentVerificationProvider !== 'approved-provider') {
    throw new Error('Production requires an approved parent-verification provider');
  }
}
