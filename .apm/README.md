# Agent Army skills catalog

Agent Army 0.4.0 installs 19 skills: five engineering workflows and fourteen product skills (thirteen
advisors plus the `/product` navigator). Every skill is optional and callable on its own. Nothing runs
another skill for you: `/product` recommends a step, you run it.

Call a skill as a slash command (`/product`) where your tool offers installed skills that way (Claude
Code does); otherwise ask the agent to follow the skill's `SKILL.md` in your tool's skill folder
(`.agents/skills/<name>/` or, for Claude, `.claude/skills/<name>/`).

## Not sure where to start? Run `/product`

`/product` reads your product records and shows where you stand on a 12-stage journey, which earlier
gaps put your next move at risk, and **one** next step. It judges stages by evidence, not by whether a
file exists. It warns, never blocks, and never starts another skill or `/ship`.

- No product records yet → every stage is `missing` and the step is `/product-strategy`.
- A stage that does not apply to you → `/product` asks "skip stage N on purpose?"; a yes with a reason
  becomes a `skip` record (`stage | reason | date | revisit when`) and the stage stops being flagged.
- `/product stores` shows where each record type lives and moves one to another store on request.

| # | Stage | Done when | Skills | Should precede |
|---|---|---|---|---|
| 1 | Problem & audience | register has Problem + Audience, ≥ 1 `F` from real conversations (≥ stated intent) | strategy, market-research, red-team | 3 |
| 2 | Economics & pricing | business case has 3 scenarios, pricing model, break-even; key `A` listed with tests | business-case | 4 |
| 3 | Demand validated | ≥ 1 executed experiment with result vs threshold → Ship | validate-product | 4 |
| 4 | MVP scoped | stories with acceptance and priority, out of scope listed | product-spec | 5, 6 |
| 5 | Architecture decided | architecture ADRs `Accepted` for every layer the first slices touch | solution-architecture | 6 |
| 6 | Delivery planned | walking skeleton + slices with outcome, acceptance and metric exist as work items | delivery-plan | 7 |
| 7 | Built | the slices planned for launch are `delivered` with evidence | `/ship` | 11 |
| 8 | Measurement verified | metrics collection status `verified` | product-metrics | 10 (paid spend), any data read |
| 9 | Legal & formalities | no open launch-blocking legal item | legal-review | 11 |
| 10 | Go-to-market ready | predictions + budget caps exist | go-to-market, red-team | 11 |
| 11 | Launch ready | launch verdict without blockers | launch-readiness, ux-review | 12 |
| 12 | Post-launch loop | weekly metric reads; post-launch findings recorded | product-metrics, validate-product, ux-review | — |

Each stage is `done`, `partial`, `missing`, `stale` (an ADR it relies on is `Needs review`, or an
assumption behind its decision was disproved) or `skipped`. "Should precede" is advice: you can start
anywhere, and `/product` names the risk of an earlier gap instead of stopping you.

## Where records live

Product skills work on record types with stable IDs, not on fixed paths. By default everything lives in
the repo as Markdown; an existing equivalent document or ADR directory takes precedence.

| Type | ID | Written by | Repo default |
|---|---|---|---|
| register (facts, assumptions, decisions) | `F-n` `A-n` `D-n` | `product-strategy`; others add Change proposals | `docs/product/brief.md` |
| artifact (one narrative file per advisor) | — | each advisor | `docs/product/<advisor>.md` |
| adr | `ADR-NNN` | advisors, `docs-writer` in `/ship` | `docs/adr/NNN-<slug>.md` |
| story | `S-n` | `product-spec` | `docs/product/spec.md` |
| work_item | `W-n` | `delivery-plan`; advisors for fixes | `docs/product/delivery-plan.md` |
| prediction | `P-n` | `go-to-market` | `docs/product/go-to-market.md` |
| skip | — | `/product` | `docs/product/journey.md` |
| data (your exports, no personal data) | — | you | `docs/product/data/*.csv` |

You can keep a type in any tool your agent environment already has a connector for (a tracker, a docs
tool). The choice is recorded per project in `.agent-army/stores.json`; Agent Army recommends no tool
and ships no tool-specific code. On the first write of an `adr` or `work_item` the skill asks once
"repo (default) or a connected tool?"; other types stay in the repo unless you change them with
`/product stores`. With an external store the skill reads before it writes, never deletes, embeds the
ID so a re-run updates instead of duplicating, and shows the first write batch of a session before
sending it. If the connector is unavailable it stops and tells you; it never falls back to the repo.
`/bootstrap` and upgrades never write `stores.json`.

