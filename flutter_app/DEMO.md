# Hospital demo mode

Use this for live presentations to hospitals, government reviewers, and investors.

## Quick start (no sign-in)

1. Open the app → **Login** screen
2. Tap **Hospital demo (8 min walkthrough)**
3. Read the methodology sheet (optional) → **Start demo funnel**

## What the demo shows

| Step | Duration | What happens |
|------|----------|----------------|
| Intro | 1 min | Synthetic child **Aarav** (age 9), ISAA picture-first routing |
| Layer 1 | ~3 min | 6 play themes (one per RIASEC type) with picture cards |
| Layer 2 | ~2 min | 60% filter → 4 themes |
| Layer 3 | ~2 min | 2 finalist themes |
| Summary | 1 min | Guardian summary → handoff → child play |

## Build flags

```bash
# Dedicated demo APK (skips login, opens demo intro)
flutter run --dart-define=HOSPITAL_DEMO=true

# Custom funnel depth (default 3 layers in demo)
flutter run --dart-define=HOSPITAL_DEMO=true --dart-define=DEMO_FUNNEL_LAYERS=3
```

## Question engine (research basis)

See **Research** button in the demo banner, or the methodology sheet on login.

- **Golden rule:** present-moment enjoyment only — never career/job framing
- **RIASEC:** 30 childhood play themes (not adult job titles)
- **ISAA routing:** picture-first for low-verbal profiles
- **60% adaptive filter:** reduces demand avoidance while narrowing interests
- **Templates:** JSON-assembled prompts with forbidden-term validation; optional LLM for deep layers when server-enabled

This is strengths **exploration**, not clinical diagnosis.
