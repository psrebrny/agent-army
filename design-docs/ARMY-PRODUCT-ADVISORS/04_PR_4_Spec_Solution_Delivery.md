> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #4: From validated product to buildable slices
**Objective:** three skills close the gap between "what" and `/ship`. `product-spec` writes the stories, `solution-architecture` decides the stack as ADRs, and `delivery-plan` produces the walking skeleton plus vertical slices as work items. All three must pass gate G3.

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

### Task 4.1: `product-spec`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** stories must be concrete enough to slice, without drifting into technical design
- **Escalation trigger:** S13 output contains a technology choice, or a story without acceptance criteria

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
The MVP goal must be tied to validated `F`/`A` IDs. If stage 3 is not done, the skill says so and offers a deliberately thin "learning MVP", never a full build. It writes `story` records `S-n` (who, what, why) with observable acceptance criteria and must/should/later priority, plus an out-of-scope list. Must-haves are imported from legal (privacy, consent) and metrics (events) by link, not by copy. It ends with open questions. On resume, it proposes spec deltas from new findings (UX, post-launch) and marks affected stories `changed` so that `delivery-plan` re-plans them. Wrapper plus ≥ 2 examples (first MVP; delta after a post-launch finding).
- **API/Component Contract:** `story` record per contract; repo default `docs/product/spec.md` (MVP goal, Stories, Out of scope, Imported must-haves, Open questions, Conversation state)
- **Compatibility:** consumed by `delivery-plan`, `solution-architecture`, `/product`
- **Refactor checkpoint / recovery:** not applicable
- No architecture, stack, data model or hour estimates. No work items: slicing belongs to `delivery-plan`.