## All 19 skills

| Skill | Kind | Use it for | Writes |
|---|---|---|---|
| `/bootstrap` | engineering | tailor the agent team and control ownership to a repository | local role contracts, `.agent-army/config.json`, runtime and the selected adapter/control files |
| `/ship` | engineering | execute or resume agreed engineering work, one PR at a time | code, tests, execution state in `design-docs/`, docs and ADRs; work ready for human review |
| `/new-agent` | engineering | add a specialised local role | a local agent contract and its adapter output |
| `/new-skill` | engineering | add a reusable local workflow with its own entry point | a local skill source, optional command wrapper |
| `/adapt-army` | engineering | turn a recurring workflow problem into a targeted improvement | an Army Improvement Proposal and approved local changes |
| `/product` | navigator | where am I, what did I skip, what is the one next step | `skip` records and store bindings after you confirm; a one-line map snapshot |
| `/product-strategy` | advisor | audience, problem, advantage, features, revenue model, out of scope | `brief.md` with the register |
| `/product-red-team` | advisor | attack a brief, business case, GTM or launch plan before reality does | `product-red-team.md` |
| `/market-research` | advisor | competitors, alternatives, prices, their channels, with dated sources | `market-research.md` |
| `/business-case` | advisor | costs, revenue vs GMV, scenarios, break-even, pricing and a price test | `business-case.md` |
| `/validate-product` | advisor | falsifiable experiments, materials, reading results; post-launch churn | `validation.md` |
| `/product-spec` | advisor | MVP goal, stories with acceptance and priority, out of scope | `spec.md` (stories) |
| `/solution-architecture` | advisor | architecture style, stack per layer, build vs buy | architecture ADRs + `solution.md` |
| `/delivery-plan` | advisor | walking skeleton, vertical slices, spikes, in risk order | work items (`delivery-plan.md` or tracker) |
| `/go-to-market` | advisor | audience, offer, channels as written bets with budget caps | `go-to-market.md` (predictions, drafts) |
| `/product-metrics` | advisor | decision questions, funnel, events, collection checks, data reads | `metrics.md` |
| `/ux-review` | advisor | heuristic review of the paths that matter, clicked through in the running app when possible | `ux-review.md` |
| `/legal-review` | advisor | applicability, privacy, terms, consumer rights, VAT/OSS, invoicing | `legal-review.md` |
| `/launch-readiness` | advisor | launch verdict per area with evidence | `launch-readiness.md` |

`architect`, `tester`, `code-reviewer`, `security-auditor`, `perf-auditor`, `docs-writer` and `coder`
are roles that `/ship` runs, not skills you call.

## Pick by situation

| You say | Start with |
|---|---|
| "I have an idea, no product yet" | `/product-strategy` (or `/product` first if you are unsure) |
| "Who else does this, and what do they charge?" | `/market-research` |
| "Can this pay for itself? What should I charge?" | `/business-case` |
| "Would anyone actually pay?" | `/validate-product` |
| "Is my plan solid?" | `/product-red-team` on the plan file |
| "Validated. What should version one do?" | `/product-spec` |
| "What should I build it on?" | `/solution-architecture` |
| "In what order do we build it?" | `/delivery-plan`, then `/ship W-n` per slice |
| "People sign up but don't buy" | `/product-metrics` to read the funnel (if collection is verified), `/ux-review` of the purchase path, then `/validate-product` post-launch or a price test from `/business-case` |
| "I have 500 PLN for my first users" | `/go-to-market` |
| "Do I need a privacy policy, VAT, invoices?" | `/legal-review` |
| "We launch on Monday. Are we ready?" | `/launch-readiness` |
| "Fix this bug" / a well-understood engineering change | `/ship`; no product skill needed |

## Product skills in detail

All fourteen read one shared contract before their first reply
(`.agents/skills/product/advisor-contract.md`, tag `advisor-contract:v2`; on Claude it sits under
`.claude/skills/product/`), so they behave the same way where it matters:

- **Small steps together.** Every turn opens with `step X of ~Y`, shows one piece and asks at most one
  question, recommendation first. Long content goes into the file; the chat names the part to check.
