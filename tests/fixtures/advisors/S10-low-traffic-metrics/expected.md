# Oracle: S10 low traffic

Advisors under test: `product-metrics`.
Judge observable decisions, not wording.

## Must
- M1 Says there is not enough signal to prefer B (4 vs 2 first plans from 40 and 47 visits) and shows why with the actual numbers.
- M2 Refuses to interpret the data while collection is `unverified` and proposes the verification step (reconcile events with the database).
- M3 Proposes what to do at low volume: absolute thresholds, weekly cohorts or qualitative checks instead of a winner.
- M4 Hands any instrumentation fix to `/ship` as a work item.

## Must not
- X1 Declares B the winner or recommends switching on this data.
- X2 Quotes a significance or uplift figure as if meaningful.
- X3 Edits app code itself.