**Delegation Contract:**
- **Goal:** passes G3 on S13.
- **Inputs / approved read paths:** manifest §3; PR 2 contract
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/product-spec/**`, `.apm/commands/product-spec.md`
- **Forbidden / never-touch zones:** contract block text
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the story schema needs a contract change.

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval product-spec --scenario S13`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = a wish list, or a hidden architecture document
- **E2E / INTEGRATION** (`advisor-eval`): ✓ every must story has acceptance; ✓ out of scope is non-empty; ✓ must-haves linked; ✓ 0 tech choices
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. Baseline from PR 1.
3. Write the skill.
4. Run check + eval; record the row.

**Aligns with:** D10

### Task 4.2: `solution-architecture`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** these are high-stakes, hard-to-reverse choices; the model must also resist stating vendor prices or limits from memory
- **Escalation trigger:** S15 recommends microservices for a solo founder without a stated reason, or states a price without a source

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Inputs: stories, register constraints (team skills, time, budget), business case (operating cost ceiling), legal (data residency, privacy), metrics (events), and in a brownfield repo the existing stack, read from manifests rather than by scanning everything. Architecture style comes first (modular monolith by default for solo/small teams). Then, for each layer the MVP needs (frontend, backend, database, hosting, auth, payments, email, analytics), it gives 2–3 options with trade-offs, ranked by the manifest criteria, with build vs buy explicit. Prices, free-tier limits and versions need a dated source, otherwise they are `A`. Each accepted choice becomes an `adr` of type architecture, `Accepted` only after confirmation. It also writes non-functional must-haves and the open technical risks that `delivery-plan` will turn into spikes. A short summary goes to the artifact (repo default `docs/product/solution.md`) and links ADRs instead of repeating them. Brownfield: keep the stack; a change needs an ADR with an explicit reason and a migration slice. Wrapper plus ≥ 2 examples (greenfield; brownfield adding payments).
- **API/Component Contract:** ADRs (shared template); `solution.md` sections: Style, Layers (link per ADR), Build vs buy, Non-functional must-haves, Open technical risks, Conversation state
- **Compatibility:** consumed by `delivery-plan`, `architect` (follows Accepted ADRs; see PR 6), `/bootstrap` indirectly (via the real skeleton)
- **Refactor checkpoint / recovery:** not applicable
- No code, no repo scaffolding, no installs. Scaffolding is the walking-skeleton slice in `/ship`.

**Delegation Contract:**
- **Goal:** passes G3 on S15; every layer the first slices touch has an Accepted or Proposed ADR.
- **Inputs / approved read paths:** manifest §3; PR 2 contract; `.apm/skills/bootstrap/baseline/core/agents/architect.md` (greenfield mode, to avoid overlap)
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/solution-architecture/**`, `.apm/commands/solution-architecture.md`
- **Forbidden / never-touch zones:** contract block text; `architect.md`
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the skill would need web access to be useful at all (then define the partial-result behavior first).

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval solution-architecture --scenario S15`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = a confident, fashionable stack the founder cannot operate, or one built on stale pricing
- **E2E / INTEGRATION** (`advisor-eval`): ✓ options per layer with trade-offs; ✓ the founder's known language is preferred unless a stated reason says otherwise; ✓ 0 unsourced prices as facts; ✓ ADRs are `Proposed` until confirmed; ✓ risks listed
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. Baseline from PR 1 (S15 K arm).
3. Write the skill.
4. Run check + eval; record the row.

**Aligns with:** D11; ADR rules

### Task 4.3: `delivery-plan`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** slicing for value and risk is the craft that most often fails (horizontal layers, big-bang MVP)
- **Escalation trigger:** S16 output contains a horizontal slice, hour estimates, or re-plans delivered items

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Inputs: stories, architecture ADRs and open risks, metrics events, and open `fix` work items from other advisors. W-1 is the walking skeleton: the chosen stack deployed with one hello path, CI and test tooling. Then come vertical slices, each with an outcome ("a user can …"), acceptance (from stories), included `S-n`, the metric/event it moves, dependencies (ADR/W), S/M/L size and status. They are ordered riskiest assumption first, then value, then dependency. Spikes are time-boxed, with one question and an exit criterion, for open technical risks. Milestones: skeleton → first useful result → payment → launch-ready set. The skill marks which slices form the launch set (stage 7). Re-runs after a spec delta, a delivered slice, a new `fix` item or an ADR in `Needs review` change only items that are not delivered and say what moved and why. It writes `work_item` records through the bound store (repo default `docs/product/delivery-plan.md`). On the first `work_item` write it asks once where work items should live (store rules in the contract). Wrapper plus ≥ 2 examples (first plan; re-plan after a delivered slice and a UX fix).
- **API/Component Contract:** `work_item` per contract; status transitions `proposed → ready` (user confirms the order) `→ in progress → delivered` (the latter two set by `/ship`)
- **Compatibility:** consumed by `/ship` (architect task source, `docs-writer` status), `/product` (stages 6–7)
- **Refactor checkpoint / recovery:** not applicable
- No per-task technical design; that is the architect's blueprint per slice.

**Delegation Contract:**
- **Goal:** passes G3 on S16 and S17; an architect can plan W-1 and W-2 without asking what "done" means.
- **Inputs / approved read paths:** manifest §3; PR 2 contract; `architect.md` (what a task source needs)
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/delivery-plan/**`, `.apm/commands/delivery-plan.md`
- **Forbidden / never-touch zones:** contract block text; `architect.md`; any tool-specific instructions (D12)
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a tracker concept (sprints, story points) seems needed; it stays out unless the user's project adds it.

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval delivery-plan --scenario S16 S17`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = a plan that delivers no usable value until the end, or a tracker filled with duplicates
- **E2E / INTEGRATION** (`advisor-eval`): ✓ W-1 is a skeleton; ✓ every slice is vertical with outcome + metric; ✓ a spike for the riskiest ADR assumption; ✓ re-run leaves delivered items untouched; ✓ S17 store behavior (preview, ID embedding, no duplicates, stop without connector)
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. Baseline from PR 1 (S16 K arm).
3. Write the skill.
4. Run check + eval; record the rows.

**Aligns with:** D11, D12; greenfield sequence

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** gate G3 — on your real idea's spec, run `solution-architecture` then `delivery-plan`; W-1 and W-2 look like things you would actually build first
