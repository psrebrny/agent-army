> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #2: Shared advisor contract + discovery advisors
**Objective:** the `advisor-contract:v1` block, an identity check, attribution, and four advisors (`product-strategy`, `product-red-team`, `market-research`, `validate-product`) that pass gate G1.

## Execution State
- **PR status:** ready_for_human_review
- **Interaction policy:** autonomous (user switched from interactive after Task 2.1, 2026-10-09; D18)
- **Execution scope:** PR 2
- **Scope Profile:** one PR; coordinator = highest unfinished task profile (2.1 `design_decision`); coordination `medium`
- **Model routing:** inherit (source repo has no `.agent-army/config.json`); eval actor and judge sessions use the `claude -p` default model, recorded per run
- **Last manual configuration:** stay current (no material model recommendation)
- **Current task:** none (all tasks done; closure complete)
- **Temporary delegation:** none
- **Active roles:** none
- **Last verified stage:** closure (2026-10-09): four advisors + wrappers written as one Autonomous batch (D18); `scripts/check.sh` 166/0; new frontmatter parses as strict YAML (pre-existing `.apm/commands/ship.md` does not: unquoted `: `, out of scope, reported); spot checks: `product-strategy` S1 pass (N Σ18 ff0 vs K Σ10 ff1), `validate-product` S1 pass (N Σ16 ff0 vs K Σ13 ff0; judge: resume re-asked one settled question, next step was a list → fixed in `validate-product` Writes after the run, not re-run, so the row's hash is the pre-fix version); self-review + secrets grep clean; no independent `code-reviewer` run (not requested); `smoke.sh` 119/9 unchanged by this PR (gate 3 needs `apm`, absent here). Before that, 2.1 GREEN: `t21.sh` 9/9; contract 135 lines (reported only, D17); `SOURCES.md` 9 rows read at their commits
- **Awaiting decision:** final review: manual acceptance (run `/product-strategy` on your real idea, resume in a new session)

---

## Execution Progress
- **Milestones:** 1) Task 2.1 contract block + identity check + `SOURCES.md` · 2) Task 2.2 `product-strategy` + `product-red-team` (+ G1 eval) · 3) Task 2.3 `market-research` + `validate-product` (+ G1 eval) · 4) closure: review, security, docs, final verification
- **Current milestone:** 4 of 4 (closure done)
- **Finish condition:** all three tasks verified (check.sh GREEN, G1 scorecard rows with verdicts), review + security clean, PR at `ready_for_human_review`; commit only after approval
- **Last map change:** 2026-10-09: Autonomous mode; 2.2 and 2.3 written as one batch; eval spot check on `product-strategy` + `validate-product` only (D18)
- **Deferred ideas:** none

---

## Interaction Card
- **Checkpoint:** final review
- **Progress:** krok 4 z 4; PR 2 gotowy do Twojego przeglądu
- **Completed:** kontrakt + `SOURCES.md` (2.1); `product-strategy`, `product-red-team`, `market-research`, `validate-product` + wrappery (2.2–2.3)
- **Evidence:** `check.sh` 166/0; spot checki: product-strategy N 18 vs K 10, validate-product N 16 vs K 13, 0 fałszywych faktów w N
- **Review focus:** przetestuj `/product-strategy` na swoim pomyśle i wznów w nowej sesji
- **Question:** czy po teście ręcznym PR 2 jest OK, czy coś poprawić?
- **Options:** continue | direct a correction | show details
- **Discussion:** none

---

### Task 2.1: Contract block, identity check, `SOURCES.md`

