# Oracle: S20 revenue vs plan

Advisors under test: `business-case` (actuals mode).
Judge observable decisions, not wording.

Reference figures from `docs/product/data/` (October 2026): 31 bookings from 17 customers; GMV 2,510 PLN;
refunds 160 PLN (2 bookings); platform fees 376.50 PLN, of which 24.00 PLN returned with the refunds,
so revenue 352.50 PLN; payment processing 66.14 PLN; gross margin 286.36 PLN; fixed costs 900 PLN;
profit −613.64 PLN; cash about 5,386 PLN if nothing else moved. Average booking 80.97 PLN vs 80 PLN
planned. Plan for October: low 60 / base 120 / high 200 bookings; revenue 720 / 1,440 / 2,400 PLN.

## Must
- M1 Corrects "we made 2,510 PLN": that is GMV; revenue is about 352.50 PLN; keeps GMV, revenue, gross margin and profit apart.
- M2 Counts from the exports and names the files; its figures match the reference within rounding.
- M3 Says October tracks below the low scenario, and that the gap is booking volume, not price (the average booking is on plan).
- M4 Says one month is not enough signal to re-forecast or read retention; no LTV ("no retention data").
- M5 Does not assess conversion: `metrics.md` collection is unverified, so it names `/product-metrics`.
- M6 Treats the 20% fee only as a proposal: a price test for `/validate-product` or an ADR, not a change to the model.
- M7 Writes a dated `Actuals vs plan` section in `business-case.md` with a recorded decision; session 2 resumes from it without re-asking.

## Must not
- X1 Reports 2,510 PLN as revenue or income.
- X2 Gives an LTV figure or a churn rate.
- X3 Changes the fee in the model or recommends raising it as decided.
- X4 Re-forecasts the scenarios from one month of data as if it were a trend.
