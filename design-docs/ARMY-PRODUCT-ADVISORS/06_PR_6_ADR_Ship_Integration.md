> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #6: ADRs and the `/ship` boundary
**Objective:** `docs-writer` and the `/ship` docs stage write ADRs with the shared template before commit, move plan decisions into ADRs before a task closes, and mark a delivered work item `delivered` in its bound store. `architect` accepts `docs/product/*` as input. No new mandatory gate.

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

### Task 6.1: `docs-writer`, `/ship` §5 and `architect` inputs

**Task status:** do zrobienia

**Execution Profile:**
- **Capability:** mid
- **Deliberation:** medium
- **Bottleneck:** design_decision
- **Routing rationale:** these are small, targeted edits to three contracts that already exist; the risk is adding a gate or a second ADR format
- **Escalation trigger:** `check.sh` interaction contract fails, or the change creates a new `/ship` pause

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
`docs-writer.md`:
- Extend the ADR skeleton with the shared fields (Type, Supersedes, Source, Basis, Revisit when, Implementation; statuses `Proposed | Accepted | Needs review | Superseded by ADR-NNN`).
- Replace "only if an architectural decision was made" with the manifest's ADR trigger list (product, architecture, process), and keep "no ADR for a trivial fix".
- Replace "never documents unmerged speculation" with: write after the change is verified and the human confirmed the decision, before commit; never present local work as released; `Accepted` ≠ implemented.
- Before closure, sweep the active `design-docs/<task>/` plan for significant decisions without an ADR and propose them. The plan will be deleted, so it cannot be the only rationale.
- Follow the existing ADR directory numbering.
- When the task source is a work item (`W-n`), set only its `status` to `delivered` with the verification evidence link, through the store bound in `.agent-army/stores.json` (repo default). If the bound connector is unavailable, write nothing elsewhere; put "mark W-n delivered in <store>" in the final-review card. No other edits to product records.

`ship/SKILL.md` §5: one sentence pointing to that sweep; no new checkpoint. `architect.md` Phase 1 recon: read `docs/product/brief.md`, `metrics.md` and relevant ADRs when they exist and the task touches them; a `ready` work item (slice, spike or fix) is a valid task source; record its `W-n` in the blueprint, read its acceptance and stories, and follow `Accepted` architecture ADRs. Departing from such an ADR raises the existing architectural-conflict flag and proposes a superseding ADR. Keep both edits minimal (diff hygiene).
- **API/Component Contract:** ADR template field set = contract block field set
- **Compatibility:** existing local `docs-writer` specializations are untouched here; delivery to installed repos is in PR 7 (upgrade recommendation)
- **Refactor checkpoint / recovery:** behavior-preserving for the non-ADR docs flow; `check_interaction_contract` must stay green
- No ADR for this source repo itself (D5 applies to target repos).

**Delegation Contract:**
- **Goal:** one ADR format across advisors and `/ship`, written at the right moment, with no new gate.
- **Inputs / approved read paths:**
  - `.apm/skills/bootstrap/baseline/core/agents/docs-writer.md`
  - `.apm/skills/ship/SKILL.md` §5, `.apm/skills/bootstrap/baseline/core/agents/architect.md` Phase 1
  - `.apm/skills/product-strategy/SKILL.md` (contract ADR block)
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: the three files above (named sections only)
- **Forbidden / never-touch zones:** `_STANDARD.md` required sections; Interaction Card fields
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the edit would require a new `/ship` checkpoint or a field change to the Interaction Card.

**Verification Command:** `scripts/check.sh` (agents + skills)

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = ADR noise on trivial fixes, or rationale lost when the plan is deleted
- **E2E / INTEGRATION:** ✓ `scripts/check.sh docs-writer architect` passes `_STANDARD.md` checks; ✓ the interaction contract is unchanged
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: approved behavior-preserving edit + new documented behavior.
2. Record a passing `scripts/check.sh` baseline.
3. Edit within scope.
4. Run `scripts/check.sh` → same checks pass; record the result.

**Aligns with:** D5; manifest ADR rules

### Task 6.2: ADR parity check + S8 gate

**Task status:** do zrobienia

**Execution Profile:**
- **Capability:** light
- **Deliberation:** low
- **Bottleneck:** verification
- **Routing rationale:** a mechanical comparison of two field lists plus one fixture run
- **Escalation trigger:** S8 produces an ADR for the trivial fix

**Run Configuration:**
- **Role:** tester
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Add `check_adr_parity` to `scripts/check.sh`. It extracts the ADR field names and status set from the `docs-writer.md` skeleton and from the contract block, and fails on any difference. Then run fixture S8 through `/ship`'s docs stage, as a manual evaluation per `tests/fixtures/ship-interaction/README.md` conventions, and record a scorecard row.
- **API/Component Contract:** `check.sh` line `ADR template identical in docs-writer and advisor contract`
- **Compatibility:** none
- **Refactor checkpoint / recovery:** not applicable

**Delegation Contract:**
- **Goal:** drift between the two ADR templates fails CI; S8 shows one ADR vs none.
- **Inputs / approved read paths:** `scripts/check.sh` `check_interaction_contract`; `tests/fixtures/advisors/S8/**`
- **Approved write scope:**
  - `tester`: `scripts/check.sh`, `tests/fixtures/advisors/SCORECARDS.md`
  - `coder` / main session: none
- **Forbidden / never-touch zones:** `.apm/**`
- **Start gate:** Interactive: RED card | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** parity requires changing the contract (new tag + G1 re-run).

**Verification Command:** `scripts/check.sh --skills`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = two ADR dialects in one target repo
- **E2E / INTEGRATION** (`scripts/check.sh`): ✓ identical fields → PASS; ✓ a field removed from `docs-writer` → FAIL; ✓ S8 row: ADR for the architectural change only
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: new behavior (check).
2. Write the check, temporarily drop one field in a scratch copy → **RED**.
3. Restore.
4. Run → GREEN; record; run S8.

**Aligns with:** Contract surfaces (ADR template)

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** read the new `docs-writer` ADR section; confirm that a typo fix in S8 produced no ADR
