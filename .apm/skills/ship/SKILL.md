---
name: ship
description: Full SDD pipeline with the agent team — discovery/interview, blueprint in design-docs/, implementation in strict TDD (Red→Green), architectural audit, security, docs. Run /ship to take a task end-to-end with quality control.
---
# /ship — SDD pipeline + Testing Trophy + strict TDD

> Token discipline for every step lives in `.claude/skills/context-budget/SKILL.md`
> (cheapest adequate model, pointers not payloads, match the fan-out to task size).
> This pipeline honors the repo's **Project policy** (`.claude/army.conf`): at `TEST_POLICY=none`
> skip step 2's tester/TDD loop entirely (implement → security → docs); at `light`/`pragmatic`
> scale the tests down. Security barriers stay on at every level.

## 0 · DISCOVERY & INTERVIEW  → agent `architect` (Phase 0)
Understand the project first. `architect` classifies the repo:
- **GREENFIELD** (no AGENTS.md/CLAUDE.md, little/no code) → interview + **bootstrap** (AGENTS.md/CLAUDE.md, directory structure, test tooling, `design-docs/` skeleton).
- **EXISTING** → recon (scan AGENTS.md/CLAUDE.md, detect stack, mirror patterns) + ask only about gaps.
Group the questions: business (what the project is, users, MVP) · architecture (stack, style, state, data) · testing (Testing Trophy, tools, commands) · NFR · process (Task-ID, commits). **Do not create files** until goal/stack/test strategy/acceptance criteria are clear. "Assume and go" → record ASSUMPTIONS and continue.

### Choose the EXECUTION MODE (ask right after the interview)
Ask the user how execution should run, and record the choice in `00_CORE_MANIFEST.md` (field `Execution Mode`):
- **A) Autonomous** — the team runs the whole pipeline on its own, without interrupting. It stops ONLY at hard gates (hooks) and at the end for commit approval. Fastest, fewest questions.
- **B) Supervised (checkpoints)** — the orchestrator pauses at key points, shows state, and waits for your "ok / fix it":
  1. after the **blueprint** (plan approval),
  2. after the **RED tests** for a task — shows the tests, you review/fix, BEFORE any implementation,
  3. after **GREEN** of each task/PR — you can correct course before the next one,
  4. before an escalation/larger architecture change.
  In this mode the user can take the wheel at any time and correct the agent; the orchestrator returns to the plan after the correction.
  **If a correction is a durable, repo-wide convention** (not a one-off for this task) — "always do X", "we never do Y", "change the test policy" — OFFER to bake it into the whole team via `.claude/skills/adapt-army/SKILL.md` (`/adapt-army`) before resuming. Don't rewrite agents silently; a one-off tweak stays task-local.
Default if unspecified: **B (supervised)** for non-trivial tasks, **A** for small ones. The mode can be changed mid-run with "switch to autonomous/supervised".

## 1 · BLUEPRINT  → `architect` (Phase 2)
Writes `design-docs/[Task-ID]/00_CORE_MANIFEST.md` + `0X_PR_*.md` (1 PR = 1 file). Atomic tasks (Logic + UI/Endpoint + Test), with explicit test paths and API contracts. When there are multiple options — asks which to take.

## 2 · IMPLEMENTATION per task — STRICT TDD `<auto_critic>` with `tester`
_(Applies at `TEST_POLICY=strict`/`pragmatic`. At `light`: thin happy-path tests, no strict RED-first. At `none`: skip this whole step — the main session just implements; lint/security still apply.)_
For EACH task in the blueprint:
1. **`tester` writes the tests (RED)** — independently, from the contract/acceptance criteria (not from the implementation), in Testing-Trophy weighting. Runs them → **MUST FAIL (RED)** for the right reason.
2. **The main session implements** the smallest change that satisfies the task (does not rewrite the tests).
3. **`tester` verifies (GREEN)** — runs again → **MUST PASS**. Still red → diagnose (bug vs test), fix and repeat. Never weaken the assertions.
No batching without verification. *Exception:* for trivial tasks the main session may do the whole Red→Green cycle inline, without a round-trip to the subagent (the cheaper default — see context-budget). Either way the `SubagentStop`/`Stop` hooks enforce green deterministically.
**In Supervised mode:** after RED show the tests and wait for "ok/fix" before implementing; after GREEN stop before the next task. **In Autonomous mode:** keep going without pauses (except the hook gates).

## 3 · REVIEW  → `code-reviewer` (Architectural Auditor)
Audit the finished diff vs blueprint + standards + business goal. Saves a report under `design-docs/[Task-ID]/reviews/`. Verdict:
- `CHANGES_REQUESTED` → produce Micro-Blueprints and return to step 2.
- `ARCHITECTURAL_ALIGNMENT_NEEDED` → back to `architect` (course correction, blueprint update).
- `APPROVED` → continue.

## 4 · SECURITY  → `security-auditor` (read-only)
Remove CRITICAL/HIGH findings. Steps 3 and 4 are read-only analyses of the finished diff — run them in parallel (fan-out).

## 5 · DOCS  → `docs-writer`

## 6 · SUMMARY
Diff, test result, review verdict, security findings. Propose a commit (Conventional Commits). DO NOT commit without my approval.

The hooks (PreToolUse/PostToolUse/SubagentStop/Stop) act independently as a hard, deterministic barrier — regardless of the agents' judgment.
