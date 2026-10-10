> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #7: Packaging, registry and upgrade from 0.3.1
**Objective:** the generator registers 19 skills at 0.4.0. Checks enforce registry/skill/wrapper agreement and the sourcing rules. Smoke proves every target and a non-destructive, idempotent 0.3.1 → 0.4.0 upgrade. A real local APM install works.

## Execution State
- **PR status:** review
- **Interaction policy:** autonomous (user, 2026-10-10)
- **Execution scope:** PR 7
- **Scope Profile:** one PR; coordinator = highest unfinished task profile (`verification`); coordination `low`
- **Model routing:** inherit (source repo has no `.agent-army/config.json`)
- **Last manual configuration:** stay current
- **Current task:** none (tasks 7.1–7.3 verified; independent review running)
- **Temporary delegation:** none
- **Active roles:** code-reviewer, security-auditor (one independent read-only subagent)
- **Last verified stage:** 7.1–7.3 verified (2026-10-10): `scripts/check.sh` 203 passed, 0 failed, 1 warning (5 advisors changed since their last eval); `scripts/check.sh --pack` 204/0/1, `apm pack` ok; `scripts/smoke.sh` 220/0 with `apm` 0.33.0 on PATH (scratch venv; gate 3 renders for real for the first time), 151/9 without `apm` (the 9 = gate 3, unchanged baseline). PR 6 accepted by the user ("lecimy dalej")
- **Awaiting decision:** none

---

## Execution Progress
- **Milestones:** 1) registry, versions, upgrade (7.1) · 2) `check.sh` package rules (7.2) · 3) pack + real local install (7.3) · 4) closure
- **Current milestone:** 4 of 4 (closure: independent review)
- **Finish condition:** every task `done` with its Verification Command green, PR at `ready_for_human_review`
- **Last map change:** none
- **Deferred ideas:** none

---

## Interaction Card
none

---

### Task 7.1: Registry, versions, upgrade recommendation

**Task status:** in review — `SKILLS` = `CORE_SKILLS` (5) + `PRODUCT_SKILLS` (14), `PACKAGE_VERSION` 0.4.0, schema 2; detection on the core set, recovery prefers a complete source and copies only missing dirs; `PRESERVED_PATHS` makes `write_text` refuse `.agent-army/stores.json`; the review prints `recommended local diff: <template> -> <local contract>` per changed role template, and a dry run previews skills it would copy. RED `scripts/smoke.sh` 135/25 (5-skill registry, 0.3.1, no recommendation) → GREEN 151/9 without apm, 220/0 with apm (2026-10-10).
**`/ship` before `/bootstrap` (for PR 8):** yes, n = 1. Scratch greenfield repo with only the 19 skills (`.agents/skills` + `.claude/skills`), `claude -p "/ship Slice W-1 walking skeleton …"`: it built the slice (RED test first, then GREEN, CLI prints, workflow YAML parses) with no `.agent-army/`, no config and no blueprint (the "small self-contained description" path). Caveat: turn 1 skipped the independent review/security pass ("no blueprint, ~15 lines"); after "approve, PR 1, Autonomous" turn 2 ran both and fixed the findings. Docs should say: the walking skeleton can go through `/ship` before `/bootstrap`; ask for the review explicitly.

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

**Task status:** in review — `check_package_rules` rules (a)–(f), one line each; never-evaluated advisors are listed as an info line, not a warning. Provoked in a scratch copy: missing wrapper, wrapper with a wrong path, registry drift, `npx skills add` in a skill, foreign `apm install someone/other-skills` in `README.md`, SOURCES row with `main` as commit, broken link → FAIL; edited advisor, 539-char description → WARN; the package's own `apm install psrebrny/agent-army` passes. `scripts/check.sh` 203/0/1 (2026-10-10).

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
- (a) `SKILLS` in `bootstrap.py` == dirs in `.apm/skills/` == files in `.apm/commands/`, each wrapper pointing at `.agents/skills/<name>/SKILL.md`; all 14 product skills carry the contract (completes PR 2's check)
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

**Task status:** in review — `scripts/check.sh --pack` ok (bundle `build/agent-army-0.4.0`: `skills/` + `commands/`, no `SOURCES.md`). `apm install /home/user/agent-army --target <t>` (apm 0.33.0, local path) in fresh scratch repos: claude → 19 skills in `.claude/skills/`; opencode → 19 skills in `.agents/skills/`. Neither target receives the `.apm/commands` wrappers or `SOURCES.md`; both stay only in the `apm_modules/_local/agent-army` cache. Finding for PR 8: four skills say "see `SOURCES.md`" (`product-strategy`, `product-red-team`, `validate-product`, `legal-review`), a dangling pointer in an installed repo; the plan's assumption "attribution lines are already in each skill" holds only for `product-strategy` and `product-red-team` (repo named), partly for `validate-product` (authors, no repo), and not for `legal-review` or `go-to-market`. 7.3 may not write this repo, so nothing was changed.

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
