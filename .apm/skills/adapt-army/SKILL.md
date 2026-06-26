---
name: adapt-army
description: Propagate a NEW durable guideline or an architectural correction into the whole agent team, consistently. Use when the user states a repo-wide convention ("from now on always X", "we never do Y"), corrects an architectural behavior that should hold beyond this one task, or changes project policy. Routes the guideline to EVERY agent that owns it (not just one), updates AGENTS.md as the source of truth, and keeps the team internally consistent. NOT for one-off task tweaks.
---
# /adapt-army — team-level course correction

A repo's conventions evolve. When a new law emerges mid-work, editing one agent leaves the rest
contradicting it. This skill keeps the **whole army** in lockstep with the new guideline. It is the
`architect`'s Course-Correction role (Rule 9) raised to the level of the team itself.

## Step 1 · Capture & qualify the guideline
Restate the guideline in one crisp sentence and confirm it is **durable and repo-wide**, not a one-off.
- **Durable & repo-wide** ("we always use the Facade", "no custom CSS — PrimeFlex only", "switch test policy to pragmatic") → continue.
- **One-off / task-local** ("for this PR skip the integration test", "name THIS variable x") → **STOP**. Do not touch the army; apply it to the current task only and say so. Polluting agents with task-specifics is the failure mode here.
If unsure which it is, ASK the user: "Should this hold for the whole repo going forward, or just this task?"

## Step 2 · Classify
Put the guideline in a bucket — it decides where it lands:
- **Architectural law** (boundaries, patterns, forbidden moves) → agents' rules/checklists + `AGENTS.md`.
- **Test idiom / strategy** (framework, layer weighting, base classes) → `tester`, `architect`, PR template.
- **Naming / layout convention** → `architect` + `code-reviewer` + `AGENTS.md`.
- **Security / perf rule** → `security-auditor` / `perf-auditor` (+ `code-reviewer` if it's a review gate).
- **Project policy** (test rigor / lint / CI) → `army.conf` knob (`TEST_POLICY`/`LINT_POLICY`/`CI_MODE`), not agent prose. **Security barriers are never a knob.**

## Step 3 · Route — find EVERY owner (the key step)
A guideline usually touches **multiple** agents. Match it against each agent's `description` + current rules and list the full blast radius. Report it before changing anything:
```
Guideline: <one line>
Touches:
  architect      → <plan rule to add/change>           [yes/no]
  tester         → <test idiom to add>                   [yes/no]
  code-reviewer  → <checklist item to add>               [yes/no]
  security/perf  → <sink/check to add>                   [yes/no]
  AGENTS.md      → <law/convention section>              [yes/no]
  templates      → <blueprint/report template change>    [yes/no]
  army.conf      → <policy knob>                          [yes/no]
```
If you can only find one owner, double-check: is there really no reviewer rule that should enforce what the architect now plans? Single-owner guidelines are rare.

## Step 4 · Confirm scope
Show the routing table from Step 3 and get the user's "ok / adjust". Don't silently rewrite half the team.

## Step 5 · Apply (source of truth first, then sync)
1. **`AGENTS.md` is the canonical record** — update its laws/conventions/policy section FIRST. Everything else is derived from it.
2. **Sync each owning agent** to match: bake the law into `architect`'s rules, `code-reviewer`'s checklist, `tester`'s idioms, the auditors' sinks — using the same depth and BAD/GOOD style as `references/agent-worked-examples.md`. Update each agent's `<prompt_examples>` if the change affects what they'd produce.
3. **Templates / `army.conf`** if Step 3 flagged them (e.g. add a section to the PR template; flip `TEST_POLICY`).
4. **Save a `.base`/timestamped backup** of every file before overwriting (reversible).
5. **Cross-agent consistency check** (same as bootstrap Step 4c): the law as `architect` plans it == the law as `code-reviewer` rejects it; commands stay identical across agents + `army.conf`; no two agents now contradict each other.

## Step 6 · Report
List exactly what changed (file → what), confirm the team is consistent, and note anything you deliberately did NOT change. If a policy knob moved, restate the new `army.conf`.

## Rules
- **Never weaken security barriers** — they are not adaptable via this skill.
- **One-off ≠ guideline** — if Step 1 says task-local, do not touch agents.
- **Evidence:** if the guideline references a code pattern, cite the proving path (as the worked examples do).
- **Quality bar:** every edited agent must still pass `_STANDARD.md` and the evidence/internalization gates.

## <prompt_examples>
**EX 1 — architectural law, multi-owner.** USER (mid-task): "From now on no service may call a repository directly — always through a Facade."
→ Qualify: durable, repo-wide. Classify: architectural law. Route → `architect` (plan rule: tasks name the Facade), `code-reviewer` (checklist: reject `*Repository` calls outside a Facade), `tester` (example specs target the Facade), `AGENTS.md` (Laws section). Confirm → apply → backups → consistency check. Report: 4 files updated, team consistent.

**EX 2 — policy knob, not prose.** USER: "We're done prototyping — turn on strict TDD."
→ Classify: project policy. Route → `army.conf` (`TEST_POLICY=strict`) + a one-line note in `AGENTS.md`'s Project-policy block. Do NOT rewrite agent rules (they already honor `TEST_POLICY`). Report the new `army.conf`.

**EX 3 — one-off, correctly refused.** USER: "For this PR, skip the e2e test, just unit-test it."
→ Qualify: task-local. STOP — do not change `tester`/`architect`. Apply only to the current task and say: "Done for this PR; I did not change the team's testing strategy. Say so explicitly if you want this to become the repo default."
