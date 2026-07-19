-- Initial PostgreSQL schema for the guardian-led private beta.
-- CUID values and @updatedAt timestamps are supplied by Prisma.
CREATE TYPE "UserRole" AS ENUM ('GUARDIAN','CARE_PROVIDER','ADMIN');
CREATE TYPE "ConsentStatus" AS ENUM ('PENDING','ACTIVE','REVOKED');
CREATE TYPE "ConfigItemStatus" AS ENUM ('PENDING','CONFIRMED','REJECTED');
CREATE TYPE "SafeguardingStatus" AS ENUM ('OPEN','IN_REVIEW','RESOLVED');
CREATE TYPE "Track" AS ENUM ('CALENDAR_GENIUS','CONSTELLATION_MAPPER');
CREATE TYPE "EventKind" AS ENUM ('TASK_OPENED','TASK_SKIPPED','TASK_COMPLETED','PAUSE_REQUESTED','COOLDOWN_STARTED','COOLDOWN_ENDED');
CREATE TYPE "PurgeStatus" AS ENUM ('REQUESTED','PROCESSING','COMPLETED','FAILED');

CREATE TABLE "Guardian" ("id" TEXT PRIMARY KEY, "externalSubject" TEXT NOT NULL UNIQUE, "email" TEXT NOT NULL UNIQUE, "displayName" TEXT, "verifiedAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL);
CREATE TABLE "CareProvider" ("id" TEXT PRIMARY KEY, "externalSubject" TEXT NOT NULL UNIQUE, "email" TEXT NOT NULL UNIQUE, "displayName" TEXT, "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "ConsentVersion" ("id" TEXT PRIMARY KEY, "version" TEXT NOT NULL UNIQUE, "jurisdiction" TEXT NOT NULL DEFAULT 'IN', "documentUrl" TEXT NOT NULL, "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "GuardianConsent" ("id" TEXT PRIMARY KEY, "guardianId" TEXT NOT NULL, "consentVersionId" TEXT NOT NULL, "status" "ConsentStatus" NOT NULL DEFAULT 'PENDING', "verificationRef" TEXT, "verifiedAt" TIMESTAMP(3), "acceptedAt" TIMESTAMP(3), "revokedAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL, UNIQUE("guardianId","consentVersionId"));
CREATE TABLE "ChildProfile" ("id" TEXT PRIMARY KEY, "guardianId" TEXT NOT NULL, "preferredName" TEXT NOT NULL, "birthYear" INTEGER NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL);
CREATE TABLE "ChildSession" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "tokenHash" TEXT NOT NULL UNIQUE, "issuedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "expiresAt" TIMESTAMP(3) NOT NULL, "revokedAt" TIMESTAMP(3), "revokeReason" TEXT);
CREATE TABLE "CareProviderGrant" ("id" TEXT PRIMARY KEY, "guardianId" TEXT NOT NULL, "childId" TEXT NOT NULL, "careProviderId" TEXT NOT NULL, "scope" TEXT[] NOT NULL, "grantedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "expiresAt" TIMESTAMP(3) NOT NULL, "revokedAt" TIMESTAMP(3), UNIQUE("childId","careProviderId"));
CREATE TABLE "Intake" ("id" TEXT PRIMARY KEY, "guardianId" TEXT NOT NULL, "childId" TEXT NOT NULL, "encryptedRawText" TEXT NOT NULL, "redactedText" TEXT NOT NULL, "confirmedAt" TIMESTAMP(3), "expiresAt" TIMESTAMP(3) NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "SensoryConfigItem" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "configVersion" INTEGER NOT NULL, "key" TEXT NOT NULL, "proposedValue" JSONB NOT NULL, "status" "ConfigItemStatus" NOT NULL DEFAULT 'PENDING', "reviewedAt" TIMESTAMP(3), "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE("childId","configVersion","key"));
CREATE TABLE "ActiveSensoryConfiguration" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "configVersion" INTEGER NOT NULL, "configuration" JSONB NOT NULL, "active" BOOLEAN NOT NULL DEFAULT true, "activatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE("childId","configVersion"));
CREATE TABLE "PlaySession" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "track" "Track" NOT NULL, "seed" TEXT NOT NULL, "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "endedAt" TIMESTAMP(3));
CREATE TABLE "PlayEvent" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "playSessionId" TEXT NOT NULL, "kind" "EventKind" NOT NULL, "layer" INTEGER NOT NULL, "payload" JSONB NOT NULL, "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "expiresAt" TIMESTAMP(3) NOT NULL);
CREATE TABLE "ExplorationAggregate" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "track" "Track" NOT NULL, "evidence" JSONB NOT NULL, "explorationInProgress" BOOLEAN NOT NULL DEFAULT true, "calculatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE("childId","track"));
CREATE TABLE "PromptVersion" ("id" TEXT PRIMARY KEY, "key" TEXT NOT NULL, "version" TEXT NOT NULL, "template" TEXT NOT NULL, "active" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE("key","version"));
CREATE TABLE "LlmOutput" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "intakeId" TEXT, "promptVersionId" TEXT NOT NULL, "channel" TEXT NOT NULL, "modelConfig" JSONB NOT NULL, "schemaVersion" TEXT NOT NULL, "content" JSONB NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "ChildReveal" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "title" TEXT NOT NULL, "message" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "llmOutputId" TEXT NOT NULL UNIQUE);
CREATE TABLE "AdultExploratoryNote" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "taxonomyKey" TEXT NOT NULL, "taxonomyVersion" TEXT NOT NULL, "observations" JSONB NOT NULL, "evidence" JSONB NOT NULL, "disclaimer" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "llmOutputId" TEXT NOT NULL UNIQUE);
CREATE TABLE "SafeguardingCase" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "intakeId" TEXT NOT NULL, "reasonCode" TEXT NOT NULL, "status" "SafeguardingStatus" NOT NULL DEFAULT 'OPEN', "restricted" BOOLEAN NOT NULL DEFAULT true, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL);
CREATE TABLE "StorageObject" ("id" TEXT PRIMARY KEY, "childId" TEXT NOT NULL, "objectKey" TEXT NOT NULL UNIQUE, "purpose" TEXT NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "deletedAt" TIMESTAMP(3));
CREATE TABLE "PurgeRequest" ("id" TEXT PRIMARY KEY, "guardianId" TEXT NOT NULL, "childId" TEXT, "status" "PurgeStatus" NOT NULL DEFAULT 'REQUESTED', "requestedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "completedAt" TIMESTAMP(3), "failureReason" TEXT);
CREATE TABLE "OutboxEvent" ("id" TEXT PRIMARY KEY, "type" TEXT NOT NULL, "aggregateId" TEXT NOT NULL, "payload" JSONB NOT NULL, "availableAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "processedAt" TIMESTAMP(3), "attempts" INTEGER NOT NULL DEFAULT 0, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE "AuditLog" ("id" TEXT PRIMARY KEY, "guardianId" TEXT, "childId" TEXT, "actorType" TEXT NOT NULL, "actorId" TEXT NOT NULL, "action" TEXT NOT NULL, "metadata" JSONB NOT NULL, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP);

ALTER TABLE "GuardianConsent" ADD FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("consentVersionId") REFERENCES "ConsentVersion"("id");
ALTER TABLE "ChildProfile" ADD FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE;
ALTER TABLE "ChildSession" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "CareProviderGrant" ADD FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("careProviderId") REFERENCES "CareProvider"("id") ON DELETE CASCADE;
ALTER TABLE "Intake" ADD FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "SensoryConfigItem" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "ActiveSensoryConfiguration" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "PlaySession" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "PlayEvent" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("playSessionId") REFERENCES "PlaySession"("id") ON DELETE CASCADE;
ALTER TABLE "ExplorationAggregate" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "LlmOutput" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("intakeId") REFERENCES "Intake"("id") ON DELETE SET NULL, ADD FOREIGN KEY ("promptVersionId") REFERENCES "PromptVersion"("id");
ALTER TABLE "ChildReveal" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "AdultExploratoryNote" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "SafeguardingCase" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("intakeId") REFERENCES "Intake"("id") ON DELETE CASCADE;
ALTER TABLE "StorageObject" ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "PurgeRequest" ADD FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE, ADD FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE;
ALTER TABLE "AuditLog" ADD FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE SET NULL;

CREATE INDEX "GuardianConsent_guardianId_status_idx" ON "GuardianConsent"("guardianId","status");
CREATE INDEX "ChildProfile_guardianId_idx" ON "ChildProfile"("guardianId");
CREATE INDEX "ChildSession_childId_expiresAt_idx" ON "ChildSession"("childId","expiresAt");
CREATE INDEX "Intake_expiresAt_idx" ON "Intake"("expiresAt");
CREATE INDEX "SensoryConfigItem_childId_configVersion_status_idx" ON "SensoryConfigItem"("childId","configVersion","status");
CREATE INDEX "PlayEvent_expiresAt_idx" ON "PlayEvent"("expiresAt");
CREATE INDEX "LlmOutput_childId_channel_createdAt_idx" ON "LlmOutput"("childId","channel","createdAt");
CREATE INDEX "OutboxEvent_processedAt_availableAt_idx" ON "OutboxEvent"("processedAt","availableAt");

-- PostgreSQL, rather than application code, prevents activation until every
-- sensory item in the proposed version has an explicit guardian confirmation.
CREATE OR REPLACE FUNCTION mindbridge_activate_confirmed_configuration()
RETURNS TRIGGER AS $$
DECLARE total_items integer; confirmed_items integer;
BEGIN
  IF NEW.active IS NOT TRUE THEN RETURN NEW; END IF;
  SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'CONFIRMED') INTO total_items, confirmed_items
  FROM "SensoryConfigItem" WHERE "childId" = NEW."childId" AND "configVersion" = NEW."configVersion";
  IF total_items = 0 OR confirmed_items <> total_items THEN
    RAISE EXCEPTION 'Cannot activate an unconfirmed sensory configuration';
  END IF;
  UPDATE "ActiveSensoryConfiguration" SET active = FALSE WHERE "childId" = NEW."childId" AND active = TRUE AND id <> NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER enforce_confirmed_sensory_configuration BEFORE INSERT OR UPDATE OF active ON "ActiveSensoryConfiguration" FOR EACH ROW EXECUTE FUNCTION mindbridge_activate_confirmed_configuration();
