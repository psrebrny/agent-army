> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #6: ADRs and the `/ship` boundary
**Objective:** `docs-writer` and the `/ship` docs stage write ADRs with the shared template before commit, move plan decisions into ADRs before a task closes, and mark a delivered work item `delivered` in its bound store. `architect` accepts `docs/product/*` as input. `/ship` recommends an interaction mode from the tasks' Execution Profiles (D13). Blueprint task statuses are English (D14) and the Execution Profile drops `Capability` and `Deliberation` (D15). `/ship` and the baseline `AGENTS.md` carry the collaborative-pace text (D16), and Interactive mode pauses once before and once after each task (D19). No new mandatory gate.

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

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** these are small, targeted edits to three contracts that already exist; the risk is adding a gate or a second ADR format
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

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** a mechanical comparison of two field lists plus one fixture run
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

### Task 6.3: Mode recommendation in `/ship`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** a small edit to an existing, checked contract; the risk is turning a recommendation into a new pause or a third mode
- **Escalation trigger:** `check_interaction_contract` fails, or the wording makes the recommendation binding

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
`ship/SKILL.md` §1 EXECUTION POLICY, where it asks for the mode when `Interaction policy` is `unset`: add one recommendation with a one-line reason. Recommend **Interactive** if any selected task has `Bottleneck` `design_decision | multiple_approaches | unknown`, or its Verification Command is not runnable (a manual evaluation such as scorecard rows does not count), and name those tasks. Otherwise recommend **Autonomous**. The user decides; the recommendation never sets the mode and is not repeated after the choice. In Interactive mode, the task-review card's `Review focus` says "remaining tasks qualify for autonomous" when that becomes true; the existing `switch to autonomous` option does the rest. `architect.md` (PR template guidance): within a PR, order decision-heavy tasks first when dependencies allow; write each task to be as close to autonomous-ready as the work honestly allows (settle design decisions with the user during planning, give a runnable Verification Command where one exists), but never downgrade `Bottleneck` or add a cosmetic command to earn the Autonomous recommendation. Extend `check_interaction_contract` so that every bottleneck value named in the `/ship` rule is in the `architect.md` `Bottleneck` enum. Add the manual fixture `tests/fixtures/ship-interaction/mode-recommendation/` (`request.md`, `expected.md`) and its row in that README's table.
- **API/Component Contract:** unchanged mode enum (`autonomous | interactive | unset`), unchanged Interaction Card field set; new `check.sh` assertion "mode rule names only known bottlenecks"
- **Compatibility:** PRs with a persisted policy are untouched; legacy `supervised` migration is unchanged
- **Refactor checkpoint / recovery:** behavior-preserving except for the added recommendation text; `check_interaction_contract` stays green
- No new pause, mode, card field or gate.

**Delegation Contract:**
- **Goal:** the mode question carries one justified recommendation, and drift between the rule and the bottleneck enum fails CI.
- **Inputs / approved read paths:**
  - `.apm/skills/ship/SKILL.md` §1
  - `.apm/skills/bootstrap/baseline/core/agents/architect.md` (Execution Profile, PR template)
  - `scripts/check.sh` `check_interaction_contract`
  - `tests/fixtures/ship-interaction/README.md`, `autonomous/`, `policy-variants/`
- **Approved write scope:**
  - `tester`: `scripts/check.sh`, `tests/fixtures/ship-interaction/mode-recommendation/**`, `tests/fixtures/ship-interaction/README.md` (table row)
  - `coder` / main session: `.apm/skills/ship/SKILL.md` §1, `architect.md` (two sentences), `README.md` interaction-modes paragraph (one sentence)
- **Forbidden / never-touch zones:** Interaction Card fields; the two-mode enum; `_STANDARD.md` required sections
- **Start gate:** Interactive: RED card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the rule would need a new pause, a card field or a third mode.

**Verification Command:** `scripts/check.sh` (agents + skills)

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = a recommendation that silently becomes a gate, or a rule that drifts from the enum
- **E2E / INTEGRATION** (`scripts/check.sh`): ✓ known bottlenecks → PASS; ✓ an unknown value in the rule → FAIL; ✓ existing interaction assertions unchanged
- **E2E / INTEGRATION** (manual fixture `mode-recommendation`): ✓ a PR with a `design_decision` task → Interactive, task named; ✓ all tasks `verification` with a runnable command → Autonomous; ✓ the user picks the other mode → honored, no argument; ✓ Autonomous run has no extra pause
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: new behavior (check) + approved edit to an existing contract.
2. Add the check; in a scratch copy, name a non-existent bottleneck in the rule → **RED**.
3. Write the rule and the architect sentence; remove the scratch copy.
4. Run `scripts/check.sh` → GREEN; run the fixture manually; record the result.

