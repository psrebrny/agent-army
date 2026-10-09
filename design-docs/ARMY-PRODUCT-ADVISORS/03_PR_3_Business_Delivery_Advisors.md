> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #3: Business and delivery advisors
**Objective:** six advisors (`business-case`, `go-to-market`, `product-metrics`, `ux-review`, `legal-review`, `launch-readiness`) that embed the contract unchanged and pass gate G2. Starts only after gate G1 in PR 2 passes. `product-spec`, `solution-architecture` and `delivery-plan` follow in PR 4, `/product` in PR 5.

## Execution State
- **PR status:** planned
- **Interaction policy:** unset — /ship asks once per PR before first execution
- **Execution scope:** unset
- **Scope Profile:** unset
- **Model routing:** unset
- **Last manual configuration:** unknown
- **Current task:** none
- **Temporary delegation:** none
- **Active roles:** none
- **Last verified stage:** planned
- **Awaiting decision:** none

---

## Execution Progress
- **Milestones:** unset
- **Current milestone:** none
- **Finish condition:** unset
- **Last map change:** none
- **Deferred ideas:** none

---

## Interaction Card
none

---

### Task 3.1: `business-case` + `go-to-market`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** capability_gap
- **Bottleneck rationale:** finance arithmetic and marketing claims are the two areas the author cannot verify by intuition, so the skills must force checkable output
- **Escalation trigger:** an S2 arithmetic error or an S4 recommendation without a prediction row

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
`business-case` guides a non-finance user and explains each term when first used. It picks the model that fits the product: initial investment, fixed and variable costs, acquisition, founder time. It separates GMV / revenue / margin / profit and cash spend / time cost. It shows three scenarios, break-even, cash need and sensitivity to key assumptions. ROI requires a stated horizon and cost definition. No LTV without retention data. Pricing section: model (flat, per seat, usage, freemium, one-off), packages, anchors from `market-research` labelled third-party data, and a willingness-to-pay hypothesis handed to `validate-product` as a price test. Formulas carry units and periods. It writes `business-case.md`. `go-to-market` is thin by design: audience, offer, channels. Every recommendation needs a prediction row written before acting. A traffic gate (Lehr approximation) applies before any A/B test. A red-team pass runs on the plan (method of `product-red-team`, applied inline). A budget cap plus stop rule applies to every paid action. Benchmarks count as third-party data. A manual weekly review applies the "act when / not enough signal" rule. Campaign copy and creative briefs are drafts for testing. It says plainly where knowledge is missing. Events come from `metrics.md`, never defined locally. It writes `go-to-market.md`. Wrappers plus ≥ 2 examples each.
- **API/Component Contract:** prediction row `ID | if (action, segment) | metric ≥ threshold by date | kill below | written on | result`
- **Compatibility:** reads `metrics.md` (owner `product-metrics`)
- **Refactor checkpoint / recovery:** not applicable
- Nothing is published, sent or bought.

