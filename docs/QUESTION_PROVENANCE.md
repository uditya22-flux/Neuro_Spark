# Question provenance — research-based, not random

## Principle

**Every funnel question maps to a named research construct.** Questions are **not** random demo text. They are **adapted** present-moment enjoyment prompts derived from published participation, interest, and play frameworks.

Wording is original (golden rule: “fun **right now**”) — we do **not** copy verbatim licensed clinical test items (ISAA, ADOS, etc.).

## Primary research sources

| Source | Citation | What we use |
|--------|----------|-------------|
| **CAPE** | King et al., 2007 — *Children’s Assessment of Participation and Enjoyment* | Leisure activity **domains**: skill-based, physical, recreational, social |
| **PAC** | King et al., 2004 — *Preferences for Activities of Children* | Routine / time / preference constructs |
| **RIASEC** | Holland, 1997 — *Making Vocational Choices* | Six interest types → 30 **childhood play themes** (not job titles) |
| **Symbolic play** | Parten, 1932; Smith, 2000 | Story, dramatic, imaginative play stems |
| **ISAA** | NIMH India | **Modality routing only** (picture/text/haptic) — not question text |

Full bibliography: `research_activity_registry.dart` → `kResearchBibliography`.

## How a question is chosen

1. **Registry** — `kResearchActivityStems` defines construct + prompt per stem ID  
2. **Bank** — `kClinicalActivityBank` links stems to RIASEC sectors + hyperfixation/sensory tags  
3. **Personalizer** — picks best stem for this child’s intake + prior engagement  
4. **60% filter** — only high-enjoyment themes advance (usage-based, not random)

## Code

| File | Role |
|------|------|
| `flutter_app/lib/features/strength_funnel/data/research_activity_registry.dart` | **Single source of truth** for research stems |
| `flutter_app/lib/features/strength_funnel/data/clinical_activity_bank.dart` | Sector + profile mapping to stems |
| `flutter_app/lib/features/strength_funnel/services/sector_prompt_personalizer.dart` | Child-specific selection |

## UI

Each question shows chips such as:

- `King et al., 2007 · CAPE`
- `Skill-based: puzzles / problem solving`
- `Matched parent-noted hyperfixation theme`

## What to tell hospitals

> “Activities are adapted from CAPE/PAC participation research and RIASEC interest theory, personalized to the child’s sensory profile and engagement. This is strengths exploration, not a licensed diagnostic battery.”
