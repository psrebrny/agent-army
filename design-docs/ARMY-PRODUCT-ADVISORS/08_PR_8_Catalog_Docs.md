> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #8: Catalog, docs and final verification
**Objective:** documentation matches delivered behavior. `.apm/README.md` becomes the real catalog with the `/ship` boundary table, and the root, baseline and test docs are correct.

## Execution State
- **PR status:** ready_for_human_review
- **Interaction policy:** autonomous (user, 2026-10-10)
- **Execution scope:** PR 8
- **Scope Profile:** one PR; coordinator = highest unfinished task profile (`retrieval`); coordination `low`
- **Model routing:** inherit (source repo has no `.agent-army/config.json`)
- **Last manual configuration:** stay current
- **Current task:** none (closure done)
- **Temporary delegation:** none
- **Active roles:** none
- **Last verified stage:** closure (2026-10-10): with apm 0.33.0 `scripts/check.sh` 204/0/0, `scripts/smoke.sh` 249/0, `scripts/check.sh --pack` 205/0/0 (no staleness WARN: every product skill matches its latest SCORECARDS row); stale-count grep empty. `advisor-eval` (N,K, one scenario each, 13 advisors): 11 `pass`; `product` S12 and `product-spec` S13 `rethink`; `product-metrics` S10 first `fix-contract` (misread the CSV: "about 10 visits per variant per week", file shows 19–25), Reads step fixed at the user's request, rerun `pass` ff0; `ux-review` S6 and `go-to-market` S4 each lost one run to malformed judge JSON (no row; rerun). Cost from the ledger ≈ $34 (+ ≈ $3–5 for the runs without a row). Independent review (fresh context) `APPROVED`; its 2 medium + 2 low doc fixes applied
- **Awaiting decision:** final review

---

## Execution Progress
- **Milestones:** 1) catalog (8.1) · 2) root/baseline/test docs (8.2) · 3) `advisor-eval` for the 12 advisors without a current row · 4) final verification
- **Current milestone:** 4 of 4 (closure done)
- **Finish condition:** 8.1 and 8.2 `done`, all three verification commands green, no staleness WARN, PR at `ready_for_human_review`
- **Last map change:** scope expansion (user, 2026-10-10): APM does not install `.apm/SOURCES.md` (PR 7, Task 7.3), so the "see `SOURCES.md`" pointers in `product-strategy`, `product-red-team`, `validate-product` and `legal-review` dangled in an installed repo. The user chose to fix the skills now: each names its source repo and license inline, `go-to-market` gains its missing `marketing-loops` attribution, and `SOURCES.md` says it stays in the source repo. `product-strategy` joins the `advisor-eval` runs (13 advisors), and the `go-to-market` run on the old text was stopped and re-queued.
- **Post-closure repair (user, 2026-10-10, "napraw i powtórz oceny"):** the `rethink` on `/product` S12 had two causes found in the raw actor transcripts. (1) Skill: turn 1 wrote the map snapshot to `journey.md` and replied with only the stage footer; step 8 now says the snapshot never replaces the reply. (2) Harness: `run.py` kept only the text after the last tool call (`claude -p` `result`), so text before a file write never reached the persona or the judge; about 12% of actor turns across all runs (128 of 1052, both arms) lost text. `run.py` now streams actor turns and joins every text block. Re-runs on the fixed harness: `/product` S12 `pass` (N Σ17 ff0, K Σ13; N showed the map, warned about building before validation and ads before measurement, one next step), `product-spec` S13 `pass` (N Σ17 ff0, K Σ14). Earlier `pass` rows stand (the loss could only lower scores). Every product skill now has a current `pass` row; `check.sh` 204/0/0.
- **Deferred ideas:** the judge sometimes returns malformed JSON (2 of 15 runs today); `run.py` stops and the run is repeated by hand

---

## Interaction Card
- **Checkpoint:** final review
- **Progress:** krok 4 z 4; PR 8 gotowy do Twojego przeglądu
- **Completed:** katalog `.apm/README.md`, README/AGENTS/baseline AGENTS/tests GUIDE, atrybucja w skillach, poprawka odczytu danych w product-metrics, oceny 13 advisorów
- **Evidence:** check 204/0/0, smoke 249/0, pack 205/0/0 (apm 0.33.0); 13 × `pass` (po naprawie harnessu i `/product`); niezależny przegląd `APPROVED`
- **Review focus:** `.apm/README.md` „Pick by situation” i „Product skills in detail”; dwa `rethink` (`/product` S12: sesja 1 nie pokazała mapy; `product-spec` S13: test odnowień bez progu i kill criterion)
- **Question:** czy PR 8 jest OK, i czy zawężamy `/product` / `product-spec` teraz, czy po merge?
- **Options:** continue | direct a correction | show details

---

### Task 8.1: `.apm/README.md` catalog

**Task status:** done — `.apm/README.md` rewritten as the delivered catalog (19-row table, 14 detailed product skills, `/ship` boundary table, paths, ADRs, attribution); `scripts/check.sh --skills` 81/0/1 (staleness WARN only, runs in progress); each row cross-read against its SKILL.md

**Execution Profile:**
- **Bottleneck:** retrieval
- **Bottleneck rationale:** describes skills that already exist; the risk is overclaiming
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

**Task status:** done — docs: `README.md` (19-skill table + catalog link; "five skills" → 19; the stale capability/effort paragraph now describes the D15 Execution Profile), `AGENTS.md` (19 skills, catalog, `SOURCES.md` source-repo only, `advisor-eval` by path + re-run rule), baseline `AGENTS.md` ("Workflows available here", advisors included), `tests/GUIDE.md` (Advisor evaluation), and one line in root `GUIDE.md` ("five skills" → 19, same stale-count risk). With apm 0.33.0: `check.sh` 203/0/1, `smoke.sh` 249/0, `check.sh --pack` 204/0/1; the one WARN is staleness while the `advisor-eval` runs finish; stale-count grep empty

**Execution Profile:**
- **Bottleneck:** retrieval
- **Bottleneck rationale:** small factual edits in known places
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

---

> **Post-closure changes (PR #4 review, 2026-10-11/12):** shared advisor contract v2, all product skills rewritten in Prompt Architect shape, `/ux-review` walking the running app, and one copy of the skills (D21–D23 in the manifest). All 14 advisors were re-run through `advisor-eval` on v2; the ledger `tests/fixtures/advisors/SCORECARDS.md` holds the rows. Harness fixes made on the way: whole actor turn captured, judge JSON recovery, web tools approved for the actor.