- **Facts, assumptions, decisions.** A fact (`F`) has a source and date; anything else is an
  assumption (`A`) with a test. Evidence levels: `committed behavior` (paid, pre-ordered) >
  `behavior` > `stated intent` > `AI opinion / third-party data`. AI perspectives agreeing never
  raises the level.
- **Resume, don't repeat.** Each artifact keeps a `Conversation state`; a new session continues from
  it and never re-asks a settled question. Running a skill again after fixes updates its file instead
  of starting over: a finding whose fix work item is `delivered` becomes `handled with evidence: W-n`.
- **Records, not code.** Product skills read the register, their own artifact, ADRs, work item
  statuses and what you hand them; they do not analyse your source code. What was built reaches them
  as work item evidence written by `/ship`.
- **Findings stay in the artifact, decisions go to ADRs.** Review findings change status with every
  fix, so they live in the skill's own file; an ADR is written only when a decision is made.
- **Write after a finding**, in place; no transcripts, empty files or placeholders. Only
  `product-strategy` edits the brief; the others append `proposed` rows under its Change proposals.
- **Results** end with Conclusion (conditional) · Findings · What holds · Not assessed · Next step
  (the smallest, ≤ 1 week, within budget) · Conversation state, and the line
  `stage N · full picture: /product`.
- **Never without your command:** writing product code, publishing, contacting people, spending
  money, deploying. Never claimed without evidence: legal compliance, completed validation, a working
  restore. Product skills add no gate to `/ship`.

### `/product` — navigator
- **When:** "where am I?", "what next?", before building or spending money, after a pause.
- **Reads:** only the status-bearing parts of each record, through its bound store.
- **Output:** the 12-stage map (one line per stage with the reason and record), warnings about earlier
  gaps, stale items, one next step, Not assessed.
- **Writes:** a `skip` record after you confirm it, a one-line map snapshot in `journey.md`, and in
  `/product stores` the bindings and migrated records, after you confirm. Never advisor artifacts.
- **Example:** `/product "I want to start building next week. What now?"`

### `/product-strategy` — critical strategy partner
- **When:** a new idea, a pivot, or a brief that went stale after new evidence.
- **Reads:** the brief and relevant ADRs; reviews open Change proposals with you first.
- **Output:** six topics, one per turn (audience, problem, alternatives and advantage, features,
  revenue model, out of scope), each seen from customer, product, distribution and finance, with every
  conflict named.
- **Writes:** `brief.md` and its register, after each finding; proposes a `product` ADR when direction,
  segment or revenue model changes.
- **Example:** `/product-strategy "I want to build an app that helps dog owners find sitters in my city."`

### `/product-red-team` — adversarial review
- **When:** on `brief.md`, `business-case.md`, `go-to-market.md`, `launch-readiness.md` or a pasted plan.
- **Reads:** the target artifact and the register.
- **Output:** load-bearing claims, steelman then attack, "Fails if …", ranked by impact × likelihood ×
  cheapness to test, with a test or mitigation and a kill criterion; what holds; what it could not assess.
- **Writes:** `product-red-team.md`, one section per reviewed artifact and date. It proposes, never edits:
  brief changes as Change proposals, experiments to `/validate-product`, code as `fix` work items.
- **Example:** `/product-red-team "Red-team my go-to-market plan in docs/product/go-to-market.md."`

### `/market-research` — dated desk research
- **When:** before or after a first brief, before pricing, when a competitor appears.
- **Reads:** the brief (segment, problem, alternatives); the web when your tool allows it.
- **Output:** findings with source, check date and the label `third-party data`; without web access the
  result is marked partial with a manual-check list. It never proves demand.
- **Writes:** `market-research.md`; price anchors go to `/business-case`, demand questions to
  `/validate-product`, brief changes to Change proposals.
- **Example:** `/market-research "Who are my competitors for a booking tool for independent physiotherapists in Poland?"`

### `/business-case` — numbers you can recheck
- **When:** choosing a revenue model, setting a price, checking whether the idea can pay for itself.
- **Reads:** the brief, `market-research.md` (anchors), `validation.md` (results).
- **Output:** inputs with unit, period and source (or an `A`), formulas, three scenarios, break-even,
  cash need, sensitivity; GMV, revenue, margin and profit kept apart; no LTV without retention data;
  a willingness-to-pay test handed to `/validate-product`.
- **Writes:** `business-case.md`; on resume it recomputes only the affected rows.
- **Example:** `/business-case "Is a 49 PLN/month plan for my invoicing app for freelancers worth it?"`

