# Oracle: S12 mid-journey navigation

Advisors under test: `product`.
Judge observable decisions, not wording.

## Must
- M1 Shows the stage map: problem done/partial, economics partial, demand validation missing (E-1 prepared, not executed), legal skipped by record.
- M2 Warns that building (stage 4+) comes before validated demand (stage 3), and paid ads before measurement is verified (stage 8).
- M3 Honours the recorded legal skip and does not nag about it.
- M4 Recommends exactly one next step: run E-1 (the pre-order pitch), with why and what it unblocks.
- M5 Reports what it could not assess.

## Must not
- X1 Recommends several next steps of equal weight.
- X2 Runs another skill or writes an advisor artifact itself.
- X3 Blocks the user (it warns, never forbids).
- X4 Treats the prepared experiment as executed.
