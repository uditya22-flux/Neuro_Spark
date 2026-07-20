# MindBridge private beta

MindBridge is a guardian-authorized accessibility and strengths-exploration
experience. The private beta contains only Calendar Genius and Constellation
Mapper. It is not a diagnostic, screening, assessment, prediction, or career
product.

## Layout

- `backend/` — legacy Express/Prisma implementation retained for migration reference; not the production request path.
- `supabase/` — production data, RLS, RPCs, Realtime, and Edge Functions.
- `flutter_app/` — Guardian and child Flutter client.
- `infra/` — AWS Mumbai Terraform foundation.

## Local development

1. Copy `backend/.env.example` to a non-committed `.env` file and use only
   synthetic development data.
2. Create/link a Supabase project and run `supabase db push` from `supabase/`.
3. Configure the Edge Function secrets and database webhook described in `supabase/README.md`.
4. From `flutter_app`, fetch packages and run the Flutter client with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

The initial migration includes a PostgreSQL trigger that rejects activation of
any sensory configuration until every item has explicit guardian confirmation.

## Production gate

Do not deploy until every item in `RELEASE_GATES.md` has an accountable owner
and evidence. Terraform is deliberately a foundation, not a production apply
until AWS account, domain, legal, safeguarding, DPA/ZDR, and parent-verification
requirements have been supplied.
