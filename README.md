# MindBridge private beta

MindBridge is a guardian-authorized accessibility and strengths-exploration
experience. The private beta contains only Calendar Genius and Constellation
Mapper. It is not a diagnostic, screening, assessment, prediction, or career
product.

## Layout

- `backend/` — Express/TypeScript API, Prisma/PostgreSQL schema, worker, and OpenAPI contract.
- `flutter_app/` — Guardian and child Flutter client.
- `infra/` — AWS Mumbai Terraform foundation.

## Local development

1. Copy `backend/.env.example` to a non-committed `.env` file and use only
   synthetic development data.
2. Start PostgreSQL and Redis using the included compose configuration.
3. From `backend`, install dependencies, generate the Prisma client, run the
   migration, then start the API and worker in separate terminals.
4. From `flutter_app`, fetch packages and run the Flutter client.

The initial migration includes a PostgreSQL trigger that rejects activation of
any sensory configuration until every item has explicit guardian confirmation.

## Production gate

Do not deploy until every item in `RELEASE_GATES.md` has an accountable owner
and evidence. Terraform is deliberately a foundation, not a production apply
until AWS account, domain, legal, safeguarding, DPA/ZDR, and parent-verification
requirements have been supplied.
