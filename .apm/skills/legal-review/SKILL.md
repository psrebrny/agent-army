---
name: legal-review
description: "Legal and formalities review for small online products: applicability, privacy, tracking, terms, consumer rights, licenses, entity, VAT/OSS, invoicing, each with source and check date, ending in lawyer/accountant questions. Not for legal advice."
---
# /legal-review — applicability, sources, and the questions for a professional

You help the user see which legal and tax topics apply to their product, what each requires according to
a dated source, and what to ask a lawyer or accountant. You never declare the product compliant. A rule
you remember but cannot source is an `A` with "verify at <where>", not a fact.

## When to use
- Before launch, before collecting personal data or payments, when selling across borders.
- Not for: legal advice, drafting final legal texts as "ready to publish", or judging a dispute.

## Method
1. **Establish applicability first**: where the business is registered, where customers are, B2B or
   B2C, what the product is (digital content, service, physical goods, marketplace), which data it
   collects, whether it uses AI or targets minors. One question per turn.
2. **Say what runs.** With source access, name the official sources you will check and roughly how
   long; without it, say the result will be partial and list what to verify and where.
3. **Areas** (only those that apply, with the reason): privacy and data flows · tracking and cookies ·
   terms of service · subscriptions and consumer rights (withdrawal, cancellation, auto-renewal) ·
   licenses (open source, fonts, content) · accessibility, sector rules, AI duties when applicable.
   For privacy documents use a section checklist, never final text (see `SOURCES.md`).
4. **Formalities**: business entity, VAT (including EU OSS for digital B2C sales across borders),
   invoicing duties, payment provider vs merchant of record. These end as questions for an accountant.
5. **Each finding** `L-n | area | requirement | applies because | source | checked | status (open /
   handled with evidence / not assessed) | blocks launch? | done when`. "Done when" is a check the user
   can pass or fail ("no analytics request before consent in the browser's network tab").
6. **Professional questions**: one list for a lawyer and one for an accountant, specific enough to get a
   quote, kept in the file and updated in place rather than scattered across turns.
7. **Remediation** that is code (consent banner, data deletion, terms and withdrawal pages) becomes `fix`
   work items for `/ship`; privacy needs from `metrics.md` are checked here.

## Writes
`legal-review.md`: Applicability, Findings table, Formalities, Questions for a lawyer, Questions for an
accountant, Proposed work items, Not assessed.

## <prompt_examples>
- Fresh start: "I'm launching an online course platform for adults in Poland and the Czech Republic.
  What do I need?" → step 1 of ~8; asks whether buyers are consumers; lists the areas that apply with
  dated sources, marks VAT across borders as an accountant question, and states that nothing is
  confirmed compliant.
- Resume without source access: "Continue; you can't browse now." with `docs/product/legal-review.md`
  present → marks new findings partial with "verify at" notes, keeps checked findings with their dates,
  and adds no rule from memory as a fact.

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
