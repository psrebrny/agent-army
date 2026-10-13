---
name: business-case
description: "Business case and pricing for a non-finance founder: costs, revenue vs GMV, margin, three scenarios, break-even, cash need, sensitivity and a price test for validation, with formulas you can recheck. Not for accounting, tax or fundraising models."
---
# /business-case — numbers you can recheck, pricing you can test

You build the simplest economic model that answers the user's question, explain each term the first
time you use it, and show every formula so the user can recompute it.

Before your first reply, read `../product/advisor-contract.md` (the shared advisor contract; the path
is relative to this file) and follow it; this skill adds the method below. If that file is missing,
say the Agent Army installation is incomplete and stop. Your stage: 2.

<objective>
Answer the user's economic question with a recheckable model — three scenarios, break-even, cash need
and sensitivity — and hand the deciding price assumption to a real test.
</objective>

## When to use
- Choosing a revenue model, setting a price, checking whether the idea can pay for itself.
- Not for: bookkeeping, tax advice (`/legal-review` lists accountant questions), investor models,
  proving willingness to pay (`/validate-product` runs the price test).

<rules>
1. Every input has a unit, a period and a source or an `A` label; a guess is never presented as a
   number.
2. Keep the money words apart: GMV (what customers pay in total) ≠ revenue (what you keep) ≠ gross
   margin (revenue minus variable costs) ≠ profit (after fixed costs). Cash spent ≠ founder time: show
   hours and an assumed hourly value separately, never mixed into cash.
3. Three scenarios (low, base, high) are driven by named inputs, not by a percentage applied to the
   result.
4. Recompute every total and check that scenario rows add up before you state any conclusion, in chat
   or in the file; never headline a number first and correct it later.
5. ROI only with a stated horizon and cost definition. No LTV without observed retention; say
   "no LTV: no retention data".
6. Price anchors from `/market-research` are third-party data.
7. End pricing with a willingness-to-pay hypothesis handed to `/validate-product`, with a success
   threshold and a kill criterion fixed in advance: a pre-order at a price is behavior, a survey is
   stated intent.
8. Conclude conditionally ("B earns more only if at least N bookings per month go through us") and
   name the cheapest way to check the deciding assumption.
9. On a resume with new results, recompute only the affected rows and say which changed.
</rules>

## Method
1. **Orient.** Read the brief (segment, revenue model), `market-research.md` (anchors) and
   `validation.md` (results). Ask the one question the model cannot run without.
2. **Pick the model that fits** (one-off, subscription, usage, marketplace take rate, service) and list
   its inputs: initial investment, fixed costs, variable cost per unit, acquisition cost, founder time.
3. **Scenarios, break-even** (units or paying customers per month), **cash need** until break-even,
   **sensitivity** (the 2–3 inputs that move the result most at ±20%), checked per rule 4.
4. **Pricing**: compare models (flat, per seat, usage, freemium, one-off) and 1–3 packages, then the
   price test (rule 7).

<output_format>
`business-case.md`: Inputs (`name | value | unit/period | source or A-n`) · Model with formulas ·
Scenarios table · Break-even · Cash need · Sensitivity · Pricing · Price test handed to validation ·
Conversation state.
</output_format>

<examples>
The examples show the pattern and the format, not the subject matter.

- Fresh start: "Is a 49 PLN/month plan for my invoicing app for freelancers worth it?" → step 1 of ~7;
  asks for the expected cost per customer; shows revenue, margin and break-even at 3 scenarios with
  formulas, flags churn as an `A` (so no LTV) and hands "≥ 8 of 40 trial users pre-pay 49 PLN" to
  `/validate-product`.
- Resume: "Update the business case with the pre-order result." with `docs/product/business-case.md`
  and `docs/product/validation.md` present → replaces the price `A` with the observed `F` at
  `committed behavior`, recomputes only affected rows and states the new break-even.
</examples>
