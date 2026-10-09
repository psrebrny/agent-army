> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #5: `/product` navigator and store bindings
**Objective:** `/product` shows where the user is, what they skipped or let go stale, and the one next step, reading through the stores. It also shows and changes the project's store bindings. It runs last among the product skills, because it reads every record schema from PR 2–4.

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

### Task 5.1: `/product` navigator

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** the value is in correct judgment over many records (done vs partial, stale, skipped) and in restraint (one step, no nagging)
- **Escalation trigger:** S12 output marks a stage done from file presence alone, ignores the recorded skip, or recommends more than one step

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
The navigator reads only status-bearing parts through the bound stores: register, stories, work item statuses, ADR statuses, `Conversation state` and verdict sections. It never reads the whole repo. It applies the 12-stage model from the contract and prints one line per stage, `done | partial | missing | stale | skipped`, with the reason and the record source. Next come warnings for gaps before the current stage, with the consequence ("ads before measurement is verified: you won't know what worked"), then stale items (ADR `Needs review`, disproved `A`), then one recommended next step (skill or `/ship W-n`, why, what it unblocks), then "Not assessed". It asks at most one question, typically "skip this stage on purpose?". A "yes" writes a `skip` record. With no product records, it recommends `/product-strategy`. In a repo without a product (library, internal tool), it says the model does not apply. Bindings mode (`/product stores`): it lists the bindings and offers to change one. A change is an explicit migration (list of records, ID preservation, old location keeps only a pointer) that runs after confirmation. Wrapper plus ≥ 2 examples (empty repo; mid-journey with a skip and an external work-item store).
- **API/Component Contract:** map line `N. Stage — state — reason (record source)`; `skip` record `stage | reason | date | revisit when`
- **Compatibility:** reads every record type; schema changes in the contract require re-running G4
- **Refactor checkpoint / recovery:** not applicable
- Warnings never block. The navigator never runs other skills or starts `/ship`.

**Delegation Contract:**
- **Goal:** passes G4 on S12 and S3; the map is correct from the records alone, whichever store they live in.
- **Inputs / approved read paths:** manifest §3 stage model + store rules; PR 2–4 skills (record schemas)
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/product/**`, `.apm/commands/product.md`
- **Forbidden / never-touch zones:** contract block text; other skills; tool-specific instructions
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a stage criterion cannot be judged from a record schema (the schema needs a field: contract change + re-run of earlier gates).

**Verification Command:** `scripts/check.sh --skills` then `advisor-eval product --scenario S12 S3`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = false "you're ready", or nagging that the user learns to ignore
- **E2E / INTEGRATION** (`advisor-eval`):
  - ✓ S12: stage 3 `missing` despite a planned experiment; warnings on build before validation and on spend before measurement; the legal skip is `skipped`; exactly one recommendation
  - ✓ S3 resume: map consistent with register + ADR; no repeated questions
  - ✓ empty product records → recommends `/product-strategy`
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. Baseline from PR 1 (S12 K arm: a plain session asked "where am I?").
3. Write the skill.
4. Run check + eval; record the rows.

**Aligns with:** D9; stage model; "no orchestrator"

### Task 5.2: External store evidence (S17 across skills)

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** this proves the seam with a real connector without shipping anything tool-specific
- **Escalation trigger:** a duplicate item, a delete attempt, or a silent repo fallback

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
In a scratch project, bind `work_item` and then `adr` to connectors the evaluator has (any tracker and any docs tool; record which ones in the scorecard note only). Run `delivery-plan` (create, then re-plan), `/product` (read state and show bindings) and the `/ship` docs-stage status update from PR 6 once it exists; until then, a manual status edit. Remove the connector and repeat one write. Clean up the scratch items afterwards. No tool name enters `.apm/**`.
- **API/Component Contract:** none new; exercises `stores.json` and the store rules
- **Compatibility:** none
- **Refactor checkpoint / recovery:** scratch project and scratch tool containers only; recovery = delete the scratch container manually (the skills never delete)

**Delegation Contract:**
- **Goal:** scorecard evidence that the seam works with two real external stores and fails safely without them.
- **Inputs / approved read paths:** `tests/fixtures/advisors/S17/**`
- **Approved write scope:**
  - `tester`: `tests/fixtures/advisors/SCORECARDS.md`
  - `coder` / main session: scratch project; scratch containers in the user's tools only
- **Forbidden / never-touch zones:** the user's real projects, boards or folders
- **Start gate:** Interactive: confirm which connectors and scratch containers to use | Autonomous: not allowed (outward-facing writes)
- **STOP and return `awaiting_approval` when:** no scratch container is available in a tool.

**Verification Command:** S17 scorecard rows for `work_item` and `adr` bindings

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = duplicates or data loss in a user's tracker
- **E2E / INTEGRATION:** ✓ first batch previewed; ✓ re-run updates the same items; ✓ no delete; ✓ status `delivered` visible to `/product`; ✓ connector removed → stop and ask
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: verification run.
2. Not applicable.
3. Run in scratch.
4. Record rows; confirm cleanup.

**Aligns with:** D12; external-store constraints

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** gate G4 — run `/product` on your real idea's records; the map matches what you did and skipped. Bind work items to a tracker of your choice in a scratch project and see `/product` read them.
