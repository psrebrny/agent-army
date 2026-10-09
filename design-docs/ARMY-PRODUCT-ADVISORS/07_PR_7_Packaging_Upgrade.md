> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #7: Packaging, registry and upgrade from 0.3.1
**Objective:** the generator registers 19 skills at 0.4.0. Checks enforce registry/skill/wrapper agreement and the sourcing rules. Smoke proves every target and a non-destructive, idempotent 0.3.1 → 0.4.0 upgrade. A real local APM install works.

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

### Task 7.1: Registry, versions, upgrade recommendation

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** a small code change with migration risk; `is_agent_army_skills()` requiring all names changes how a 0.3.1 install (5 skills) is detected
- **Escalation trigger:** a 0.3.1 fixture loses a local file or `bootstrap` treats it as foreign

**Run Configuration:**
- **Role:** coder
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
In `bootstrap.py`, set `SKILLS` to the 19 names, `PACKAGE_VERSION = "0.4.0"` and leave `PROFILE_SCHEMA_VERSION = 2`. Make Agent Army detection depend on the 0.3.1 core set (`bootstrap`, `ship`, `new-agent`, `new-skill`, `adapt-army` + `bootstrap.py`), so a 5-skill install is still recognised. Recovery copies only missing skill dirs (`dst.exists()` → skip, as today). In `apm.yml`, set version `0.4.0` and correct the description (skill count, advisors). In `bootstrap/SKILL.md` "Incremental Upgrade Review", the inventory delta lists the new advisors as capabilities, and the recommended diff is the `docs-writer` ADR change applied to the local specialized `.agent-army/agents/docs-writer` contract, merged into the specialization rather than replacing it. `apply`/`skip` is recorded via the existing `--upgrade-review-outcome`. Update the bootstrap description's version string. Add `.agent-army/stores.json` to the generator's preserved, never-written paths. Verify whether `/ship` can run before `/bootstrap` in a scratch greenfield repo (needed by the walking-skeleton sequence); record the answer for PR 8 docs.
- **API/Component Contract:** `SKILLS` (19); `PACKAGE_VERSION` 0.4.0; profile schema 2
- **Compatibility:** consumers `materialize_skills`, `package_inventory`, upgrade review, smoke
- **Refactor checkpoint / recovery:** existing smoke profiles must pass before and after; recovery action = revert the registry edit
- Never overwrite existing local skill dirs or `.agent-army/agents/*`.

**Delegation Contract:**
- **Goal:** a 0.4.0 package installs 19 skills and upgrades 0.3.1 without touching local decisions.
- **Inputs / approved read paths:** `bootstrap.py` lines 30–45, 460–540; `bootstrap/SKILL.md` §Update detection, §Incremental Upgrade Review; `apm.yml`
- **Approved write scope:**
  - `tester`: `scripts/smoke.sh`, `tests/fixtures/**` (upgrade fixture)
  - `coder` / main session: `.apm/skills/bootstrap/bootstrap.py`, `.apm/skills/bootstrap/SKILL.md`, `apm.yml`
- **Forbidden / never-touch zones:** profile schema; ownership/control logic; baseline agents
- **Start gate:** Interactive: RED card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a profile schema bump looks necessary.

