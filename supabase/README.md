# MindBridge Supabase backend

## Hosted backend (all devices — default)

Project **Mind_Bridge** is live at:

- **API:** https://zkskozozwjjzwvnkmeqb.supabase.co
- **Dashboard:** https://supabase.com/dashboard/project/zkskozozwjjzwvnkmeqb

Migrations and edge functions are deployed. The Flutter app defaults to this URL, so builds on **phone, tablet, and web** talk to the same cloud backend without extra config.

```bash
cd flutter_app && flutter run
# or release builds:
flutter build apk
flutter build ios
flutter build web
```

Guardians sign in on the login screen, then intake + strength funnel sync remotely.

## Local dev (optional)

Use this only when iterating against Docker on your machine:

```bash
bash scripts/start-backend.sh
supabase functions serve
cd flutter_app && flutter run --dart-define=USE_LOCAL_SUPABASE=true
```

Local mail OTP: http://127.0.0.1:64324

## Production checklist

1. Enable Email/Phone providers in Supabase Auth dashboard.
2. Configure Send SMS Auth Hook → `sms-hook` (`MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`).
3. Database Webhook on `pending_triggers` inserts → `dispatch-fcm`.
4. Set Edge Function secrets via `supabase secrets set`.

The legacy `backend/` Express service is not used in production.