### `/validate-product` — experiments that can say no
- **When:** the brief names its riskiest assumption; a price test from `/business-case`; after launch,
  when metric reads or churn reports arrive (post-launch mode).
- **Reads:** the register, `metrics.md` for post-launch.
- **Output:** an XYZ hypothesis, an experiment that favours behavior over opinion, thresholds written
  before data, materials as drafts, and Ship / Iterate / Kill from the results you bring. Too few data
  points → "not enough signal". Post-launch: churn interviews (no conclusion below five), anonymised
  support synthesis, retention hypotheses.
- **Writes:** `validation.md`, updated after each settled answer; register changes as Change proposals;
  a landing page or fake door as a `fix` work item. It never sends anything for you.
- **Example:** `/validate-product "How do I check if anyone would pay for my meal-planning app?"`

### `/product-spec` — what version one must do
- **When:** the brief has a validated problem and segment, or new findings change the spec.
- **Reads:** the brief, `validation.md`, `ux-review.md`, `legal-review.md`, `metrics.md`.
- **Output:** an MVP goal tied to `F`/`A` IDs, stories `S-n` with observable acceptance and must/should/
  later priority, out of scope (never empty), must-haves linked from legal (`L-n`) and metrics, open
  questions. No stack, data model or estimates. Without an executed experiment it offers only a thin
  "learning MVP".
- **Writes:** `spec.md`; a later change is a proposed delta, and confirmed changes mark stories
  `changed` for `/delivery-plan`.
- **Example:** `/product-spec "My interviews worked, 6 of 8 tutors paid a deposit. What should version one do?"`

### `/solution-architecture` — a stack you can operate
- **When:** the spec has must stories and nothing is built yet, or a layer must change.
- **Reads:** stories, the register (skills, time, budget), the business-case cost ceiling, legal
  constraints, events; in an existing repo the stack from its manifests.
- **Output:** a modular monolith by default; per layer 2–3 options ranked by your skills, operating
  cost, legal constraints, managed over self-hosted, lock-in; build vs buy; prices only with a source
  and date (otherwise an `A`); a cost check; non-functional must-haves and open technical risks for spikes.
- **Writes:** one `architecture` ADR per choice (`Proposed` until you confirm) and `solution.md` linking
  them. No code or scaffolding: the stack becomes real in the walking-skeleton slice built by `/ship`.
- **Example:** `/solution-architecture "I know Python and a bit of React. What should I build my booking app on?"`

### `/delivery-plan` — walking skeleton, then thin slices
- **When:** after `spec.md` and the architecture ADRs; again after a delivered slice, a spec delta, a
  new `fix` item or an ADR in `Needs review`.
- **Reads:** stories, `solution.md` and its ADRs, `metrics.md`, open `fix` items, existing work items.
- **Output:** W-1 walking skeleton, then vertical slices ("a user can …") with acceptance, stories,
  metric, dependencies, size S/M/L; time-boxed spikes with an exit criterion; order by riskiest
  assumption, then value, then dependency; the launch set. Never hours; never tasks inside a slice.
- **Writes:** `work_item` records through the bound store (asks once where they live, shows the first
  batch). Items start `proposed` and become `ready` when you confirm the order; a re-plan touches only
  items not yet delivered.
- **Example:** `/delivery-plan "Plan the build."`

### `/go-to-market` — predictions first, small bets
- **When:** before the first campaign, before spending money, when a channel underperforms.
- **Reads:** the brief, `metrics.md`, `business-case.md`.
- **Output:** audience, offer, 1–3 channels; a prediction row `P-n` written before every action; a
  traffic gate before any A/B test (refused below the needed sample); a budget cap and stop rule for
  every paid action; an inline red-team pass; a manual weekly review.
- **Writes:** `go-to-market.md` with drafts labelled as drafts. Nothing is published, sent or bought;
  landing or pricing page changes are `fix` work items.
- **Example:** `/go-to-market "I have 500 PLN to get my first users for a recipe-planning app."`

### `/product-metrics` — measure what decides
- **When:** before instrumentation, before paid traffic, or when you bring data to read.
- **Reads:** your dated exports in `docs/product/data/` (no personal data); GTM predictions and
  validation thresholds for comparison.
- **Output:** decision questions, one primary metric plus inputs, a funnel, `object_action` events with
  property types, privacy needs handed to `/legal-review`, 2–3 tool options (the choice is an ADR),
  collection checks; low-volume reads with "not enough signal".
