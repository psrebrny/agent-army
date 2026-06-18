# CLAUDE.md — project memory

> Fill in the [bracketed] sections. Keep this file < 200 lines (it loads on EVERY message).
> Move detail into `.claude/skills/` (load on demand) and `.claude/rules/`.

## Project
[One-sentence description. Stack/language: … . Key directories: … .]

## Run / test / lint
[Build/test/lint commands. If left empty — the hooks auto-detect them:
npm/pnpm/yarn · pytest/ruff · go · cargo.]

## Conventions
- [Style, naming, architectural patterns. What to avoid.]
- Small, atomic changes. Plan first, then code.
- Commits in Conventional Commits format.
- SDD: the plan lives as files in `design-docs/[Task-ID]/`, not just in chat.
- Tests: Testing Trophy (E2E/integration > unit), behavior not implementation.
- Strict TDD: Red → Green for every task (auto-critic lock).

## Entry point, orchestrator and team
**Entry point → `/bootstrap`** (run ONCE, after install): reads the repo (code analysis), asks questions, reviews the templates, and **creates/specializes the whole team for this repo** per `.claude/agents/_STANDARD.md`. Greenfield → interview + bootstrap of the foundations.

**Orchestrator → the main session driven by `/ship`**: it talks to you, delegates to subagents, enforces the mode (Autonomous/Supervised) and does NOT bypass the hooks. (A subagent can't run an interactive interview, so the entry point and orchestrator are main-session skills, not subagents.)

**Team (`.claude/agents`)** — delegate by the `description` field; quality is held by `_STANDARD.md`:
- `architect` — interview (greenfield/existing) + blueprint in `design-docs/` (does not code)
- `tester` — independent TDD executor: writes RED tests from the contract, verifies GREEN
- `code-reviewer` — Architectural Auditor: audits the diff vs blueprint+business, report in `design-docs/reviews/`
- `security-auditor` — security audit (read-only)
- `perf-auditor` — performance audit, "measure first" (read-only)
- `docs-writer` — documentation updates

**Adding more agents → `/new-agent`** (always to `_STANDARD.md`).
**Token/context discipline → `.claude/skills/context-budget/SKILL.md`** (cheapest adequate model, plan first, pointers not payloads, short sessions).

## Barriers (hooks — run automatically, deterministically)
- **PreToolUse** → blocks editing secrets (`.env`, keys) and dangerous bash commands.
- **PostToolUse** → auto-format after every file change.
- **SubagentStop** → lint + tests after `tester`/`code-reviewer` work.
- **Stop** → quality gate: I don't finish until lint/tests are green.
Do not bypass the barriers. If something blocks you rightly — fix the cause.

## Hard rules
- Do NOT commit without human approval.
- Do NOT disable or weaken tests/hooks to "pass".
- Do NOT paste secrets into code or prompts.
- Uncertain → ask, don't guess.
