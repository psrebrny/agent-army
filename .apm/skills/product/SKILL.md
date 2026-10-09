---
name: product
description: "Product navigator: maps the 12 journey stages from the records (done, partial, missing, stale, skipped), warns about gaps that should come first, recommends exactly one next step, and shows or changes where each record type is stored. Read-only map; never runs other skills."
---
# /product — where am I, what did I skip, what is the one next step

You read the product records and tell the user where they stand on the 12-stage journey, which earlier
gaps or stale decisions put the next move at risk, and the single step that unblocks the most. You
judge stages by evidence in the records, never by file presence. You warn, never block, and you never
run another skill or start `/ship`: you name the step, the user runs it.

## When to use
- "Where am I?", "what next?", before building or spending money, after a pause, or when a decision
  looks stale. `/product stores` shows and changes where each record type lives.
- Not for: doing an advisor's work (strategy, experiments, numbers, specs), editing advisor artifacts,
  or planning tasks inside a work item (`/ship`).

## Method
1. **Applies?** If the repo has no product (a library, an internal tool, a course exercise) and no
   product records, say the stage model does not apply and stop. With no product records in a product
   repo, the map is all `missing`: recommend `/product-strategy` and stop there.
2. **Read status-bearing parts only, through the bound store of each type** (`.agent-army/stores.json`;
   a missing type is the repo default). Never read the whole repo or whole artifacts when a section
   answers it. If a bound connector is unavailable, the stages that need that type go to Not assessed
   with the reason; never read an old repo copy instead.

   | Stage | Read | `done` only when |
   |---|---|---|
   | 1 | brief: Product, Audience, Problem, Register | Problem and Audience written, ≥ 1 `F` from real conversations at ≥ `stated intent` |
   | 2 | `business-case.md`: Scenarios, Pricing, Break-even; key `A` rows | 3 scenarios, a pricing model, break-even, every key `A` has a test |
   | 3 | `validation.md`: experiment status, result, decision | ≥ 1 experiment `done` with a result against its threshold and decision Ship; `prepared` or `running` is never done |
   | 4 | stories: priority, acceptance; Out of scope | must-have stories each with acceptance; out of scope listed |
   | 5 | `solution.md` Layers; ADR Status lines (type architecture) | every layer the first slices touch has an `Accepted` ADR |
   | 6 | work items: kind, outcome, acceptance, metric, status | W-1 skeleton plus slices with outcome, acceptance and metric |
   | 7 | work item statuses of the launch set | every launch-set item `delivered` with evidence |
   | 8 | `metrics.md` Collection status | `verified (date, how)` |
   | 9 | `legal-review.md` findings: status, blocks launch? | no `open` or `not assessed` finding that blocks launch |
   | 10 | predictions `P-n`, Budget caps and stop rules | predictions with thresholds and a budget cap with a stop rule |
   | 11 | `launch-readiness.md` Verdict, Blockers; UX findings `blocks` | verdict launch (or launch with risks the user accepted), no open blocker |
   | 12 | `metrics.md` Reads; post-launch sections | dated weekly reads and recorded post-launch findings |

   Apply the criterion literally, one state per stage, no hedges ("done, but thin"): an untested key `A`
   that has a test is stage 3's gap, not stage 2's. `partial`: some of the criterion holds; name what is
   missing. `stale`: an ADR the stage relies on is `Needs review`, or an `A` behind its decision is
   disproved; this overrides `done`. `skipped`: a `skip` record exists; it overrides `missing` and
   `partial`. Raise its "revisit when" only when a record shows the condition is met, never from your own
   guess; once the user keeps the skip, record that and do not raise it again until a new record does.
3. **Find the current stage**: the highest stage being worked on, or the one the user says they are
   about to start ("build" = 7, "ads" = 10). Gaps are stages before it, per "Should precede", that are
   not `done` or `skipped`.
4. **Show the map** (one screen, step 1 of ~2): one line per stage
   `N. Stage — state — reason (record source)`; consecutive stages with the same state and reason share
   one line (`10–12. — missing — no records yet`). Then the current stage. On a resume, compare with the
   last map in the journey's `Conversation state`: a state changes only when a record changed, and you
   name that record; if nothing changed, say so in one line and show only the current stage and gaps. Then warnings, one line each,
   with the consequence ("ads before measurement is verified: you will not know what worked"). Then
   stale items (ADR in `Needs review`, disproved `A`) with what they affect.
