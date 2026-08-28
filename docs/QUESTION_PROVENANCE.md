# Question provenance and personalization

## What MindBridge questions are

MindBridge does **not** copy verbatim items from ISAA, ADOS, Vineland, or hospital web forms. That would require licensing and would turn the product into a clinical screening tool (explicitly out of charter).

Instead, each question is:

1. **Grounded** in published frameworks (RIASEC interest types, developmental play research, elementary leisure activity taxonomies)
2. **Personalized** to the child’s intake profile (ISAA scores, age, hyperfixation, sensory triggers)
3. **Adapted** by real usage (60% engagement filter across funnel layers)
4. **Framed** with the present-moment golden rule (enjoyment now, not future career)

## Framework sources (conceptual core)

| Framework | Role in MindBridge |
|-----------|-------------------|
| **Holland RIASEC** | 6 interest types → 30 childhood **play themes** (5 per type) |
| **Developmental play research** | Constructive, cooperative, symbolic, motor play activity stems |
| **ISAA (Indian Scale for Assessment of Autism)** | **Routing only** — picture vs text vs haptic; not question text |
| **Parent hyperfixation intake** | Selects best activity variant (trains, space, patterns, etc.) |
| **Engagement scores** | Top 60% advance each layer; finalists = strongest present-moment sparks |

## Code locations

| Component | Path |
|-----------|------|
| Clinical activity bank (variants + provenance tags) | `flutter_app/lib/features/strength_funnel/data/clinical_activity_bank.dart` |
| Personalization engine | `flutter_app/lib/features/strength_funnel/services/sector_prompt_personalizer.dart` |
| Funnel wiring | `flutter_app/lib/data/strength_funnel_repository.dart` |
| 60% adaptive filter | `flutter_app/lib/features/strength_funnel/data/strength_funnel_math.dart` |

## How personalization works

For each sector, the engine scores multiple activity variants:

- **+4** if variant matches parent-reported hyperfixation (e.g. trains → track/car activities)
- **+1** if child age fits variant range
- **−8** if variant conflicts with sensory triggers (e.g. drum → avoided when `loud_sudden_noise`)
- **+1.5** per highly engaged related sector from prior layers (same RIASEC family, score ≥ 0.65)

The winning variant becomes the question shown. The UI displays the **provenance framework** chip (e.g. `RIASEC-Realistic / DevPlay-Constructive`).

## Path to licensed clinical items (future)

To use **verbatim** clinical questions:

1. Obtain legal/ethics approval from instrument owners (NIMH for ISAA, etc.)
2. Map licensed items to sectors without violating charter (still present-moment, not diagnostic labels)
3. Document validation study with partner hospital

Until then, describe the product as **research-informed strengths exploration**, not a clinical test battery.