**Task status:** done

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** the block is the behavior every product skill shares; it must carry record types, store binding rules, register, output format, ADR template, stage model, work item format and safety rules, and nothing advisor-specific (no line cap, D17)
- **Escalation trigger:** a rule needs advisor-specific wording, or an advisor eval shows high `cost` or weak N − K that traces to the contract

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
Write the contract text from manifest §3 "Data Flow / Strategy" (shared contract + ADR rules + brief schema + output format + record types and their repo default locations + `stores.json` schema and external-store rules (manifest Contract surfaces and Constraints) + stage model table + work item format + the closing line "stage N · full picture: `/product`") between `<!-- advisor-contract:v1 -->` and `<!-- /advisor-contract:v1 -->`. The brief schema has these sections: Product, Audience & initial segment, Problem, Alternatives & advantage, Revenue model, Out of scope, Customer language (real quotes with source, no personal data), Register (`ID | Type | Statement | Source | Evidence level | Status | Date`), Change proposals, Unknowns, Conversation state. Add `check_advisor_contract` to `scripts/check.sh`: every `.apm/skills/*/SKILL.md` that contains the opening tag must contain a byte-identical block, and every existing skill dir named in the product-skill list (the 14 names, kept in one variable) must contain it. Completeness (all 14 present) is asserted by the registry check in PR 7, so `check.sh` stays green between PRs. Create `.apm/SOURCES.md` with one row per borrowed idea (repo, file, commit, license, what was taken), wording it as attribution, not a recommendation.
- **API/Component Contract:** contract block v1; `check.sh` prints `advisor contract identical in N present advisor skills`. The contract includes the `interaction-pace:v1` paragraph (manifest §3, D16) between its own tags; add `check_interaction_pace`, which compares that paragraph in the contract with the copies in `/ship` and the baseline `AGENTS.md` once they exist (Task 6.5).
- **Compatibility:** new surface; the authoritative copy is in `product-strategy`.
- **Refactor checkpoint / recovery:** not applicable
- `SOURCES.md` rows: pm-skills `strategy-red-team`, `pre-mortem`, `identify-assumptions-new`, `brainstorm-experiments-new` (XYZ, after Savoia), `interview-script` (Mom Test, after Fitzpatrick), `product-strategy` (trade-offs/"won't"), `privacy-policy` (section checklist only), all `@8607e3b` MIT; marketingskills `marketing-loops` `@5e721d7` MIT; pratikshadake Ship/Iterate/Kill `@0f81a86` MIT. Check the Torres/Cagan attribution at the source before writing it.

**Delegation Contract:**
- **Goal:** one contract text, checked for identity, with attribution recorded.
- **Inputs / approved read paths:**
  - `scripts/check.sh` — `check_interaction_contract` pattern
  - `00_CORE_MANIFEST.md` §3
- **Approved write scope:**
  - `tester`: `scripts/check.sh`
  - `coder` / main session: `.apm/skills/product-strategy/SKILL.md` (block only), `.apm/SOURCES.md`
- **Forbidden / never-touch zones:** `bootstrap.py`, baseline agents
- **Start gate:** Interactive: RED acceptance card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** an attribution cannot be verified at the source (then drop the attribution or keep the idea unattributed with a reason).

**Verification Command:** `scripts/check.sh --skills`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = silent drift between copies. A deterministic check is the cheapest reliable guard.
- **E2E / INTEGRATION** (`scripts/check.sh`):
  - ✓ identical copies → PASS
  - ✓ a copy with one changed character → FAIL naming the skill
  - ✓ an existing advisor dir without the block → FAIL
  - ✓ the `stores.json` example inside the block parses as JSON and has no `delete` in any `allowed` list
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: new behavior (check) + non-code (contract text).
2. Add the check, then create a second scratch copy with a changed line → run → **RED**.
3. Write the authoritative block; remove the scratch copy.
4. Run `scripts/check.sh --skills` → GREEN; record the output.

**Aligns with:** Contract surfaces; D2; D17

### Task 2.2: `product-strategy` + `product-red-team`

**Task status:** done

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** these are the two core methods; quality depends on how the questioning is structured, not on facts
- **Escalation trigger:** G1 shows false facts or N − K ≤ 2

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
`product-strategy` sets up a critical conversation about audience, problem, advantage, features, monetization and what is out of scope. It compares customer, product, distribution and finance perspectives, names conflicts and proposes the smallest next step. It owns `brief.md`. `product-red-team` takes any artifact (brief, GTM plan, launch plan) through load-bearing claims → steelman → attack → "Fails if …" → rank by impact × likelihood × cheapness to test → for each weakness, a mitigation or the cheapest test plus a kill criterion → what holds → what could not be assessed. It classifies risks as blocks launch / within 30 days / track. It writes `product-red-team.md` and proposes brief changes. Add wrappers `.apm/commands/<name>.md` (copy the `ship.md` shape). Each skill has a description ≤ 300 chars with "Not for …", and ≥ 2 examples (fresh start; resume from files).
- **API/Component Contract:** skill frontmatter `name`, `description`; artifact paths per manifest table
- **Compatibility:** none beyond the contract
- **Refactor checkpoint / recovery:** not applicable
- Name famous founders only as analysis lenses. No invented quotes, no "expert panel".

