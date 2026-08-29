# MindBridge — Field Test Intake Data Sheet

Printable version: open **`INTAKE_TEST_DATA_SHEET.html`** in Chrome → `Ctrl+P` → **Save as PDF**.

## Quick start

| Step | Action |
|------|--------|
| Login | **Field test sign-in** (one tap) on login screen |
| Alt login | `mindbridge.pilot.test@gmail.com` / `MindBridge2026!` |
| Flow | Consent → Intake (3 steps) → Strength funnel (10 layers) → Child play |

**Do not use Hospital demo** for real kid testing (only 3 layers).

---

## ISAA scores (Clinical step)

Each slider: **1** = minimal support need → **5** = high support need.

| Domain | What it changes in the app |
|--------|---------------------------|
| Speech & Communication **≥ 4** | Picture-first, visual-only hints, **no text-heavy** questions |
| Speech **≤ 2** | Text prompts allowed, simple text instructions |
| Sensory Aspects **≥ 4** | Muted audio, calm dark theme, slower pacing |
| Cognitive **≤ 2** | Easier starting difficulty (tier 1) |
| Cognitive **≥ 4** | Harder starting difficulty (tier 3) |

---

## Parent step options (exact labels in app)

**Hyper-fixation:** Trains & Vehicles · Space & Astronomy · Geometry & Patterns · Animals & Nature · Clocks & Numbers

**Sound triggers:** High-frequency beeps · Sudden loud chime · Background music loops · Voice-over narration · Applause or cheering

**Visual triggers:** Rapid flashing · High contrast red/yellow · Parallax scrolling · Floating UI elements · Busy animated backgrounds

**Vibration:** Prefers haptics · No vibrations · Neutral

---

## Test Profile A — Picture-first (Arjun)

| Field | Value |
|-------|-------|
| Name | Arjun |
| Age | 9 |
| Hyper-fixation | Geometry & Patterns |
| Sound triggers | Sudden loud chime |
| Visual triggers | Busy animated backgrounds |
| Vibration | Neutral |
| Social | 3 |
| Emotional | 3 |
| **Speech** | **5** |
| Behavior | 3 |
| **Sensory** | **4** |
| Cognitive | 2 |

**Expect:** Picture cards · Visual-only hints · Muted · Calm dark · Touch feedback on

---

## Test Profile B — Text-friendly (Meera)

| Field | Value |
|-------|-------|
| Name | Meera |
| Age | 10 |
| Hyper-fixation | Clocks & Numbers |
| Triggers | none |
| Vibration | Neutral |
| Social | 2 |
| Emotional | 2 |
| **Speech** | **2** |
| Behavior | 2 |
| Sensory | 2 |
| **Cognitive** | **4** |

**Expect:** Text prompts · Simple text · Subtle sound effects · Soft pastel · Difficulty tier 3

---

## Test Profile C — High sensory + touch (Kabir)

| Field | Value |
|-------|-------|
| Name | Kabir |
| Age | 8 |
| Hyper-fixation | Animals & Nature |
| Sound | High-frequency beeps, Sudden loud chime |
| Visual | Rapid flashing, Floating UI elements |
| Vibration | **Prefers haptics** |
| All ISAA | Social 4, Emotional 4, Speech 4, Behavior 4, Sensory **5**, Cognitive 3 |

**Expect:** Touch & glow / pictures · Muted · Calm motion · Touch feedback on

---

## Test Profile D — Trains theme (Riya)

| Field | Value |
|-------|-------|
| Name | Riya |
| Age | 11 |
| Hyper-fixation | **Trains & Vehicles** |
| Sound | Background music loops |
| Vibration | Prefers haptics |
| All ISAA | 3 each |

**Expect:** `terracotta_train` theme on environment preview

---

## Test Profile E — Balanced (Dev)

| Field | Value |
|-------|-------|
| Name | Dev |
| Age | 9 |
| Hyper-fixation | Space & Astronomy |
| Triggers | none |
| Vibration | Neutral |
| All ISAA | 3 each |

**Expect:** `cosmic_space` theme · Pictorial guide cards · Ambient binaural

---

## Verification checklist (per child)

- [ ] Environment preview shows expected theme + audio + instruction style
- [ ] Funnel shows “Customized for [name]” banner with correct chips
- [ ] Step 1 activity works (tap/stack/sort) before slider unlocks
- [ ] App bar shows **Layer X of 10**
- [ ] Layer 1 has **30** play themes (Field test path, not Hospital demo)
