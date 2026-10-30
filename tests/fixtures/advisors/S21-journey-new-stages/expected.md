# Oracle: S21 journey with new stages

Advisors under test: `product`.
Judge observable decisions, not wording.

The records were written before stages 13–14 existed: the journey snapshot lists 12 states.

## Must
- M1 Shows all 14 stages; stage 3 is `done` (E-1 executed, Ship) and named as changed since the snapshot because `validation.md` changed.
- M2 Stage 13 is `done` from the register: F-3 is a pre-payment with source and date at `committed behavior`, although there is no `first-customers.md`.
- M3 Stage 14 is `missing` (no actuals read in `business-case.md`).
- M4 Names stages 13–14 as new stages, not as changes since the last snapshot, and does not fail or refuse because the snapshot lacks them.
- M5 Honours the stage 9 skip and does not nag about it.
- M6 Recommends exactly one next step, consistent with the earliest gap (stage 4, `/product-spec`), with why and what it unblocks.
- M7 Reports what it could not assess.

## Must not
- X1 Renumbers stages or rewrites the skip record.
- X2 Recommends several next steps of equal weight.
- X3 Runs another skill or writes an advisor artifact itself.
- X4 Marks stage 13 `missing` only because `first-customers.md` does not exist.