**Aligns with:** D13; constraint "No new mandatory gate in `/ship`"

### Task 6.4: English status vocabulary and a reduced Execution Profile

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** two vocabularies and the routing policy are shared by `architect.md`, `/ship` and `check.sh`; the risk is breaking resume of existing blueprints or leaving `/ship` §1.4–1.6 routing on fields that no longer exist
- **Escalation trigger:** a legacy Polish status cannot be mapped one-to-one, or §1.4–1.6 cannot route a task without capability/deliberation

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
- **D14:** in `architect.md` (PR skeleton) and `ship/SKILL.md` (§1 MANDATORY BLUEPRINT + ROUTING + SCOPE GATE status mapping, §1.7 "New plan tasks remain …"), replace the task status vocabulary with `open | in progress | in testing | in review | done | awaiting decision | blocked | conditional`, mapped one-to-one from `do zrobienia | w trakcie | do testów | do review | wykonane | czeka na decyzję | zablokowane | warunkowe`. `/ship` accepts the legacy value on read and writes the English one on its next update of that task. `check.sh` (the `Task status` assertion near line 216) accepts the English skeleton. Update the blueprint fixtures under `tests/fixtures/ship-interaction/**/design-docs/` and `tests/fixtures/planning-roles/**/blueprint/`, keeping one fixture with a legacy Polish status to prove the mapping.
- **D15:** in the `architect.md` Execution Profile skeleton and Principle 5, drop `Capability` and `Deliberation` and rename `Routing rationale` to `Bottleneck rationale`. In `ship/SKILL.md`: §1.4 Scope Profile derives coordination from the selected scope and bottlenecks, not from task capability; §1.5 keeps the `Bottleneck` table, with "increase deliberation by one step" read as one effort step of the tool when it supports it; §1.6 routes each role from `model_routing` (bootstrap) or the tool default, with no per-task capability recommendation. The role capability tiers in bootstrap routing stay unchanged. `/ship` ignores `Capability`/`Deliberation` lines in legacy blueprints.
- **API/Component Contract:** task status enum (English, plus legacy read mapping); Execution Profile fields `Bottleneck | Bottleneck rationale | Escalation trigger`; Interaction Card unchanged; mode enum unchanged
- **Compatibility:** existing blueprints in target repos resume unchanged (legacy statuses mapped, extra profile lines ignored); role model routing in `.agent-army/config.json` unchanged; profile schema stays `2`
- **Refactor checkpoint / recovery:** passing `scripts/check.sh` and `scripts/smoke.sh` before the edit; the same checks green after; revert the three files if the legacy fixture stops resuming
- No new mode, pause, card field or gate.

**Delegation Contract:**
- **Goal:** new blueprints carry English statuses and no capability/deliberation, and a blueprint written by 0.3.1 still resumes.
- **Inputs / approved read paths:**
  - `.apm/skills/bootstrap/baseline/core/agents/architect.md` (Principle 5, PR skeleton)
  - `.apm/skills/ship/SKILL.md` §1 (status mapping) and §1.4–1.7
  - `scripts/check.sh`, `scripts/smoke.sh`
  - `tests/fixtures/ship-interaction/**`, `tests/fixtures/planning-roles/**`
- **Approved write scope:**
  - `tester`: `scripts/check.sh`, `tests/fixtures/ship-interaction/**/design-docs/**`, `tests/fixtures/planning-roles/**/blueprint/**`
  - `coder` / main session: `.apm/skills/ship/SKILL.md` §1 (status mapping) and §1.4–1.7, `.apm/skills/bootstrap/baseline/core/agents/architect.md` (Principle 5, PR skeleton)
- **Forbidden / never-touch zones:** Interaction Card fields; the two-mode enum; bootstrap role routing and `.agent-army/config.json` schema; `_STANDARD.md` required sections
- **Start gate:** Interactive: RED card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the change needs a profile schema bump, a bootstrap migration, or a new card field.

