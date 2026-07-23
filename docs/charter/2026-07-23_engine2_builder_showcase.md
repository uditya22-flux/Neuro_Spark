# Engine 2 builder-showcase charter change

Status: Approved by the project owner in this work session on 2026-07-23.

## Limited scope

This approval permits a compile-time, builder-only showcase of Engine 2A and
Engine 2B. It may use an adult builder's deliberately fictional interactions
and timing, held only in memory for the running session, to demonstrate
adaptive play routing across Layers 1 through 10.

The implementation must not accept or persist real child or guardian data in
this mode. It must not create a clinical diagnosis, child-facing score,
prediction, employment signal, education-placement signal, or adult report.

## Showcase behavior

- Layer 1 may present 30 non-verbal, themed play tasks, one per defined play
  mechanic, and calculate an in-memory routing score from the fictional
  session.
- The session may select an active Top 10 for Layer 2 and narrow the active
  pool through Layer 10 solely to demonstrate the adaptive state machine.
- The final in-memory mechanic may route to Calendar Genius or Constellation
  Mapper only when it maps to those existing training experiences; all other
  outcomes remain in a neutral exploration state.

## Non-negotiable boundaries

- This mode is enabled only with `--dart-define=BUILDER_SHOWCASE_MODE=true`.
- It must remain separate from normal guardian, child-profile, and cloud-LLM
  data paths.
- No scores, rankings, or telemetry are written to Supabase in this mode.
- Any future real-data implementation requires the production approvals in
  `AGENTS.md` and `RELEASE_GATES.md`.