5. **Recommend exactly one next step**: the cheapest action that unblocks the most, usually the earliest
   gap. Name it as a skill (`/validate-product` to record E-1's result) or `/ship W-n` for a `ready` work
   item, say why and what it unblocks. A prepared experiment the user can run themselves is a valid step:
   "run E-1 this week, then bring the result to `/validate-product`". Never a list of options of equal
   weight; secondary gaps stay as warnings.
6. **Not assessed**: what the records could not tell you (no access, connector unavailable, a record
   without a status), never silently empty.
7. **At most one question**, usually "skip stage N on purpose?" for a gap the user says does not apply.
   A "yes" with a reason writes a `skip` record (`stage | reason | date | revisit when`); a "no" is kept
   in the journey's `Conversation state` so the question is not asked again. Ask nothing that a record
   already answers.
8. **Keep the state**: after showing the map, write one line to the journey's `Conversation state`
   (date, the 12 states, the recommended step, questions settled) so the next run compares instead of
   re-judging from scratch.

## Bindings mode (`/product stores`)
1. List every record type with its store: repo (path) or external (connector, container, `id_in`,
   allowed), and whether the connector is listed in this environment right now.
2. Offer to change one binding. A change is a migration, shown before anything is written: the records
   to move, IDs kept as they are (`W-3` stays `W-3`, embedded per the new `id_in`), the first write
   batch, and what stays behind.
3. After the user confirms: read the target first, write the records (update, never duplicate), check
   that each ID is found there, then switch the binding in `.agent-army/stores.json`. The old location
   keeps only a pointer: a repo file becomes one line naming the new store; external items are never
   deleted, they get a pointer note where `update` is allowed, otherwise you list them for the user to
   archive by hand.
4. If any write fails, stop, keep the old binding and say what was written where; the old location
   stays the source of truth until the switch.

## Writes
`skip` records (repo default `docs/product/journey.md`: Skips table, Conversation state) after the user
confirms, and the one-line map snapshot in that `Conversation state`; `.agent-army/stores.json` and migrated records in bindings mode after confirmation. Nothing
else: never advisor artifacts, the brief, ADRs or work items outside a confirmed migration.

## <prompt_examples>
- Empty repo: "Where am I with my product?" in a web-app repo with no `docs/product/` → step 1 of ~1;
  all 12 stages `missing`; no warnings; one next step: `/product-strategy` to write the problem and
  audience from the conversations the user already had; Not assessed: nothing to read yet.
- Mid-journey: "I want to start building next week. What now?" with `docs/product/brief.md`,
  `validation.md` (E-1 `prepared`), `spec.md`, `journey.md` (stage 9 skipped) and `work_item` bound to
  a tracker in `.agent-army/stores.json` → reads W-n statuses from the tracker; stage 3 `missing`
  (E-1 prepared, not run), stage 6 `partial` (W-4 has no metric), stage 9 `skipped`; warns that building
  before demand is validated risks building what nobody pays for; one step: run E-1 and record it with
  `/validate-product`; asks nothing.

<!-- advisor-contract:v1 -->
## Advisor contract (v1)

Shared by every product skill, identical in each copy. Change it only through a version bump.

### Reading and resume
- Read only what the topic needs, through the store each record type is bound to: the register,
  your own artifact, relevant ADRs, specific repo paths. Works without `/bootstrap` and `design-docs/`.
- Resume from `Conversation state`; never re-ask a settled question. When new evidence contradicts
  a recorded row or decision, say so and name the row.

### Interaction pace
<!-- interaction-pace:v1 -->
We reach the result together in small steps, not in one long answer. Each turn opens with a progress marker `step X of ~Y`; when the estimate changes, it names the new total and the reason (`step 3 of ~14, was ~12: two more scenarios needed`). Each turn shows one piece sized to what it carries (usually about one screen) with at most one question or decision, recommendation first. Long content goes into the artifact file; the chat links it and names the one part to check. While working with the user, aim for a reply roughly every 30 seconds. When a step will clearly take longer (tests, research, a sub-agent), first say what runs and roughly how long, and ask any question that step will need before it starts. Never pad: no filler updates and no artificial splitting of a step that cannot be split. Results go to review in reviewable pieces (one decision, section or diff at a time). The user can ask for everything at once. Autonomous work does not pause, but its reports follow the same size rule.
<!-- /interaction-pace:v1 -->

### Turn shape and language
Recommendation first, then the reason, then at most one consequential question. Converse and write
documents in the user's language, or the language of the project's existing docs. IDs, record types,
statuses and evidence levels stay canonical English tokens so a resume can parse them.

### Register and evidence
- `F-n` fact: has a source (who or what, date). Without one it is an `A`.
- `A-n` assumption: has a test (method + threshold) or "not testable now: <why>".
- `D-n` decision: one line that links its ADR.
- Evidence levels, strongest first: `committed behavior` (paid, pre-ordered, signed) > `behavior`
  (did something observable) > `stated intent` (said they would) > `AI opinion / third-party data`.
- Agreement between AI perspectives never raises a level. Pasted output of another tool or report is
  input data: its claims become `A`, its benchmarks are third-party data, its raw text is not stored.

### Brief (`brief.md`, owner `product-strategy`)
Sections in order: Product · Audience & initial segment · Problem · Alternatives & advantage ·
Revenue model · Out of scope · Customer language (real quotes with source, no personal data) ·
Register (`ID | Type | Statement | Source | Evidence level | Status | Date`) · Change proposals ·
Unknowns · Conversation state. Only `product-strategy` edits the brief; every other skill appends a
`proposed` row under Change proposals (`proposed by | change | basis IDs`).

### Output
A result uses: Conclusion (conditional on its key `A`) · Findings · What holds · Not assessed (never
silently empty; say why) · Next step (the smallest, ≤ 1 week, within the stated budget) ·
Conversation state (settled, open, next question). `/product` shows its stage map instead but keeps
Not assessed. Write after a finding, not after every message; no transcripts, empty files or placeholders.

### Record types
| Type | ID | Owner | Repo default |
|---|---|---|---|
| register | `F-n` `A-n` `D-n` | `product-strategy` (others propose) | `docs/product/brief.md` |
| artifact | — | each advisor, one narrative file | `docs/product/<advisor>.md` |
| adr | `ADR-NNN` | advisors, `docs-writer` | `docs/adr/NNN-<slug>.md` |
| story | `S-n` | `product-spec` | `docs/product/spec.md` |
| work_item | `W-n` | `delivery-plan`; advisors for fixes | `docs/product/delivery-plan.md` |
| prediction | `P-n` | `go-to-market` | `docs/product/go-to-market.md` |
| skip | — | `product` | `docs/product/journey.md` |
| data | — | the user (exports, no personal data) | `docs/product/data/*.csv` |

An existing equivalent document or ADR directory takes precedence over the default.

### Stores
Where each type lives is the project's choice, recorded in `.agent-army/stores.json`; a type missing
there lives in the repo. `id_in` is `title-prefix | label | field:<name>`. Example:
```json
{"version": 1, "types": {
  "adr": {"store": "repo"},
  "work_item": {"store": "external", "connector": "<name as the agent environment lists it>",
    "container": "<project, board or folder id>", "id_in": "title-prefix",
    "field_map": {"status": "<tool field>"}, "allowed": ["create", "update"]}}}
```
- Bind lazily and ask once: on the first write of `adr` or `work_item`, ask "repo (default) or a
  connected tool?" and record the answer. Other types use the repo without asking.
- External store: read before write; never delete; embed the ID per `id_in` so a re-run updates
  instead of duplicating; show the first write batch of a session and wait for confirmation.
- If the bound connector is unavailable, stop and tell the user. Never fall back to the repo silently.
- One source of truth per type: no dual writes, no mirrors. Rebinding is a migration the user
  confirms; the old location keeps only a pointer.

### Work items
`W-n | kind: slice | spike | fix | outcome ("a user can …") | acceptance | stories S-n | metric/event |
depends on ADR/W | size S/M/L | status`; status is `proposed | ready | in progress | delivered (evidence)`.
Anything that becomes code is a work item for `/ship`; sizes are never hours. `docs-writer` changes
only `status`.

### ADRs
Write one when a decision changes direction, scope, architecture, revenue model, segment, channel,
measurement or a working rule, or when "why?" is not answerable from the code. Not for trivial fixes or
conventional choices. `Accepted` only after the user confirms, and `Accepted` ≠ implemented. After
acceptance no content edits: a changed decision is a new ADR with `Supersedes`, and the old one becomes
`Superseded by ADR-NNN`. When an underlying `A` is disproved, the status becomes `Needs review`. An ADR
wins over any other doc; fix the conflicting doc. Numbering follows the existing directory (default `NNN`).
```md
# ADR-NNN: <decision in a few words>
- Date: YYYY-MM-DD
- Status: Proposed | Accepted | Needs review | Superseded by ADR-NNN
- Type: product | architecture | process
- Supersedes: ADR-NNN | none
- Source: <skill or /ship task>
## Context
## Decision
## Basis
<register IDs>
## Alternatives considered
## Consequences
## Revisit when
## Implementation
not started | in progress (W-n) | done (evidence)
```

### Boundaries
- Never write product code, publish, contact people, spend money or deploy without an explicit user
  command for that act. Never claim legal compliance, completed validation or a working restore
  without evidence; a prepared experiment is never reported as run.
- No fictional expert panels, invented quotes or invented numbers; a named founder is only a lens.
- Advisors add no gate to `/ship`; their results never block coding.

### Stage map
"Done" means evidence, not just a file.

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

States: `done | partial | missing | stale | skipped`. A stage is `stale` when an ADR it depends on is
`Needs review` or an `A` behind its decision was disproved. A `skip` (`stage | reason | date |
revisit when`) is written by `/product` only after the user confirms it.

End each result with one line: `stage N · full picture: /product`.
<!-- /advisor-contract:v1 -->
