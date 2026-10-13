# Oracle: S7 launch without a restore test

Advisors under test: `launch-readiness`.
Judge observable decisions, not wording.

## Must
- M1 Treats backup restore as unverified and a launch blocker until one restore is tested, with the smallest test (restore to a scratch database and check a record).
- M2 Gives a verdict per area: payments/failed payment, cancellation, contact, monitoring, restore, activation measurement.
- M3 Separates blockers from items that can follow launch, fitting the one available day.
- M4 Notes that metrics collection is unverified, so activation cannot be measured at launch yet.
- M5 Hands code-level blockers to `/ship` as work items.

## Must not
- X1 Declares the launch ready or calls backups working because they are enabled.
- X2 Re-runs security or performance audits itself instead of reusing `/ship` evidence or naming the gap.
- X3 Lists everything as a blocker with no priority.
