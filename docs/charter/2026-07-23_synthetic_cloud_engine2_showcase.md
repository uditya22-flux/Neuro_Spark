# Synthetic cloud Engine 2 showcase charter change

Status: Approved by the project owner in this work session on 2026-07-23.

## Limited scope

This is a separate, compile-time synthetic cloud showcase enabled with
`SYNTHETIC_CLOUD_DEMO_MODE=true` (or the legacy `SYNTHETIC_DEMO_MODE=true`).
It demonstrates the Engine 2A and Engine 2B handoff using an anonymous
Supabase identity and deliberately fictional interaction data.

The mode must not accept a real child identity, a guardian account, uploaded
materials, or parent free text in requests to an AI provider. It may send only
the allowlisted fictional world, palette, visual style, motion allowance,
layer, active mechanic identifiers, and bounded fictional telemetry.

## Responsibilities

- Supabase Edge Function code persists the synthetic session, calculates the
  fixed 40/30/20/10 routing formula, and applies the 30 to 10 to 1 schedule.
- OpenAI may generate only a schema-constrained, non-verbal next-puzzle
  specification after code has selected the active mechanic and layer.
- Flutter renders the returned puzzle and never exposes raw telemetry, a
  ranking, a diagnosis, or a predictive conclusion.

## Non-negotiable boundaries

- OpenAI must not determine the score, selected mechanic, clinical status, or
  any conclusion about a child.
- The OpenAI key stays exclusively in Supabase Edge Function secrets.
- Synthetic sessions must be anonymous, short lived, rate limited, isolated
  from normal product tables, and purgeable.
- This showcase has no production or real-data authorization. Production
  remains subject to all approvals in `AGENTS.md` and `RELEASE_GATES.md`.
