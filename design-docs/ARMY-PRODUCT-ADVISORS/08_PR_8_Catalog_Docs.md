> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #8: Catalog, docs and final verification
**Objective:** documentation matches delivered behavior. `.apm/README.md` becomes the real catalog with the `/ship` boundary table, and the root, baseline and test docs are correct.

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

### Task 8.1: `.apm/README.md` catalog

**Task status:** do zrobienia

**Execution Profile:**
- **Capability:** mid
- **Deliberation:** low
- **Bottleneck:** retrieval
- **Routing rationale:** describes skills that already exist; the risk is overclaiming
- **Escalation trigger:** a catalog claim has no matching skill text

**Run Configuration:**
- **Role:** docs-writer
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Replace the "proposals" framing with the delivered catalog. Open with "Not sure where to start? Run `/product`" and the 12-stage model and how to bind work items/ADRs to a tool of the project's choice (`.agent-army/stores.json`; no tool is recommended) (done criteria, what should precede what). For each of the 19 skills: when to use it, inputs, output files, when it writes, one invocation example. Add the "standalone vs hands off to `/ship`" table and the lifecycle paths from the manifest, with no orchestrator. Describe ADRs: where they live, who writes them, when they don't. Link no third-party skill.
- **API/Component Contract:** none
- **Compatibility:** `check.sh` link rule (PR 7)
- **Refactor checkpoint / recovery:** not applicable

**Delegation Contract:**
- **Goal:** a new user finds the entry point (`/product`), can pick the right advisor and knows what reaches `/ship`.
- **Inputs / approved read paths:** `.apm/skills/*/SKILL.md`; manifest §3
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/README.md`
- **Forbidden / never-touch zones:** skills
- **Start gate:** Interactive: card | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a skill's actual behavior contradicts the manifest.

**Verification Command:** `scripts/check.sh --skills`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = docs promising behavior the skills lack
- **E2E / INTEGRATION:** ✓ 19 rows; ✓ links resolve; ✓ no third-party install lines
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: documentation.
2. Not applicable.
3. Write.
4. Run the check; cross-read each row against its skill.

**Aligns with:** `/ship` boundary table

### Task 8.2: Root, baseline and test docs + final verification

**Task status:** do zrobienia

**Execution Profile:**
- **Capability:** light
- **Deliberation:** low
- **Bottleneck:** retrieval
- **Routing rationale:** small factual edits in known places
- **Escalation trigger:** final verification fails

**Run Configuration:**
- **Role:** docs-writer
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
- `README.md`: a short table of the 19 skills plus a link to the catalog.
- `AGENTS.md` (this repo): skill count, key files (`SOURCES.md`, advisors), and the `advisor-eval` maintainer workflow by path (`.claude/skills/advisor-eval/SKILL.md`) so non-Claude tools can follow it. Also add the rule: any advisor or contract change → re-run `advisor-eval`.
- Baseline `AGENTS.md`: list the available workflows, advisors included.
- `tests/GUIDE.md`: an advisor evaluation section (fixtures, scorecards, staleness warning, "scorecards only, no transcripts").
- `apm.yml` description is already fixed in PR 7.

Then run the final verification and confirm every advisor's latest scorecard is current (no staleness WARN).
- **API/Component Contract:** none
- **Compatibility:** none
- **Refactor checkpoint / recovery:** not applicable

**Delegation Contract:**
- **Goal:** every doc states the delivered behavior; all checks are green.
- **Inputs / approved read paths:** files above; PR 1–7 results
- **Approved write scope:**
  - `tester`: `tests/GUIDE.md`
  - `coder` / main session: `README.md`, `AGENTS.md`, `.apm/skills/bootstrap/baseline/AGENTS.md`
- **Forbidden / never-touch zones:** `CLAUDE.md` (pointer only)
- **Start gate:** Interactive: card | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a staleness WARN remains (run `advisor-eval` first).

**Verification Command:** `scripts/check.sh && scripts/smoke.sh && scripts/check.sh --pack`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = stale counts ("four/five skills") and links that don't resolve
- **E2E / INTEGRATION:** ✓ all three commands green; ✓ `grep -rn "five shared skills\|four live skills"` empty
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: documentation + final verification.
2. Not applicable.
3. Edit.
4. Run the full verification; record the outputs.

**Aligns with:** manifest §2 last item

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** read `.apm/README.md` as a new user: pick an advisor for "I have an idea, no product yet" and for "people sign up but don't buy"
