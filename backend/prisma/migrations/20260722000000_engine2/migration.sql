-- Engine 2 is independent from the fixed MVP Track enum.
CREATE TYPE "Engine2Phase" AS ENUM ('BASELINE', 'ADAPTIVE', 'COMPLETE');
CREATE TYPE "Engine2SessionStatus" AS ENUM ('ACTIVE', 'PAUSED', 'COMPLETE', 'EXPIRED', 'REVOKED');

CREATE TABLE "Engine2QuestionSet" (
  "id" TEXT PRIMARY KEY,
  "childId" TEXT NOT NULL,
  "stage" "Engine2Phase" NOT NULL,
  "version" TEXT NOT NULL,
  "schemaVersion" TEXT NOT NULL,
  "promptVersion" TEXT NOT NULL,
  "modelConfig" JSONB NOT NULL,
  "redactedProvenance" JSONB NOT NULL,
  "sensorySnapshot" JSONB NOT NULL,
  "questions" JSONB NOT NULL,
  "generatedSnapshot" JSONB NOT NULL,
  "fallbackUsed" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "Engine2Session" (
  "id" TEXT PRIMARY KEY,
  "childId" TEXT NOT NULL,
  "questionSetId" TEXT NOT NULL,
  "phase" "Engine2Phase" NOT NULL DEFAULT 'BASELINE',
  "status" "Engine2SessionStatus" NOT NULL DEFAULT 'ACTIVE',
  "cursor" INTEGER NOT NULL DEFAULT 0,
  "pauseOrSkipRun" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "pausedAt" TIMESTAMP(3),
  "completedAt" TIMESTAMP(3),
  "expiresAt" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "Engine2Answer" (
  "id" TEXT PRIMARY KEY,
  "sessionId" TEXT NOT NULL,
  "questionId" TEXT NOT NULL,
  "optionIds" TEXT[] NOT NULL,
  "skipped" BOOLEAN NOT NULL DEFAULT false,
  "clientSubmissionId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE("sessionId", "questionId"),
  UNIQUE("sessionId", "clientSubmissionId")
);
CREATE TABLE "Engine2ObservedProfile" (
  "id" TEXT PRIMARY KEY,
  "childId" TEXT NOT NULL,
  "sessionId" TEXT NOT NULL UNIQUE,
  "profileVersion" TEXT NOT NULL,
  "schemaVersion" TEXT NOT NULL,
  "evidence" JSONB NOT NULL,
  "observations" JSONB NOT NULL,
  "provenance" JSONB NOT NULL,
  "childReveal" JSONB NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE "Engine2QuestionSet" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "Engine2Session" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("questionSetId") REFERENCES "Engine2QuestionSet"("id") ON DELETE CASCADE;
ALTER TABLE "Engine2Answer" ADD FOREIGN KEY ("sessionId") REFERENCES "Engine2Session"("id") ON DELETE CASCADE;
ALTER TABLE "Engine2ObservedProfile" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("sessionId") REFERENCES "Engine2Session"("id") ON DELETE CASCADE;
CREATE UNIQUE INDEX "Engine2QuestionSet_childId_stage_version_key" ON "Engine2QuestionSet"("childId", "stage", "version");
CREATE INDEX "Engine2QuestionSet_childId_stage_createdAt_idx" ON "Engine2QuestionSet"("childId", "stage", "createdAt");
CREATE INDEX "Engine2QuestionSet_expiresAt_idx" ON "Engine2QuestionSet"("expiresAt");
CREATE INDEX "Engine2Session_childId_status_updatedAt_idx" ON "Engine2Session"("childId", "status", "updatedAt");
CREATE INDEX "Engine2Session_expiresAt_idx" ON "Engine2Session"("expiresAt");
CREATE INDEX "Engine2Answer_sessionId_createdAt_idx" ON "Engine2Answer"("sessionId", "createdAt");
CREATE INDEX "Engine2ObservedProfile_childId_createdAt_idx" ON "Engine2ObservedProfile"("childId", "createdAt");
