# Run the synthetic cloud Engine 2 demo

This is a fictional-builder showcase only. It uses an anonymous Supabase
identity, never sends parent free text to OpenAI, and keeps the OpenAI key out
of Flutter.

## One-time Supabase setup

The Edge Function `synthetic-engine2-next-task` is deployed. Apply the
database migration once before running the app:

1. Open the linked Supabase project, then **SQL Editor** → **New query**.
2. Open `supabase/migrations/20260723020000_synthetic_engine2_cloud_demo.sql`
   in this repository, copy its entire contents into the query, and select
   **Run**.
3. Confirm the project secrets include `OPENAI_API_KEY` and `OPENAI_MODEL`.
   `SYNTHETIC_ENGINE2_CLOUD_ENABLED=true` enables this separate demo endpoint.

If the database password is available locally, the migration can instead be
applied from PowerShell:

```powershell
$env:SUPABASE_DB_PASSWORD = 'your-database-password'
npx supabase@latest db push
Remove-Item Env:SUPABASE_DB_PASSWORD
```

Do not put the database password, OpenAI key, Groq key, or service-role key in
`flutter_app/.env`.

## Run Flutter

Ensure `flutter_app/.env` contains only the public Supabase URL and anon key,
then run:

```powershell
cd D:\mind_bridge\mind_bridge_project\flutter_app
flutter pub get
flutter run --dart-define=SYNTHETIC_CLOUD_DEMO_MODE=true
```

## What should happen

1. The guardian intake screen opens without the normal sign-in UI.
2. Intake details are mapped locally to a fixed visual world and sensory
   settings; raw text does not go to the cloud.
3. Layer 1 issues 30 themed, word-free play tasks. Each selected option is
   stored as fictional demo telemetry.
4. A correct option automatically loads the next task. A wrong option gently
   returns to the same task without a failure screen.
5. The server applies the fixed 40% accuracy, 30% recovery, 20% engagement,
   and 10% speed formula, narrowing 30 → 10 → 8 → 7 → 6 → 5 → 4 → 3 → 2 → 1.
6. Layer 10 ends in Calendar, Constellation, or the neutral Exploring screen,
   depending on the final deterministic sector mapping.

## Quick troubleshooting

- `relation synthetic_engine2_demo_sessions does not exist`: run the SQL
  migration above.
- `Synthetic Engine 2 is temporarily unavailable`: confirm anonymous sign-in
  is enabled, the function is deployed, and the two OpenAI secrets exist.
- Flutter starts locally but never reaches cloud tasks: run with exactly
  `SYNTHETIC_CLOUD_DEMO_MODE=true`, not builder or local prototype mode.