**Verification Command:** `scripts/check.sh && scripts/smoke.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = an old blueprint that no longer resumes, or routing text that still depends on removed fields; `check.sh` structure plus the existing fixtures is the cheapest reliable level
- **E2E / INTEGRATION** (`scripts/check.sh`): ✓ English skeleton → PASS; ✓ a skeleton still containing `Capability:` → FAIL; ✓ a Polish status in the skeleton → FAIL
- **E2E / INTEGRATION** (manual fixture): ✓ the legacy-status fixture resumes and its task is rewritten with the English status; ✓ no `Capability`/`Deliberation` appears in a newly planned task
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: approved change to existing contracts + new check assertions.
2. Change the `check.sh` assertions first → **RED** against the current skeleton.
3. Edit `architect.md`, `ship/SKILL.md` and the fixtures.
4. Run `scripts/check.sh && scripts/smoke.sh` → GREEN; run the legacy fixture manually; record the result.

**Aligns with:** D14, D15; constraint "No new mandatory gate in `/ship`"

### Task 6.5: Collaborative pace in `/ship` and the baseline `AGENTS.md`

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** the block text is fixed in the manifest; the hard part is showing that a real session follows it, which no grep can prove
- **Escalation trigger:** the block conflicts with an existing rule (for example the `/ship` Interaction Card fields or the architect's milestone map)

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Copy the `interaction-pace:v1` paragraph (manifest §3, D16; authoritative copy in the advisor contract) verbatim into `ship/SKILL.md` (DELIVERY-FOCUSED INTERACTION; covers `architect` and every role `/ship` runs) and the baseline `AGENTS.md` (next to "Delivery-focused interaction"; read by every tool in a target repo, so the other skills follow it without their own copy). Do not copy it into individual skills. Where a file already has a rule on question count or progress lines (`/ship` progress line, the architect's "step X of approximately Y"), keep it and let the paragraph govern size, rhythm and the shared `step X of ~Y` marker format. Add the manual fixture `tests/fixtures/ship-interaction/pace/` (`request.md`, `expected.md`) and its README row.
- **API/Component Contract:** the three copies are identical (`check_interaction_pace` from Task 2.1); Interaction Card fields, modes and gates unchanged
- **Compatibility:** an existing target-repo `AGENTS.md` and local `/ship` specializations receive the paragraph through the upgrade review in PR 7, merged, not replaced
- **Refactor checkpoint / recovery:** `scripts/check.sh` and `scripts/smoke.sh` green before and after
- No new pause, mode, card field or gate.

**Delegation Contract:**
- **Goal:** `/ship` and the baseline `AGENTS.md` carry the pace paragraph identical to the contract's, and a manual run shows short turns with one question each.
- **Inputs / approved read paths:**
  - manifest §3 (block text), D16
  - `.apm/skills/ship/SKILL.md`, `.apm/skills/bootstrap/baseline/AGENTS.md`, the advisor contract in `.apm/skills/product-strategy/SKILL.md`
  - `tests/fixtures/ship-interaction/README.md`
- **Approved write scope:**
  - `tester`: `tests/fixtures/ship-interaction/pace/**`, `tests/fixtures/ship-interaction/README.md` (table row)
  - `coder` / main session: `.apm/skills/ship/SKILL.md`, `.apm/skills/bootstrap/baseline/AGENTS.md` (paragraph only)
- **Forbidden / never-touch zones:** Interaction Card fields; the two-mode enum; `_STANDARD.md` required sections
- **Start gate:** Interactive: RED card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** the paragraph would need different wording in `/ship` or `AGENTS.md` (it must stay identical).

**Verification Command:** `scripts/check.sh && scripts/smoke.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = copies that drift, or a rule nobody follows in a real session
- **E2E / INTEGRATION** (`scripts/check.sh`): ✓ three identical copies → PASS; ✓ one edited copy → FAIL
- **E2E / INTEGRATION** (manual fixture `pace`): ✓ a planning turn stays about one screen with one question; ✓ a long test run is announced with an estimate before it starts; ✓ every turn shows `step X of ~Y`, and a changed total is announced with its reason; ✓ "give me everything" is honoured
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: approved edit to existing contracts.
2. In a scratch copy, change one word in one copy → `check_interaction_pace` **RED**.
3. Copy the paragraph into both files; remove the scratch copy.
4. Run the verification command → GREEN; run the fixture manually; record the result.

**Aligns with:** D16


### Task 6.6: Lighter `/ship` Interactive mode

**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** the user found today's Interactive flow (separate RED, GREEN and review cards, statuses in the chat) heavy while running PR 2; which pauses carry real decisions and which are ceremony is a judgment the user makes with us, not a fact to look up
- **Escalation trigger:** removing a pause would also remove a decision the user must make (scope, risk, external action, commit), or the lighter flow conflicts with D13's mode recommendation

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** the shape of the lighter flow (below) is settled with the user before the edit

**Action:**
Make Interactive mode feel like a conversation, building on the pace paragraph from Task 6.5 (run 6.5 first). Starting proposal, to be confirmed with the user: (1) **one pause before a task** (behavior, cases, verification, write list in one short card; replaces the separate RED / baseline / implementation acceptance pauses unless a real behavior decision is open) and **one pause after it** (result, evidence, next task; the task review); (2) RED/GREEN evidence, statuses and milestones stay in the PR file and the chat shows only `step X of ~Y` plus what changed; (3) "decide together, then let it run" (D13) as the default path: once the remaining tasks qualify for Autonomous, the card offers `switch to autonomous` in one line; (4) the always-on stops stay in both modes: external or irreversible actions, security/privacy/compliance decisions, breaking contracts, scope expansion, final review, commit approval. Update `ship/SKILL.md` (INTERACTION CARD, DELIVERY-FOCUSED INTERACTION, EXECUTION POLICY) and the matching `architect.md` card/checkpoint list, then `check_interaction_contract` so author and executor still agree.
- **API/Component Contract:** still two modes (`autonomous | interactive`); the Interaction Card keeps its eight fields; the `Checkpoint` set may shrink (for example `RED acceptance`, `baseline acceptance`, `implementation acceptance` folded into one `task plan`), and `check_interaction_contract` asserts the new set in both files
- **Compatibility:** a PR file paused at a removed checkpoint resumes as `task plan`, keeping its evidence; Autonomous mode is unchanged
- **Refactor checkpoint / recovery:** `scripts/check.sh` and `scripts/smoke.sh` green before and after
- No new mode, card field or gate; fewer routine pauses only.

**Delegation Contract:**
- **Goal:** an Interactive `/ship` run on a small PR pauses about twice per task, each pause one screen with one question, and still stops at every required decision.
- **Inputs / approved read paths:**
  - `.apm/skills/ship/SKILL.md`, `.apm/skills/bootstrap/baseline/core/agents/architect.md`
  - `scripts/check.sh` `check_interaction_contract`
  - the PR 2 execution log in `02_PR_2_Contract_Discovery_Advisors.md` (what felt heavy)
- **Approved write scope:**
  - `tester`: `scripts/check.sh` (`check_interaction_contract` checkpoint set), `tests/fixtures/ship-interaction/light-interactive/**`, `tests/fixtures/ship-interaction/README.md` (table row)
  - `coder` / main session: `.apm/skills/ship/SKILL.md`, `.apm/skills/bootstrap/baseline/core/agents/architect.md` (card and checkpoint text only)
- **Forbidden / never-touch zones:** the two-mode enum; the eight card fields; the always-on stops listed above; the `interaction-pace:v1` paragraph
- **Start gate:** Interactive: card with the agreed flow and write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a pause the user wants removed guards a decision listed under always-on stops.

**Verification Command:** `scripts/check.sh && scripts/smoke.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = a lighter flow that skips a decision the user needed, or author/executor drift
- **E2E / INTEGRATION** (`scripts/check.sh`): ✓ `ship` and `architect` checkpoint sets agree → PASS; ✓ one file still lists `RED acceptance` → FAIL
- **E2E / INTEGRATION** (manual fixture `light-interactive`): ✓ a two-task PR pauses before and after each task, no more; ✓ an external action still stops; ✓ a legacy PR paused at `RED acceptance` resumes as `task plan`
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: approved edit to existing contracts (behavior change of the Interactive flow).
2. Agree the flow with the user; update `check_interaction_contract` to the new checkpoint set → **RED** against today's files.
3. Edit `ship/SKILL.md` and `architect.md`.
4. Run the verification command → GREEN; run the fixture manually; record the result.

**Aligns with:** D13, D16, D19

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** read the new `docs-writer` ADR section; confirm that a typo fix in S8 produced no ADR
> - [ ] **Functional:** the `/ship` mode question shows one recommendation with a reason; your choice wins
> - [ ] **Functional:** an Interactive `/ship` run on a small PR pauses once before and once after each task, and still stops for external actions and commit (Task 6.6)
> - [ ] **Functional:** a new blueprint shows English task statuses and no `Capability`/`Deliberation`; an old blueprint with `do zrobienia` still resumes
