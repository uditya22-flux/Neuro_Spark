# Field testing — real app (10 layers, not hospital demo)

## Important: two modes on the login screen

| Button | Layers | Use when |
|--------|--------|----------|
| **Field test sign-in** | **All 10 layers** · 30 play themes in layer 1 | Kids/guardians installing the app for real try-outs |
| Hospital demo (full / quick) | 3 layers only | Short hospital walkthrough with pre-filled answers |

For field testing with children, always use **Field test sign-in** (or your own confirmed account). Do **not** use Hospital demo.

## Fastest way to test today

1. Run the app (Chrome, Windows, or tablet):
   ```bash
   cd flutter_app
   flutter run -d chrome
   ```
2. On the login screen tap **Field test sign-in** (one tap — no password typing).
3. Accept **consent** → complete **intake** → **strength funnel (layers 1–10)** → **child play**.

Layer 1 shows **30 play themes**. Layers 2–5 keep themes the child scored ≥60% fun. Layers 6–10 deepen into the top 2–4 interests (no more elimination). Plan **45–90 minutes** with breaks; guardian stays present.

## Install on kids’ tablets (APK)

Build without the hospital demo flag so the app defaults to the full funnel:

```bash
cd flutter_app
flutter build apk --release
```

Share the APK from `build/app/outputs/flutter-apk/app-release.apk`. On each device:

1. Install APK (allow unknown sources if needed).
2. Open app → **Field test sign-in** (or guardian creates account and confirms email).
3. Guardian completes consent + intake; child does funnel layers with guardian nearby.
4. App bar shows **Layer X of 10** during the funnel.

## Pilot guardian account

| Field | Value |
|-------|--------|
| Email | `mindbridge.pilot.test@gmail.com` |
| Password | `MindBridge2026!` |

This account is **email-confirmed** on the hosted Supabase project.

## If you create your own account

Hosted Supabase requires **email confirmation** before sign-in works. After **Create account**, check your inbox, confirm, then **Sign in**.

Or use **Sign in with email code** (6-digit OTP) — no password needed.

## Real child testing flow

```
Sign in (Field test) → Consent → ISAA intake → Parent personalization → Environment preview
  → Strength funnel layers 1–10 (picture cards; ≥60% fun advances)
  → Guardian summary → Handoff → Child play session
```

DigiLocker is **not** required for this beta.

## Disable pilot button for production builds

```bash
flutter build apk --dart-define=PILOT_LOGIN=false
```