**Delegation Contract:**
- **Goal:** both skills pass G2 on S2, S4 and S11 (plan red-team).
- **Inputs / approved read paths:** manifest §3 "Specific behaviors"; PR 2 contract
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/{business-case,go-to-market}/**`, `.apm/commands/{business-case,go-to-market}.md`
- **Forbidden / never-touch zones:** the contract block text (changing it = new tag + re-run G1)
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the contract needs a change.

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval business-case go-to-market --scenario S2 S4 S11`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = plausible but wrong numbers. The judge re-computes the S2 tables.
- **E2E / INTEGRATION** (`advisor-eval`): ✓ S2 GMV ≠ revenue, sums re-check, pricing hands a price test to validation; ✓ S4 every channel has a prediction row, an A/B test is refused below the gate; ✓ 0 false facts
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. The bar is arm K from the same run.
3. Write both skills.
4. Run check + eval; record the rows.

**Aligns with:** manifest "Specific behaviors"; no external actions

### Task 3.2: `product-metrics`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** this is the only advisor whose output becomes code via `/ship`; its event schema must be testable by `tester`
- **Escalation trigger:** the schema cannot be expressed as an assertion

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
The cycle from the manifest runs: decision questions → primary metric + 3–5 input metrics → funnel (visit → signup → first useful result → purchase → return in 7 days) → `object_action` events with properties, the source of each number, and the minimum meaningful volume → privacy and consent (handoff to `legal-review`; least data that answers the questions) → tool options with no assumed paid tool; the choice becomes an ADR → a `fix`-kind work item for instrumentation (the architect reads `metrics.md`, the tester asserts name + schema) → collection verified (manual trial, payment reconciliation, no duplicates; until then the status is "unverified") → post-launch reads from `docs/product/data/*.csv` (dated, no personal data), compared with GTM predictions and validation thresholds, routed to the advisor the data points to. Low volume → absolute numbers and weekly cohorts. It writes `metrics.md`.
- **API/Component Contract:** `metrics.md` sections: Decision questions, Metrics, Funnel, Events (`name | trigger | properties | source`), Privacy, Collection status, Reads
- **Compatibility:** consumed by `go-to-market`, `launch-readiness`, `architect`
- **Refactor checkpoint / recovery:** not applicable
- Never writes instrumentation code itself.

**Delegation Contract:**
- **Goal:** passes G2 on S10 and produces a handoff an architect can turn into a test.
- **Inputs / approved read paths:** manifest §3; PR 2 contract
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/product-metrics/**`, `.apm/commands/product-metrics.md`
- **Forbidden / never-touch zones:** contract block text
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** data access would need an integration (deferred to automation stage 1).

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval product-metrics --scenario S10`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = interpreting noise, or unverified collection
- **E2E / INTEGRATION** (`advisor-eval`): ✓ "not enough signal" at low volume; ✓ no significance test; ✓ the handoff lists event + schema assertion
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. The bar is arm K from the same run.
3. Write the skill.
4. Run check + eval; record the row.

**Aligns with:** `/ship` boundary table; D5

### Task 3.3: `ux-review` + `legal-review` + `launch-readiness`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** all three must avoid false confirmations (study, compliance, restore)
- **Escalation trigger:** any run claims compliance, a user study or a working backup without evidence

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
`ux-review` covers offer comprehension, onboarding, first useful result, purchase, errors, accessibility of key paths. Each finding is tied to evidence (screen, flow, file). A heuristic review is labelled as such. Fixes become `fix`-kind work items with finding IDs. It writes `ux-review.md`. `legal-review` first establishes jurisdictions, B2B/B2C and product nature, then the areas from manifest §3, including formalities (entity, VAT incl. EU OSS, invoicing, payment provider vs merchant of record) that end as accountant questions. Each finding has source, check date and applicability basis. Partial without sources. It names the matters needing a lawyer or accountant. Remediation that is code is handed to `/ship`. It writes `legal-review.md`. `launch-readiness` covers product, purchase, failed payment, cancellation, contact, support, monitoring, restore evidence, and measurement (only that `metrics.md` steps 1–5 hold). It reuses `/ship` audit outputs when present and says "not run" otherwise, without duplicating the security auditor. Code blockers become `fix`-kind work items. It writes `launch-readiness.md`. Wrappers plus ≥ 2 examples each.
- **API/Component Contract:** artifact paths per manifest table
- **Compatibility:** `launch-readiness` reads `metrics.md`, `legal-review.md`, `ux-review.md`
- **Refactor checkpoint / recovery:** not applicable
- "Not run" ≠ "run clean".

**Delegation Contract:**
- **Goal:** all three pass G2 on S5, S6 and S7.
- **Inputs / approved read paths:** manifest §3; PR 2 contract; `.apm/skills/bootstrap/baseline/core/agents/security-auditor.md` (to avoid overlap)
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/{ux-review,legal-review,launch-readiness}/**`, `.apm/commands/{ux-review,legal-review,launch-readiness}.md`
- **Forbidden / never-touch zones:** contract block text; baseline agents
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** legal content would be stated from memory without a source.

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval ux-review legal-review launch-readiness --scenario S5 S6 S7`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = false assurance to a founder before launch
- **E2E / INTEGRATION** (`advisor-eval`): ✓ S5 partial + lawyer and accountant questions (VAT/OSS); ✓ S6 "heuristic review" label; ✓ S7 restore listed as an unverified blocker
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. The bar is arm K from the same run.
3. Write the three skills.
4. Run check + eval; record the rows.

**Aligns with:** constraints on false claims; `/ship` boundary table

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** gate G2 — scorecards for S2, S4, S5, S6, S7, S10, S11 pass the decision rule; re-check one S2 table by hand
