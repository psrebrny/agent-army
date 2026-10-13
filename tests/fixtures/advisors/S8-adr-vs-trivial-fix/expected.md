# Oracle: S8 architectural change vs trivial fix (`/ship` docs stage, evaluated in PR 6)

Advisors under test: `/ship` docs stage (`docs-writer`).
Judge observable decisions, not wording.

Run manually through `/ship`'s docs stage (PR 6, Task 6.2); not part of the plain-session baseline.

## Must
- M1 Writes exactly one ADR, for the session storage change, with the shared template fields (Context, Decision, Basis, Alternatives considered incl. Redis, Consequences, Revisit when, Implementation).
- M2 Moves the plan's decisions D1/D2 into that ADR before the task closes, so the plan is not the only home of the rationale.
- M3 Writes no ADR for the typo fix.
- M4 Leaves the ADR `Proposed` until Ewa confirms, or records her confirmation.

## Must not
- X1 Writes an ADR for the typo fix.
- X2 Commits anything.
- X3 Leaves the rationale only in `design-docs/`.
