/*
  Warnings:

  - You are about to drop the `Engine2Answer` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Engine2ObservedProfile` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Engine2QuestionSet` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Engine2Session` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "ActiveSensoryConfiguration" DROP CONSTRAINT "ActiveSensoryConfiguration_childId_fkey";

-- DropForeignKey
ALTER TABLE "AdultExploratoryNote" DROP CONSTRAINT "AdultExploratoryNote_childId_fkey";

-- DropForeignKey
ALTER TABLE "AuditLog" DROP CONSTRAINT "AuditLog_guardianId_fkey";

-- DropForeignKey
ALTER TABLE "CareProviderGrant" DROP CONSTRAINT "CareProviderGrant_careProviderId_fkey";

-- DropForeignKey
ALTER TABLE "CareProviderGrant" DROP CONSTRAINT "CareProviderGrant_childId_fkey";

-- DropForeignKey
ALTER TABLE "CareProviderGrant" DROP CONSTRAINT "CareProviderGrant_guardianId_fkey";

-- DropForeignKey
ALTER TABLE "ChildProfile" DROP CONSTRAINT "ChildProfile_guardianId_fkey";

-- DropForeignKey
ALTER TABLE "ChildReveal" DROP CONSTRAINT "ChildReveal_childId_fkey";

-- DropForeignKey
ALTER TABLE "ChildSession" DROP CONSTRAINT "ChildSession_childId_fkey";

-- DropForeignKey
ALTER TABLE "Engine2Answer" DROP CONSTRAINT "Engine2Answer_sessionId_fkey";

-- DropForeignKey
ALTER TABLE "Engine2ObservedProfile" DROP CONSTRAINT "Engine2ObservedProfile_childId_fkey";

-- DropForeignKey
ALTER TABLE "Engine2ObservedProfile" DROP CONSTRAINT "Engine2ObservedProfile_sessionId_fkey";

-- DropForeignKey
ALTER TABLE "Engine2QuestionSet" DROP CONSTRAINT "Engine2QuestionSet_childId_fkey";

-- DropForeignKey
ALTER TABLE "Engine2Session" DROP CONSTRAINT "Engine2Session_childId_fkey";

-- DropForeignKey
ALTER TABLE "Engine2Session" DROP CONSTRAINT "Engine2Session_questionSetId_fkey";

-- DropForeignKey
ALTER TABLE "ExplorationAggregate" DROP CONSTRAINT "ExplorationAggregate_childId_fkey";

-- DropForeignKey
ALTER TABLE "GuardianConsent" DROP CONSTRAINT "GuardianConsent_consentVersionId_fkey";

-- DropForeignKey
ALTER TABLE "GuardianConsent" DROP CONSTRAINT "GuardianConsent_guardianId_fkey";

-- DropForeignKey
ALTER TABLE "Intake" DROP CONSTRAINT "Intake_childId_fkey";

-- DropForeignKey
ALTER TABLE "Intake" DROP CONSTRAINT "Intake_guardianId_fkey";

-- DropForeignKey
ALTER TABLE "LlmOutput" DROP CONSTRAINT "LlmOutput_childId_fkey";

-- DropForeignKey
ALTER TABLE "LlmOutput" DROP CONSTRAINT "LlmOutput_intakeId_fkey";

-- DropForeignKey
ALTER TABLE "LlmOutput" DROP CONSTRAINT "LlmOutput_promptVersionId_fkey";

-- DropForeignKey
ALTER TABLE "PlayEvent" DROP CONSTRAINT "PlayEvent_childId_fkey";

-- DropForeignKey
ALTER TABLE "PlayEvent" DROP CONSTRAINT "PlayEvent_playSessionId_fkey";

-- DropForeignKey
ALTER TABLE "PlaySession" DROP CONSTRAINT "PlaySession_childId_fkey";

-- DropForeignKey
ALTER TABLE "PurgeRequest" DROP CONSTRAINT "PurgeRequest_childId_fkey";

-- DropForeignKey
ALTER TABLE "PurgeRequest" DROP CONSTRAINT "PurgeRequest_guardianId_fkey";

-- DropForeignKey
ALTER TABLE "SafeguardingCase" DROP CONSTRAINT "SafeguardingCase_childId_fkey";

-- DropForeignKey
ALTER TABLE "SafeguardingCase" DROP CONSTRAINT "SafeguardingCase_intakeId_fkey";

-- DropForeignKey
ALTER TABLE "SensoryConfigItem" DROP CONSTRAINT "SensoryConfigItem_childId_fkey";

-- DropForeignKey
ALTER TABLE "StorageObject" DROP CONSTRAINT "StorageObject_childId_fkey";

-- DropTable
DROP TABLE "Engine2Answer";

-- DropTable
DROP TABLE "Engine2ObservedProfile";

-- DropTable
DROP TABLE "Engine2QuestionSet";

-- DropTable
DROP TABLE "Engine2Session";

-- DropEnum
DROP TYPE "Engine2Phase";

-- DropEnum
DROP TYPE "Engine2SessionStatus";

-- CreateIndex
CREATE INDEX "ActiveSensoryConfiguration_childId_active_idx" ON "ActiveSensoryConfiguration"("childId", "active");

-- CreateIndex
CREATE INDEX "AdultExploratoryNote_childId_createdAt_idx" ON "AdultExploratoryNote"("childId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_guardianId_createdAt_idx" ON "AuditLog"("guardianId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_childId_createdAt_idx" ON "AuditLog"("childId", "createdAt");

-- CreateIndex
CREATE INDEX "CareProviderGrant_careProviderId_expiresAt_idx" ON "CareProviderGrant"("careProviderId", "expiresAt");

-- CreateIndex
CREATE INDEX "ChildReveal_childId_createdAt_idx" ON "ChildReveal"("childId", "createdAt");

-- CreateIndex
CREATE INDEX "Intake_childId_createdAt_idx" ON "Intake"("childId", "createdAt");

-- CreateIndex
CREATE INDEX "PlayEvent_childId_occurredAt_idx" ON "PlayEvent"("childId", "occurredAt");

-- CreateIndex
CREATE INDEX "PlaySession_childId_track_startedAt_idx" ON "PlaySession"("childId", "track", "startedAt");

-- CreateIndex
CREATE INDEX "PurgeRequest_status_requestedAt_idx" ON "PurgeRequest"("status", "requestedAt");

-- CreateIndex
CREATE INDEX "SafeguardingCase_status_restricted_idx" ON "SafeguardingCase"("status", "restricted");

-- CreateIndex
CREATE INDEX "StorageObject_childId_deletedAt_idx" ON "StorageObject"("childId", "deletedAt");

-- AddForeignKey
ALTER TABLE "GuardianConsent" ADD CONSTRAINT "GuardianConsent_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GuardianConsent" ADD CONSTRAINT "GuardianConsent_consentVersionId_fkey" FOREIGN KEY ("consentVersionId") REFERENCES "ConsentVersion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChildProfile" ADD CONSTRAINT "ChildProfile_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChildSession" ADD CONSTRAINT "ChildSession_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CareProviderGrant" ADD CONSTRAINT "CareProviderGrant_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CareProviderGrant" ADD CONSTRAINT "CareProviderGrant_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CareProviderGrant" ADD CONSTRAINT "CareProviderGrant_careProviderId_fkey" FOREIGN KEY ("careProviderId") REFERENCES "CareProvider"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Intake" ADD CONSTRAINT "Intake_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Intake" ADD CONSTRAINT "Intake_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SensoryConfigItem" ADD CONSTRAINT "SensoryConfigItem_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ActiveSensoryConfiguration" ADD CONSTRAINT "ActiveSensoryConfiguration_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaySession" ADD CONSTRAINT "PlaySession_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayEvent" ADD CONSTRAINT "PlayEvent_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayEvent" ADD CONSTRAINT "PlayEvent_playSessionId_fkey" FOREIGN KEY ("playSessionId") REFERENCES "PlaySession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExplorationAggregate" ADD CONSTRAINT "ExplorationAggregate_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LlmOutput" ADD CONSTRAINT "LlmOutput_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LlmOutput" ADD CONSTRAINT "LlmOutput_intakeId_fkey" FOREIGN KEY ("intakeId") REFERENCES "Intake"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LlmOutput" ADD CONSTRAINT "LlmOutput_promptVersionId_fkey" FOREIGN KEY ("promptVersionId") REFERENCES "PromptVersion"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChildReveal" ADD CONSTRAINT "ChildReveal_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdultExploratoryNote" ADD CONSTRAINT "AdultExploratoryNote_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafeguardingCase" ADD CONSTRAINT "SafeguardingCase_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SafeguardingCase" ADD CONSTRAINT "SafeguardingCase_intakeId_fkey" FOREIGN KEY ("intakeId") REFERENCES "Intake"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StorageObject" ADD CONSTRAINT "StorageObject_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurgeRequest" ADD CONSTRAINT "PurgeRequest_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurgeRequest" ADD CONSTRAINT "PurgeRequest_childId_fkey" FOREIGN KEY ("childId") REFERENCES "ChildProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_guardianId_fkey" FOREIGN KEY ("guardianId") REFERENCES "Guardian"("id") ON DELETE SET NULL ON UPDATE CASCADE;
