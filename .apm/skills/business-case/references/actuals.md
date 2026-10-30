# Actuals mode — revenue vs plan

Read this when the user brings dated exports or asks how real money compares with the business case.
It adds a comparison method to `SKILL.md`; rules 1–9 there still apply (money words kept apart, no LTV
without retention, recompute only affected rows). Stage: 14.

## Inputs
- Dated exports in `docs/product/data/` (payment provider, bank, cost list), one period per file or a
  date column. Name the file and the period for every number you use. A payment provider listed as a
  data source in `metrics.md` is pulled as the contract's Stores section allows (aggregates only).
- An export with personal data (names, emails, card details, addresses) is not read further: say so,
  and ask the user for an aggregated export (per day or per customer ID).
- Conversion comes only from `metrics.md` Reads, and only when its `Collection status` is
  `verified (date, how)`. Otherwise list conversion under Not assessed and name `/product-metrics`.
- The scenarios table, inputs and formulas already in `business-case.md`. With no business case yet,
  say there is no plan to compare against and build the model first (the normal method).

## Method
1. **Count from the file** before you state any number: per period, GMV (what customers paid in
   total), payment fees, refunds and chargebacks, revenue (what you keep), variable costs, gross
   margin, fixed costs, profit, cash at period end, paying customers. Prices with VAT are shown net
   of VAT; a VAT question goes on the accountant list through `/legal-review`.
2. **Compare** each line with the low, base and high rows for the same period:
   `line | actual | low | base | high | tracks | source file`. Say which scenario the period tracks
   and which inputs explain the gap (more customers, lower price, higher fees). Never blend GMV into
   revenue to close a gap.
3. **Not enough signal**: with one period, or fewer than about 10 paying customers in the period,
   describe the period and do not re-forecast; say what volume or how many periods would change that.
   Retention and LTV stay out until at least two monthly cohorts have been observed for a full period
   each; until then say "no LTV: no retention data".
4. **Update the model** only where an actual replaces an assumption: the `A` input becomes an `F`
   with the file and date as its source, the affected rows are recomputed and checked (rule 4), and
   you say which rows changed. Register changes go to the brief as Change proposals.
5. **Decide**: one recorded decision per read — keep the plan, re-forecast (which rows, why), or a
   proposal. A price change is never made here: it is a price test handed to `/validate-product`, or,
   when it changes the revenue model, an ADR the user confirms. A cost or channel finding goes to the
   skill it points to (`/go-to-market` for acquisition cost, `/first-customers` for conversion in
   conversations).

## Output
Append one dated section under `Actuals vs plan` in `business-case.md`:
`Read YYYY-MM-DD · period · files` → the comparison table → which scenario it tracks → not enough
signal (what and why) → decision → affected rows recomputed. Earlier reads stay as they are.