**Verification Command:** `scripts/smoke.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = destructive or non-idempotent upgrade for existing users. The cheapest reliable level is the smoke integration test.
- **E2E / INTEGRATION** (`scripts/smoke.sh`):
  - ✓ every target: all 19 `.agents/skills/<name>/SKILL.md` present (loop over the list; replaces "five shared skills" at `smoke.sh:308`)
  - ✓ no native agent files for any advisor name in any target
  - ✓ 0.3.1 fixture with 5 skills + local docs-writer specialization → `--mode auto` migrates; local files byte-identical; the 14 missing skills are added
  - ✓ second run → no-op (no writes)
  - ✓ a pre-existing `.agent-army/stores.json` is byte-identical after first bootstrap, upgrade and `--mode full`
  - ✓ `skip` outcome preserves the local docs-writer; `applied` records the outcome
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: new behavior + migration.
2. Write the smoke assertions → run → **RED** (5-skill registry).
3. Change the registry, detection, versions and upgrade review.
4. Run `scripts/smoke.sh` → GREEN; record.

**Aligns with:** D7, D8; constraint "profile schema v2 unchanged"

### Task 7.2: `check.sh` package rules

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** deterministic file checks modelled on existing ones
- **Escalation trigger:** a rule produces a false positive on existing skills

**Run Configuration:**
- **Role:** tester
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Add to `check.sh --skills`:
- (a) `SKILLS` in `bootstrap.py` == dirs in `.apm/skills/` == files in `.apm/commands/`, each wrapper pointing at `.agents/skills/<name>/SKILL.md`; all 14 product skills carry the contract (completes PR 2's check); all 19 skills and the baseline `AGENTS.md` carry `interaction-pace:v1` (D16)
- (b) no third-party install guidance in `.apm/**` or `README.md` (`npx skills`, `/plugin install`, `apm install` of any package other than `psrebrny/agent-army`)
- (c) `.apm/SOURCES.md` rows have repo, file, commit (7+ hex), license
- (d) WARN when an advisor description is > 300 chars
- (e) relative links in `.apm/README.md` and advisor skills resolve
- (f) WARN when an advisor's `SKILL.md` sha256[:12] or contract tag differs from its latest `SCORECARDS.md` row ("advisor changed since last eval; run advisor-eval")
- **API/Component Contract:** each rule prints one ok/bad/warn line
- **Compatibility:** none
- **Refactor checkpoint / recovery:** baseline: existing checks stay green

**Delegation Contract:**
- **Goal:** packaging and sourcing rules are enforced, and eval staleness is visible.
- **Inputs / approved read paths:** `scripts/check.sh`; `tests/fixtures/advisors/SCORECARDS.md`
- **Approved write scope:**
  - `tester`: `scripts/check.sh`
  - `coder` / main session: none
- **Forbidden / never-touch zones:** `.apm/**`
- **Start gate:** Interactive: RED card | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a rule would flag the package's own `apm install psrebrny/agent-army` docs.

**Verification Command:** `scripts/check.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = silent registry drift; a "menu" of third-party skills creeping back in
- **E2E / INTEGRATION** (`scripts/check.sh`): ✓ a missing wrapper → FAIL; ✓ an `npx skills add` line in a skill → FAIL; ✓ a SOURCES row without commit → FAIL; ✓ an edited advisor → WARN
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: new behavior.
2. Add the rules, provoke each failure in a scratch copy → **RED**.
3. Restore.
4. Run `scripts/check.sh` → GREEN; record.

**Aligns with:** D2; Contract surfaces (registry)

### Task 7.3: Pack and real local install

**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** runs existing commands; checks the `SOURCES.md` packaging assumption
- **Escalation trigger:** APM drops root files in `.apm/`

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Run `scripts/check.sh --pack`. In a fresh scratch git repo, install the **local** working tree (not the GitHub release) via APM for `claude` and `opencode`. Confirm the 19 skills, the wrappers, and whether `SOURCES.md` ships. If it does not ship, move the attribution lines into each advisor's skill (they are already there) and keep `SOURCES.md` as source-repo only, documented in PR 8.
- **API/Component Contract:** none
- **Compatibility:** none
- **Refactor checkpoint / recovery:** not applicable

**Delegation Contract:**
- **Goal:** proof that the real install path delivers the package.
- **Inputs / approved read paths:** `AGENTS.md` "End-to-end"
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: scratch dir only
- **Forbidden / never-touch zones:** this repo's working tree
- **Start gate:** Interactive: confirm the scratch path | Autonomous: scratch only
- **STOP and return `awaiting_approval` when:** APM is not installed (record `INSUFFICIENT_EVIDENCE`).

**Verification Command:** `scripts/check.sh --pack` + listing of scratch `.agents/skills/`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = works in smoke, fails in real APM
- **E2E / INTEGRATION:** ✓ 19 skills in scratch for claude + opencode; ✓ the `SOURCES.md` presence is recorded
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: verification run.
2. Not applicable.
3. Run.
4. Record the listings.

**Aligns with:** manifest §4 E2E

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** in a copy of one of your 0.3.1 repos, `apm update` + `/bootstrap` shows the upgrade card; `skip` leaves `docs-writer` untouched
