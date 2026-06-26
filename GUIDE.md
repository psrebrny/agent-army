# Claude Agent Army — guide (finished product)

A self-checking Claude Code agent team for **any repo**: architect (SDD + Testing Trophy + strict
TDD), independent tester, architectural auditor, security, performance and docs — keeping each
other honest, plus deterministic **hooks** (barriers the model can't bypass).

## Requirements
Claude Code v2.x · `bash` · `python3` (barriers; a fallback runs without it). Windows: WSL or Git Bash.

## Project policy — before you start
`/bootstrap` will ask you to set a **policy** for this repo — it's one step, no mystery. The Army adapts to your project's actual stakes. These settings are saved in `.claude/army.conf` (committed; visible in review) and read by both the agents and the gates:

**Testing rigor** — what level of tests does THIS repo need?
- `strict` (default) — full TDD: write RED tests first, verify GREEN. Testing Trophy (E2E/integration > unit). For most real projects.
- `pragmatic` — tests required, but not strict RED-first. Write them, keep them passing. Still Testing Trophy mix.
- `light` — smoke tests / happy-path only. When coverage must be thin.
- `none` — no tests at all. For throwaway / side-project validators, POCs, experiments. The test gate is skipped entirely.

**Lint** — does the gate block on lint errors?
- `on` (default) — yes, linter must pass. For production code.
- `off` — linting still runs (auto-format on save), but the gate won't halt a commit. Use when you have your own, stricter linter elsewhere.

**CI** — does this repo use Agent Army's workflow, or do you bring your own?
- `on` (default) — use `.github/workflows/quality.yml` (the Army's verify.sh).
- `off` — the repo already has its own CI (richer, specialized) — don't install ours; you brought it.

**Examples:**
- A 3-week side-project validator? `TEST_POLICY=none, LINT_POLICY=off, CI_MODE=off` — fast iteration, no ceremony.
- A microservice in a monorepo with its own CI pipeline? `TEST_POLICY=strict, LINT_POLICY=on, CI_MODE=off` — full rigor, but don't overlay our CI.
- A frontend feature in a React app, no existing CI? `TEST_POLICY=pragmatic, LINT_POLICY=on, CI_MODE=on` — reasonable tests, use our basic CI.

**Security barriers are NOT a knob.** Secret files and dangerous commands are blocked at every level — that does not change.

## Install (once per repo)
```bash
cd my-repo
apm install psrebrny/agent-army --target opencode   # or: claude | cursor | codex | gemini | copilot | windsurf
```
apm deploys the four skills only. The baseline agents/hooks/templates/CI ride bundled as raw assets inside the `bootstrap` skill — they become live, repo-tailored files only when you run `/bootstrap` below (it also installs the git pre-commit hook and appends to `.gitignore`).

## STEP 1 — entry point: `/bootstrap`  (run first)
```
cd my-repo   # open it in your AI tool, then:
/bootstrap
```
> OpenCode: if `/bootstrap` isn't recognised yet, invoke it directly with `@.agents/skills/bootstrap/SKILL.md`.
`/bootstrap`:
1. **reads the repo** (stack, standards, conventions, real test/lint commands),
2. **asks a few smart questions** (only the gaps; business, architecture, testing, NFR, process),
3. **creates/specializes the whole team for this repo** (exact commands, test framework, conventions) + a tailored `CLAUDE.md`/`AGENTS.md` + a `design-docs/` skeleton + specialized templates,
4. **verifies** (runs lint+tests once) and reports.
Greenfield (empty repo) → full interview + bootstrap of the foundations. Quality is held by `.claude/agents/_STANDARD.md`.

## STEP 2 — working in the repo: `/ship`  (orchestrator)
```bash
/ship "add a /health endpoint with a test"
```
Pipeline: **Discovery/interview → mode choice → Blueprint (architect, design-docs/) → implementation in strict TDD (tester: RED → code → GREEN) → review (code-reviewer) → security → docs → summary + commit proposal** (commit only with your approval).

At the start `/ship` asks about the **execution mode**:
- **A) Autonomous** — the team does everything on its own; it stops only at hook gates and for commit approval.
- **B) Supervised** — the orchestrator pauses at checkpoints (after the blueprint, after RED tests, after GREEN, before an escalation) and waits for "ok/fix". You can take the wheel and correct the agent.
Switch on the fly: "switch to autonomous/supervised".

## Command cheatsheet
- `/bootstrap` — ONCE: repo analysis + interview + building the team.
- `/ship "<task>"` — take a feature end-to-end with quality control.
- `/new-agent` — add a new agent (always to `_STANDARD.md`).
- `/agents` — list the team.

## What's in the repo after install
```
.claude/
  settings.json                 # hook registration (barriers)
  agents/                       # the team (architect, tester, code-reviewer, security-auditor, perf-auditor, docs-writer; + optional coder)
    _STANDARD.md                # the quality bar for EVERY agent
  hooks/                        # guard / format / verify / gate / detect / git-pre-commit
  skills/                       # bootstrap (entry) · ship (orchestrator) · new-agent · context-budget
  templates/
    blueprint/                  # 00_CORE_MANIFEST + 0X_PR (the architect fills these)
    reports/                    # code-review / security / perf / docs / adr / test-report
CLAUDE.md                       # project memory (tailored to the repo after /bootstrap)
.github/workflows/quality.yml   # CI: the same verify.sh
```

## Barriers (run automatically, independent of the agents' judgment)
- **PreToolUse** → blocks editing secrets and dangerous commands.
- **PostToolUse** → auto-format after a file change.
- **SubagentStop** → lint+tests after the tester.
- **Stop** → won't finish the turn until lint/tests are green (with loop protection).
- **git pre-commit** → secret scan + lint/tests, even when someone bypasses Claude Code.

## Extending
New agent: `/new-agent` (holds `_STANDARD.md`). Per-repo override: drop your own `.claude/agents/<name>.md` — it overrides the general one.

## Troubleshooting
- `claude doctor` — diagnostics (hooks, MCP, shell).
- Hooks don't work on Windows → use WSL/Git Bash.
- No `python3` → the barriers run in fallback mode (blocking the worst patterns).
