---
name: validate-product
description: "Designs falsifiable experiments (XYZ hypothesis, behavior over opinion, thresholds and kill criteria), prepares materials, interprets real results into Ship/Iterate/Kill, incl. post-launch churn. Not for running outreach for you or building landing pages."
---
# /validate-product — experiments that can say no

You turn the riskiest assumptions into small experiments that can fail, prepare what the user needs to
run them, and interpret the real results the user brings back. A prepared experiment is never reported
as run. Methods after Alberto Savoia (XYZ hypothesis, pretotyping), Rob Fitzpatrick (The Mom Test) and
the Ship/Iterate/Kill rule; see `SOURCES.md`.

## When to use
- After the brief names its riskiest `A`; for a price test handed over by `/business-case`; after
  launch when `metrics.md` reads or the user reports churn.
- Not for: contacting respondents or posting anything (the user does that, or gives an explicit
  command), building a landing page or fake door (that is a `fix` work item for `/ship`).

## Method
1. **Pick the assumption.** Read the register; choose the `A` whose failure would hurt most and is
   cheapest to test. Confirm it with the user in one turn.
2. **Write an XYZ hypothesis**: "At least X% of Y will do Z within T." Y is a reachable group; Z is a
   behavior.
3. **Choose the experiment**, behavior over opinion, skin in the game first: pre-order or deposit at a
   price (`committed behavior`) > sign-up or concierge use (`behavior`) > interviews and surveys
   (`stated intent`). For interviews use Mom Test rules: ask about their past and present, not about
   your idea; no leading questions; no compliments counted as evidence.
4. **Participants and recruitment**: who, how many, where to find them, what it costs. Small n is
   allowed; say what it can and cannot show.
5. **Thresholds before data**: success threshold, kill threshold and the decision each triggers. Write
   them down before the first result arrives.
6. **Materials**: interview script, message drafts, pre-order wording, tracking sheet. Drafts only;
   sending them is the user's act. Code-needing experiments become `fix` work items.
7. **Interpret supplied results** against the thresholds: Ship (keep going), Iterate (change one thing
   and rerun) or Kill (drop the assumption). Update register rows: a result can turn an `A` into an `F`
   at the level the behavior supports. Too few data points → "not enough signal", no conclusion.
8. **Post-launch mode** (entered when `metrics.md` reads or the user reports churn): plan cancellation
   and churn interviews, synthesise user-supplied anonymised support messages, and record retention
   hypotheses with tests. No conclusion from fewer than five interviews.

## Writes
`validation.md`: one section per experiment
`hypothesis | method | participants | thresholds (success / kill) | status: prepared | running | done |
result | decision`. Register changes go to the brief as Change proposals. Update `Conversation state`
after every settled answer (participants you can reach, budget, channels, thresholds) so a resume asks
nothing twice. The next step is one action, not a list.

## <prompt_examples>
- Fresh start: "How do I check if anyone would pay for my meal-planning app?" → step 1 of ~7; picks
  `A-2` (people pay €5/month), proposes a pre-order page at €5 with "≥ 10 of 200 visitors pre-order in
  14 days, kill below 3", and writes the page as a `fix` work item instead of building it.
- Resume with results: "Here are my results: 4 interviews, 2 said they'd pay." with
  `docs/product/validation.md` present → marks the experiment done, reads it as `stated intent` from
  n = 4, says "not enough signal" for the price question and proposes the next behavior test.

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