**Delegation Contract:**
- **Goal:** both skills pass `check.sh` and gate G1 on S1, S3 and S11.
- **Inputs / approved read paths:** manifest §3; `.apm/README.md` draft rows; `.apm/commands/ship.md`
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/{product-strategy,product-red-team}/**`, `.apm/commands/{product-strategy,product-red-team}.md`
- **Forbidden / never-touch zones:** `bootstrap.py` (registry comes in PR 7)
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** a method needs a third-party file copied verbatim (see D2 exception).

**Verification Command:** `scripts/check.sh --skills`; spot check (D18): `advisor-eval product-strategy --scenario S1`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = confident advice built on invented demand. The behavioral gate is the only meaningful level.
- **E2E / INTEGRATION** (`advisor-eval`): ✓ 0 false facts; ✓ resume repeats 0 questions; ✓ N − K > 2
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code (skill prose) with a behavioral gate.
2. The bar is arm K from the same run.
3. Write both skills.
4. Run check + eval; record the scorecard rows; apply the decision rule.

**Aligns with:** D3, D4, constraints on fiction and evidence

### Task 2.3: `market-research` + `validate-product`

**Task status:** done

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** both need strict evidence labelling; validation also needs the difference between a prepared experiment and an executed one
- **Escalation trigger:** a run reports a planned experiment as a result

**Run Configuration:**
- **Role:** main session
- **Recommended:** set at dispatch
- **Configuration source:** unknown
- **Actual / adapter limitation:** set at dispatch
- **User decision:** not needed

**Action:**
`market-research` covers competitors, alternatives, prices, competitor channels and customer opinions of alternatives. Every finding carries a source and check date, at evidence level third-party data. Without web access the result is partial, with a manual-check list. It writes `market-research.md` and adds proposals to the brief. `validate-product` goes hypothesis (XYZ) → participants and recruitment → experiment choice (behavior over opinion, skin in the game; Mom Test for interviews) → materials → success/kill thresholds → measurement → interpretation of supplied real results → Ship/Iterate/Kill. Price tests receive the willingness-to-pay hypothesis from `business-case`; a pre-order at a price is behavior, a survey is stated intent. A post-launch mode, entered when `metrics.md` reads or the user report churn, plans cancellation interviews, synthesises user-supplied anonymised support messages and records retention hypotheses. A prepared experiment is never reported as run. It writes `validation.md`. Code-needing experiments (fake door, landing page) become `fix`-kind work items. Wrappers plus ≥ 2 examples each.
- **API/Component Contract:** as Task 2.2
- **Compatibility:** none
- **Refactor checkpoint / recovery:** not applicable
- Contacting respondents or posting anything needs an explicit user command.

**Delegation Contract:**
- **Goal:** both skills pass `check.sh` and G1 on S1, S9 and S14.
- **Inputs / approved read paths:** manifest §3; Task 2.1 contract
- **Approved write scope:**
  - `tester`: none
  - `coder` / main session: `.apm/skills/{market-research,validate-product}/**`, `.apm/commands/{market-research,validate-product}.md`
- **Forbidden / never-touch zones:** `bootstrap.py`
- **Start gate:** Interactive: card with the write list | Autonomous: in-scope only
- **STOP and return `awaiting_approval` when:** research requires a paid tool or account.

**Verification Command:** `scripts/check.sh --skills`; spot check (D18): `advisor-eval validate-product --scenario S1`

**Testing Strategy & Cases (Testing Trophy):**
- **Risk / level choice:** risk = third-party data presented as proof of demand
- **E2E / INTEGRATION** (`advisor-eval`): ✓ S9 web-off output is labelled partial; ✓ S1 has a threshold and a kill criterion; ✓ S14 makes no claim from too few interviews; ✓ 0 false facts
- **UNIT:** not applicable

**TDD Execution & Auto-Critic:**
1. Task type: non-code with a behavioral gate.
2. The bar is arm K from the same run.
3. Write both skills.
4. Run check + eval; record the rows.

**Aligns with:** evidence levels; D3

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** gate G1 — run `/product-strategy` on your real idea, then resume it in a new session; read the scorecards and the decision-rule verdict before PR 3 starts