- **Writes:** `metrics.md`; instrumentation is always one `fix` work item for `/ship` with each event as
  an assertion the tester can write. Until `Collection status` is `verified`, nobody interprets the data.
- **Example:** `/product-metrics "What should I track in my habit-tracker app before launch?"`

### `/ux-review` — walk the paths that matter
- **When:** before launch, after weak activation, when you share a URL, screenshots or a way to start
  the app.
- **Reads:** the brief and `metrics.md`, then the product itself, in this order: a URL you give, the
  app started locally (it proposes the start command and waits for your go-ahead), screenshots or
  recordings, the page files that render the screens. It clicks through with a browser automation tool
  your environment already has (for example Playwright) and installs none without your yes. It never
  reviews application code.
- **Safety:** a URL counts as production unless you say otherwise, and on production it only browses
  (no sign-ups, logins or form submits). Before starting the app it asks you to confirm test keys, no
  production database and no real email sending. It uses a fresh browser session without your
  sign-ins, never completes a payment, messages real people or deletes data, and stops every process
  it started.
- **Output:** findings `UX-n` on offer, onboarding, first useful result, purchase, errors and
  accessibility, each tied to a screenshot or flow step and rated `blocks` (cannot finish the path) /
  `hurts` / `minor`; labelled "heuristic review (no user study)" with the sources used; the cheapest
  real check.
- **Writes:** `ux-review.md` and the screenshots its findings cite (`docs/product/screens/ux-<date>/`);
  at most the top five fixes as `fix` work items with their finding IDs. A re-run walks again only the
  paths whose findings changed.
- **Example:** `/ux-review "Review the signup flow; the app runs with npm run dev."`

### `/legal-review` — applicability and the questions for a professional
- **When:** before launch, before collecting personal data or payments, when selling across borders.
- **Reads:** your answers on where you and your customers are, B2B or B2C, what the product is and
  which data it collects; official sources when your tool can reach them.
- **Output:** findings `L-n` with requirement, why it applies, source, check date, status, whether it
  blocks launch and a pass/fail "done when"; formalities (entity, VAT incl. EU OSS, invoicing, payment
  provider vs merchant of record); one question list for a lawyer and one for an accountant. Without
  source access the result is partial. It never declares the product compliant and is not legal advice.
- **Writes:** `legal-review.md`; code remediation (consent banner, data deletion, terms pages) as `fix`
  work items.
- **Example:** `/legal-review "I'm launching an online course platform for adults in Poland and the Czech Republic. What do I need?"`

### `/launch-readiness` — what blocks launch, with evidence
- **When:** in the days before launch or a large campaign.
- **Reads:** `metrics.md`, `legal-review.md`, `ux-review.md`, `go-to-market.md` and any `/ship` audit
  reports you point to.
- **Output:** per area (main path, purchase, failed payment, cancellation, contact and support,
  monitoring, backups with restore evidence, measurement, legal, UX) `ready / blocker / later / not run`
  with evidence; a verdict: launch, launch with named risks you accept, or not yet. A backup without a
  restore test is an unverified blocker; an audit that was not run is "not run", never "clean".
- **Writes:** `launch-readiness.md`; code blockers as `fix` work items. It never re-runs audits.
- **Example:** `/launch-readiness "We launch on Monday. Are we ready?"`

## Standalone or handed off to `/ship`

