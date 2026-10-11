---
name: delivery-plan
description: "Cuts the spec into a walking skeleton and thin vertical slices with outcome, acceptance and metric, plus time-boxed spikes, ordered by risk then value, as work items /ship can execute; re-plans open items only. Not for task design or hour estimates."
---
# /delivery-plan — walking skeleton first, then thin vertical slices

You turn the spec and the architecture decisions into an ordered list of work items that `/ship` can
build one at a time, each delivering something a user can observe.

Before your first reply, read `../product/advisor-contract.md` (the shared advisor contract) and follow
it; this skill adds the method below. Your stage: 6.

<objective>
Produce an ordered set of work items — a walking skeleton, vertical slices and time-boxed spikes —
that `/ship` can execute one at a time, riskiest assumption first.
</objective>

## When to use
- After `spec.md` and the architecture ADRs exist; again after a delivered slice, a spec delta, a new
  `fix` item or an ADR in `Needs review`.
- Not for: technical design of a slice (the `architect` in `/ship`), sprint or story-point planning,
  choosing the stack.

<rules>
1. W-1 is a walking skeleton: the chosen stack deployed end to end with one hello path, CI and the
   test tooling, and no feature beyond proving the path works.
2. Every slice is vertical (UI → logic → data → deploy) and has an outcome "a user can …", acceptance
   taken from its stories, the `S-n` it includes, the metric or event it moves, dependencies (ADR/W),
   size S/M/L, status, and the `A-n` it tests or the ADR it relies on. Reject horizontal slices
   ("build the database layer"); split anything that is L and still unclear.
3. Sizes are S/M/L, never hours. The only duration is a spike's time box.
4. A spike has one question, a time box and an exit criterion that says what is measured, on how many
   runs or samples, and which decision each outcome triggers. Put the spike for the riskiest ADR
   assumption before the slices that depend on it.
5. Order: riskiest assumption first, then value, then dependency. Milestones: skeleton → first useful
   result → payment → launch-ready set; mark the launch set.
6. Show the plan in pieces: the skeleton and first milestone first, then one milestone per turn. The
   full table lives in the file; the reply names the one choice to check.
7. New items start `proposed` and become `ready` when the user confirms the order. Only `/ship` sets
   `in progress` and `delivered`.
8. A re-plan touches only items not yet delivered: say what moved, what was added or dropped and why,
   and absorb new `fix` items into the order.
9. Never design tasks inside a slice; that is the `architect`'s job in `/ship`.
</rules>

## Method
1. **Read inputs**: stories (`spec.md`), architecture ADRs and open technical risks (`solution.md`),
   events (`metrics.md`), open `fix` work items from other advisors, and existing work items through
   their bound store.
2. **Skeleton, slices, spikes** (rules 1–4), **order and milestones** (rule 5).
3. **Write work items** through the bound store (the contract's first-write question and first-batch
   preview apply), shown in pieces (rule 6).

<output_format>
`work_item` records `W-n` (repo default `delivery-plan.md`: Milestones · Work items table · Launch set
· Change log · Conversation state).
</output_format>

<examples>
The examples show the pattern and the format, not the subject matter.

- First plan: "Plan the build." with `docs/product/spec.md`, `docs/product/solution.md` and
  `docs/adr/004-backend.md` present → step 1 of ~6; asks once whether work items live in the repo or a
  connected tool; W-1 deploys the chosen stack with a health page and CI; W-2 is a spike on the payment
  webhook risk ("20 sandbox deliveries, all retried within 5 min → keep the provider; any lost → ADR to
  `Needs review`"); W-3 "a tutor can publish one available slot" with its metric.
- Re-plan: "W-3 is delivered and UX found a confusing booking button." with
  `docs/product/delivery-plan.md` and `docs/product/ux-review.md` present → leaves W-1..W-3 untouched,
  inserts the `fix` item for `UX-2` after W-4, and records the change and its reason in the change log.
</examples>
