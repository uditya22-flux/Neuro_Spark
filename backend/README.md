# MindBridge backend

The private-beta API is intentionally guardian-led. It stores only the minimum data needed to provide two accessible play tracks and explicitly avoids diagnostic, career-prediction, hiring, and child re-engagement features.

## Local setup

1. Copy `.env.example` to `.env` and set secure values.
2. Start PostgreSQL and Redis for the stack (Redis is reserved for the production queue/cache adapter; the development worker uses the database outbox).
3. Run `npm install`, `npm run prisma:generate`, and `npm run prisma:migrate`.
4. Run `npm run dev` and, in a second terminal, `npm run worker`.

The development LLM provider is deterministic and schema-safe. Production startup rejects non-fake LLM configuration until the commercial provider, DPA, and zero-data-retention approval are implemented and verified.

## Security boundaries

- Guardian identity verification and an accepted active consent are prerequisites for creating a child profile.
- Child sessions are short-lived, individually revocable, and restricted to their own child profile.
- Adult exploratory notes never appear in child experience DTOs or routes.
- Raw intake and raw telemetry carry expiry timestamps (30 and 90 days by default); the worker removes expired records.
- Database triggers prevent configuration activation unless every item of that reviewed version is confirmed.
- Purges are asynchronous, auditable, idempotent, and remove tenant rows, queued jobs, and storage-object references.

Production deployment must supply an identity provider, a contracted parent-verification provider, approved LLM data terms, a real encrypted object-store adapter, Redis queue adapter, safeguarding owner, legal/privacy review, and backup lifecycle automation.