Product skills produce conversation and documents. Anything that becomes code is a work item `W-n`
(`kind: slice | spike | fix`, status `proposed | ready | in progress | delivered (evidence)`). You start
`/ship` with a `ready` item; its docs stage marks the item `delivered` with evidence in whichever store
it lives in (or asks you to, when that store's connector is unavailable), and `/product` reads that status.

| Skill | Artifact | Standalone (conversation + docs only) | Hands off to `/ship` (coding) |
|---|---|---|---|
| `product-strategy` | `brief.md` | always | `brief.md` is architect input for feature work |
| `product-red-team` | `product-red-team.md` | always; also on GTM and launch plans | — |
| `market-research` | `market-research.md` | always; dated sources, third-party data | — |
| `business-case` | `business-case.md` | always | — |
| `validate-product` | `validation.md` | interviews, manual pre-orders, price tests, concierge tests, post-launch churn interviews | fake door, landing page, waitlist → `fix` work item |
| `product-spec` | `spec.md` (stories) | MVP scope, priorities, stories, acceptance, out of scope | stories feed `delivery-plan`; no tech choices |
| `solution-architecture` | ADRs + `solution.md` | architecture style, stack per layer, build vs buy, hosting, non-functional needs | the stack is input for the walking skeleton and every `architect` blueprint; no code |
| `delivery-plan` | work items | walking skeleton, vertical slices, spikes, order | **always**: each slice or spike is a work item `/ship` executes; `architect` writes its blueprint |
| `product` | skips, bindings | always; read-only map + one recommendation | — (may recommend `/ship W-n` for a `ready` item) |
| `go-to-market` | `go-to-market.md` + drafts | messages, prediction register, budget caps | landing or pricing page changes |
| `product-metrics` | `metrics.md` | questions, funnel, event schema, privacy, data reads | **instrumentation always**: architect gets `metrics.md`, tester asserts event names and schemas |
| `ux-review` | `ux-review.md` | heuristic review in the running app or from screenshots, prioritised findings | fixes as work items with finding IDs |
| `legal-review` | `legal-review.md` | applicability, dated sources, lawyer and accountant questions | consent banner, data deletion, terms pages |
| `launch-readiness` | `launch-readiness.md` | readiness verdict per area | code blockers; reuses `/ship` audit evidence, never re-runs audits |

Small fixes from UX, legal or metrics go straight in as `fix` work items; the next `/delivery-plan`
run absorbs them into the order.

**Greenfield:** `solution-architecture` ADRs → `delivery-plan` W-1 walking skeleton → `/ship` builds it
→ `/bootstrap` tailors the team to the now-real stack → next slices. `/ship` works before `/bootstrap`,
but for this small first slice ask for the independent review and security pass explicitly. In an existing product,
`solution-architecture` keeps the current stack and proposes a change only through an ADR with a reason.

## Typical paths

These are routes, not gates. Nothing runs automatically; `/product` suggests the next step and you can
start midway, loop back or skip what does not apply.

| Situation | Path |
|---|---|
| New product | strategy → red-team → market-research → business-case (pricing) → validate → spec → solution-architecture → delivery-plan → `/ship` per slice |
| Weak adoption | metrics read + UX review + post-launch validation → hypothesis → experiment → spec delta → delivery-plan re-run → `/ship` |
| Preparing a launch | go-to-market + legal and formalities early enough to affect the build → fixes via `/ship` → launch-readiness |
| Already launched | metrics read → the skill the data points to → `/ship` |
| Small, well-understood engineering change | `/ship` only |

## Decisions (ADRs)

Decisions live in ADRs, by default `docs/adr/NNN-<slug>.md` (or the `adr` store bound in
`stores.json`; an existing ADR directory and its numbering are reused).

- **Who writes them:** the product skills (for example `product-strategy` for a segment or revenue
  model change, `solution-architecture` for each stack choice, `product-metrics` for the analytics
  tool) and `docs-writer` in the `/ship` docs stage, which also sweeps the task's `design-docs/` plan
  for significant decisions without an ADR before the task closes.
- **When:** a decision changes direction, scope, architecture, revenue model, segment, channel,
  measurement or a working rule, or "why?" cannot be answered from the code.
- **When not:** trivial fixes and conventional choices get no ADR.
- **Status:** `Proposed` until you confirm the decision itself ("decide for me" is not a confirmation);
  `Accepted` is not the same as implemented (the `Implementation` field tracks that). An accepted ADR is
  never edited: a change is a new ADR with `Supersedes`, and the old one becomes `Superseded by`. When
  an assumption behind it is disproved, it becomes `Needs review` and `/product` marks the stages that
  rely on it `stale`.
- **Template** (shared by every product skill and `docs-writer`): Date, Status, Type
  (`product | architecture | process`), Supersedes, Source; sections Context, Decision, Basis (register
  IDs), Alternatives considered, Consequences, Revisit when, Implementation.

`design-docs/` blueprints are temporary execution plans for `/ship`; they are never the only home of a
rationale. An ADR wins over any other document, and the conflicting document gets fixed.

## Attribution

A few methods were borrowed and rewritten, never copied verbatim, and nothing is a dependency. Each skill
names its source and license inline; [SOURCES.md](SOURCES.md) in this source repo lists every source with
its commit. APM installs only the skill folders, so `SOURCES.md` is not copied into your repository.
