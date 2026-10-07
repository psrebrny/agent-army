# Agent Army workflows and proposed product advisors

This is a working catalog for discussion. The five existing skills below are
available today. All product advisor names, responsibilities and artifact paths
are **proposals**, not installed commands or changes to the current pipeline.

## Available workflows

| Skill | Use it for | Main artifacts or result |
|---|---|---|
| `/bootstrap` | Tailor the team and control ownership to a repository | Local role contracts, `.agent-army/config.json`, runtime and selected adapter/control files |
| `/ship` | Execute or resume agreed engineering work | Implementation, verification evidence and execution state in `design-docs/`; relevant documentation; work ready for human review |
| `/new-agent` | Add a specialized local role | A local agent contract and its supported adapter output |
| `/new-skill` | Add a reusable local workflow with its own entry point | A local skill source, optional command wrapper and rendered skill |
| `/adapt-army` | Turn a recurring workflow problem into a targeted improvement | An Army Improvement Proposal and approved local changes |

`architect` and `docs-writer` are existing roles, not additional slash-command
skills. The architect owns technical planning; the documentation writer keeps
delivered behavior and significant architectural decisions documented.

## Proposed product advisors

These would be independently callable skills in the same package. They would
not become mandatory stages of `/ship`. Each starts from the user's current
question and existing evidence, supports discussion one consequential question
at a time, and updates a concise artifact when there is something worth keeping.

The paths below are suggested defaults in a target repository. Reuse equivalent
existing documents instead of creating a competing source of truth. Do not
create all these documents during installation or for every invocation.

| Proposed skill | Responsibility | Suggested artifact | Boundary |
|---|---|---|---|
| `/product-strategy` | Challenge the problem, audience, differentiation, feature priorities and monetization using several explicit business/customer perspectives | `docs/product/brief.md`: current product brief, assumptions, decisions and next question | Does not impersonate famous founders or treat agreement between AI perspectives as customer evidence |
| `/business-case` | Explain and model economic viability for the actual business model | `docs/product/business-case.md`; a reproducible calculation table when useful | Separates observations from estimates; does not invent demand, acquisition costs or retention |
| `/validate-product` | Design small falsifiable experiments, prepare materials, and evaluate supplied results | `docs/product/validation.md`: hypotheses, methods, thresholds, results and decisions | A planned test is not completed validation; contacting people requires authorization |
| `/go-to-market` | Choose an initial audience, positioning, offer, channels and campaign experiments | `docs/product/go-to-market.md` plus campaign copy and creative briefs as needed | Makes channel choices from evidence and constraints; publishing, outreach and ad spending require authorization |
| `/ux-review` | Inspect critical customer journeys, first-use experience, purchase flow, errors and accessibility | `docs/product/ux-review.md`: observed friction, proposed improvements and validation steps | A heuristic review is not a completed usability study or accessibility certification |
| `/legal-review` | Identify applicable legal questions from markets, customer type, data flows, contracts and dependencies | `docs/product/legal-review.md`: applicability, dated official sources, findings, remediation and unresolved questions | Findings must distinguish confirmed issues from uncertain applicability; no unsupported declaration of legal compliance |
| `/launch-readiness` | Assess whether customers can use, buy and receive support for the delivered product | `docs/product/launch-readiness.md`: evidence, blockers, accepted risks and launch checklist | Reuses technical/security/legal findings; does not deploy, publish or substitute for specialist review |

Start with these seven responsibilities. Pricing belongs in business case and
go-to-market; competitor research belongs in strategy; interviews belong in
validation. Add more entry points only when a recurring independent workflow
justifies them.

## Business case for a non-finance user

Explain terminology as it becomes relevant and ask for facts the user can
reasonably know. Recommend the model rather than asking the user to choose
financial metrics up front.

- Identify who pays, what they buy and the charging model.
- Separate initial investment, recurring fixed costs, variable delivery costs,
  acquisition costs and the founder's time. Distinguish cash spending from the
  economic cost of time.
- Separate transaction volume (GMV), revenue and profit. Use subscription,
  marketplace, usage-based or one-off economics only where applicable.
- Show pessimistic, base and optimistic scenarios with explicit assumptions,
  time horizons and reproducible calculations.
- Estimate break-even, cash needs and sensitivity to the assumptions that matter.
  Use customer acquisition cost, retention and lifetime value only to the extent
  the evidence supports them; flag speculative extrapolation.
- End with a conditional recommendation and the smallest next measurement that
  could change it. A spreadsheet forecast does not validate willingness to pay.

## Scope of the additional advisors

**UX review:** whether a new customer understands the offer, reaches first value,
can complete payment, recover from errors and use important flows accessibly.

**Legal review:** determine relevant jurisdictions and B2B/B2C scope first. Check
privacy and data handling, tracking/marketing, customer terms and subscriptions,
consumer rights, software/content licenses, and accessibility or sector-specific
rules where applicable. Include AI-related obligations only when relevant to the
actual product and role. Identify questions for a lawyer or accountant when the
facts or interpretation cannot be established. Check current official sources
for each audit instead of freezing legal requirements into the skill.

Useful official starting points:

- [EDPB small-business data protection guide](https://www.edpb.europa.eu/sme_en)
- [EDPB privacy by design and by default](https://www.edpb.europa.eu/topics/ai-and-technology/privacy-by-design-and-by-default_en)
- [Your Europe B2C distance selling](https://europa.eu/youreurope/business/selling-in-eu/selling-goods-services/ecommerce-distance-selling/index_en.htm)

**Launch readiness:** inspect the critical product and purchase paths, payment
failure/cancellation handling where relevant, support/contact information,
operational monitoring, recovery evidence, and a small measurement plan for
activation, repeat use and conversion. Reuse existing deployment checks and
auditors; classify untested recovery as unknown, not passed. Start with a small
set of useful signals, not a speculative analytics platform.

## Lightweight durable memory — proposed refinement

The existing `docs-writer` already supports short ADRs under `docs/adr/`. Refine
that behavior so completed engineering work leaves a small durable account of
significant accepted decisions:

- Record context, decision, reason, meaningful alternatives and consequences.
- Add status/date and useful implementation pointers. Keep each record short.
- Preserve confirmed reasoning from the decision discussion; do not infer why a
  choice was made merely from its implementation.
- Do not write an ADR for every fix or copy an entire blueprint into one.
- Distinguish an accepted decision from verified implementation and released
  behavior. Update or supersede a record when the decision changes.

The current `/ship` uses active `design-docs/` for execution and resumption.
Keep those while work is unfinished. Completed plans need not be an input to
product advisors: they can use the current README/product brief, relevant ADRs,
code and available customer evidence. Removing completed plans would be a
separate explicit housekeeping action after durable information is preserved.

Architectural ADRs do not replace a product brief: code and technical decisions
cannot establish the target customer, demand or willingness to pay. Missing
business context should be asked for or marked unknown.

## Suggested routes, not gates

| Starting situation | Useful route |
|---|---|
| New product idea | Strategy → rough business case → validation → revise strategy/economics → architect → `/ship` |
| Existing product with weak adoption | UX review + customer evidence → strategy → validation of the proposed improvement → architect → `/ship` |
| Preparing a paid launch | Business case + go-to-market preparation; legal review early enough to affect design → implementation/remediation → launch readiness |
| Product already launched | Read actual usage and acquisition results → revisit validation, economics or campaigns according to the weakest evidence |
| Small, well-understood engineering fix | `/ship`; no business workflow required |

Legal/privacy questions can affect initial design. Marketing experiments can
validate demand before implementation. These routes can loop or start midway;
there is no requirement to run every advisor or generate every artifact.
