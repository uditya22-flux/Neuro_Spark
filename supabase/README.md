# MindBridge Supabase backend

This directory is the backend deployment boundary for the Supabase-only migration.

1. Create a Supabase project and enable Email/Phone providers in Auth.
2. Run `supabase db push` from this directory.
3. Configure the Send SMS Auth Hook to call `sms-hook`; the function expects `MSG91_AUTH_KEY` and `MSG91_TEMPLATE_ID` secrets.
4. Configure a Database Webhook on `pending_triggers` inserts to call `dispatch-fcm` with `{ "id": "{{ record.id }}" }`.
5. Provide `FCM_PROJECT_ID` and a short-lived `FCM_ACCESS_TOKEN` to `dispatch-fcm` as secrets. The service-account credential must never ship to Flutter.
6. Set `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and provider secrets only as Edge Function secrets.

The legacy `backend/` Express/Prisma service is not part of the production request path. New client reads/writes use Supabase Auth, Postgres/RLS, RPCs, Realtime, and Edge Functions. Firebase is limited to FCM transport; Firestore, Firebase Auth, Storage, Functions, Analytics, and Remote Config are not used.

The migration intentionally keeps adult notes and child experience in separate tables and policies. Never pass intake text, exports, secrets, or generated data to Graphify.
