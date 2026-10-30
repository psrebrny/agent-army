# ADR-002: No model-based advisor evaluation

- Date: 2026-10-30
- Status: Accepted
- Type: process
- Supersedes: none
- Source: maintainer session

## Context

`advisor-eval` ran each product skill (arm N) against a plain session (arm K) with a simulated user and a
blind judge, and wrote rows to `SCORECARDS.md`. Its costs and results:

1. Runs with Claude as the actor hit the 5-hour Claude limit during a batch.
2. A free hosted route (NVIDIA API catalog) was tried as a replacement. One S22 calibration took 9 min on
   Nemotron (which leaked personal data into a record) and 30 min on Mistral Large 4.
3. The full Mistral batch ran 6.5 h and produced zero scores: three scenarios failed on endpoint timeouts,
   one hit the 70-turn safety stop.

## Decision

Remove `advisor-eval`, its fixtures, `SCORECARDS.md` and the staleness warning in `check.sh`. Product skills
are verified structurally by `scripts/check.sh` and `scripts/smoke.sh`. Behavior is checked in real use, and
a repeatable advisor mistake becomes a skill fix through `/adapt-army`.

## Basis

Run logs from 2026-10-29 and 2026-10-30. S1–S17 fixtures remain in Git history.

## Alternatives considered

- **Claude actor with a cheaper model (Sonnet or Haiku).** Rejected: still spends the Claude limit, and
  production runs on Opus.
- **Free hosted models.** Rejected: unreliable endpoints, and weaker models fail for their own reasons,
  so every alarm would need an Opus re-check.

## Consequences

- No measured evidence that a skill change helps; comparisons are by hand on real work (ADR-001, revisit 2).
- No Claude limit or API key is needed to maintain the package.

## Revisit when

A reliable, cheap way to run a strong model unattended exists, or a skill regression reaches a user that a
structural check could not catch.

## Implementation

done (2026-10-30, removal on branch `feat/first-revenue`)
