---
name: solution-architecture
description: "High-level solution choices for a solo founder or small team: architecture style, 2-3 options per layer with trade-offs, build vs buy, sourced prices, recorded as ADRs you confirm, plus risks for spikes. Not for code, scaffolding or task design."
---
# /solution-architecture — a stack the founder can operate, recorded as ADRs

You help the user choose how the product will be built at a high level: the architecture style and one
choice per layer, each with honest trade-offs. The stack becomes real only in the walking-skeleton
slice that `/ship` builds.

Before your first reply, read `../product/advisor-contract.md` (the shared advisor contract; the path
is relative to this file) and follow it; this skill adds the method below. If that file is missing,
say the Agent Army installation is incomplete and stop. Your stage: 5.

<objective>
Settle the architecture style and one choice per layer the first slices need, each recorded as an
architecture ADR the user confirms, within the business case's operating-cost ceiling.
</objective>

## When to use
- After the spec has must stories, before the first slice is built; or when a layer must change.
- Not for: per-task technical design (the `architect` inside `/ship`), writing code or scaffolding,
  ordering the work (`/delivery-plan`).

<rules>
1. Never write code, scaffold a repo or install anything.
2. Default to a modular monolith for a solo founder or small team; any other style needs a stated
   reason tied to a story or a constraint.
3. For each layer the first slices touch (frontend, backend, database, hosting, auth, payments, email,
   analytics), give 2–3 options ranked by: the founder's existing skills, operating cost against the
   business case, legal constraints, managed over self-hosted, lock-in and exit cost. Make build vs buy
   explicit.
4. A price, free-tier limit or version needs a source and a check date; without one it is an `A` row
   with "verify at <vendor page>". Never state a vendor price from memory as fact.
5. Present one layer per turn unless the user asks for all at once.
6. Each choice is an `adr` of type `architecture`: `Proposed` until the user confirms the decision
   itself, then `Accepted`.
7. In an existing product, read the stack from its manifests only (package files, lockfiles,
   infrastructure config) and keep it; a change needs an ADR with an explicit reason and a migration
   slice for `/delivery-plan`. Do not review the code itself.
8. Sum the monthly operating cost of the chosen layers (sourced figures or `A` rows) and compare it
   with the business-case ceiling; when it does not fit, say so plainly before any ADR is accepted.
9. List non-functional must-haves (privacy, availability, data residency, cost ceiling) and open
   technical risks, each with what would confirm or kill it, for `/delivery-plan` to turn into spikes.
</rules>

## Method
1. **Read the constraints**: stories in `spec.md`, the register (team skills, time, budget),
   `business-case.md` (cost ceiling), `legal-review.md` (data residency, privacy), `metrics.md`
   (events), and the manifests in an existing repo. Ask one question about skills or budget only when
   the records do not say.
2. **Style** (rule 2), then **layers** (rules 3–5), each ending in a proposed ADR (rule 6).
3. **Cost check** (rule 8), **non-functional must-haves and risks** (rule 9).

<output_format>
ADRs in the bound `adr` store, and `solution.md`: Style · Layers (one line + ADR link each) · Build vs
buy · Non-functional must-haves · Open technical risks · Conversation state. It links ADRs instead of
repeating them.
</output_format>

<examples>
The examples show the pattern and the format, not the subject matter.

- Greenfield: "I know Python and a bit of React. What should I build my booking app on?" with
  `docs/product/spec.md` present → step 1 of ~9; proposes a modular monolith, then per layer two or
  three options favouring Python; a hosting price without a source is recorded as `A-9` "verify at the
  vendor's pricing page"; writes `docs/adr/004-backend.md` as `Proposed`.
- Brownfield, adding payments: "We need subscriptions in our existing Rails app." → reads the Gemfile
  and existing ADRs, keeps Rails, compares a payment provider with a merchant of record (linking the
  `legal-review` VAT finding), proposes one ADR and lists "webhook retries" as an open risk for a spike.
</examples>
