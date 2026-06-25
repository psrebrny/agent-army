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
- Tests & rigor: follow the **Project policy** below (default: Testing Trophy + strict TDD Red→Green).

## Project policy (`.claude/army.conf`)
Configurable rigor for THIS repo, read by both the hooks and the agents. Set by `/bootstrap`, editable by hand. **Security barriers (secret/dangerous-command blocking) are NOT part of this — always on.**
- **TEST_POLICY** = `[strict | pragmatic | light | none]` — `strict` = TDD Red→Green + Testing Trophy; `none` = no tests (the `tester`/TDD steps are skipped and the test gate is off).
- **LINT_POLICY** = `[on | off]` — whether the Stop gate blocks on lint errors.
- **CI_MODE** = `[on | off]` — whether this repo uses Agent Army's `quality.yml` or its own CI.

## Entry point, orchestrator and team
**Entry point → `/bootstrap`** (run ONCE, after install): reads the repo (code analysis), asks questions, reviews the templates, and **creates/specializes the whole team for this repo** per `.claude/agents/_STANDARD.md`. Greenfield → interview + bootstrap of the foundations.

**Orchestrator & implementer → the main session driven by `/ship`**: it talks to you, **writes the production code itself** (the `tester` writes the test code, never production), delegates specialist work to subagents, enforces the mode (Autonomous/Supervised) and does NOT bypass the hooks. By default no separate `coder` — the orchestrator codes with warm context (blueprint + RED tests + your conversation); for **large or parallel-PR** tasks delegate production coding to the `coder` subagent (ships, but off the default `/ship` pipeline) to keep the session lean. (A subagent can't run an interactive interview either, so entry point and orchestrator are main-session skills.)

**Team & hard rules → single source of truth in `AGENTS.md`.** Roster (delegate by each agent's `description`, quality held by `_STANDARD.md`): `architect` (plans, never codes) · `tester` (RED→GREEN) · `code-reviewer` · `security-auditor` · `perf-auditor` · `docs-writer`. Add agents → `/new-agent`.
**Token/context discipline → `.claude/skills/context-budget/SKILL.md`** (cheapest adequate model, plan first, pointers not payloads, short sessions).

## Barriers (hooks — run automatically, deterministically)
- **PreToolUse** → blocks editing secrets (`.env`, keys) and dangerous bash commands.
- **PostToolUse** → auto-format after every file change.
- **SubagentStop** → lint + tests after `tester` finishes (the only agent that writes code/tests).
- **Stop** → quality gate: I don't finish until lint/tests are green.
Do not bypass the barriers. If something blocks you rightly — fix the cause.

## Hard rules
- Do NOT commit without human approval.
- Do NOT disable or weaken tests/hooks to "pass".
- Do NOT paste secrets into code or prompts.
- Uncertain → ask, don't guess.
