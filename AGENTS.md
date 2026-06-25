# AGENTS.md — Agent Army source repo

> Universal entry point readable by Claude Code, Cursor, GitHub Copilot, Codex, Gemini, and
> other agentic tools. **This is the SOURCE repo** — you're working on the toolkit itself,
> not a repo where it's already installed.

## What this repo is

**Claude Agent Army** is a deployable toolkit that injects a self-checking agent team +
deterministic hook barriers into any target repo. This repo is the *source*. It ships **two
independent install paths** (keep them separate — neither edits the other):
- **bash** — `install.sh` copies `template/` into a target repo. Pure bash, no LLM calls.
- **apm** — `apm.yml` + `.apm/` make it installable via Microsoft's Agent Package Manager. apm
  deploys only the four skills; the baseline agents/hooks/templates ride bundled in
  `.apm/skills/bootstrap/baseline/` and are materialized + specialized by `/bootstrap`.

No build step, no test suite.

## Key files

- `install.sh` — the installer. Copies `template/` to a target repo. Pure bash, no LLM calls.
- `template/` — everything that gets installed:
  - `agents/agents/` — seven subagent definition files + `_STANDARD.md` quality bar (→ `.claude/agents/`): `architect`, `tester`, `code-reviewer`, `security-auditor`, `perf-auditor`, `docs-writer`, `coder` (optional)
  - `agents/hooks/` — lifecycle hook scripts (→ `.claude/hooks/`)
  - `agents/skills/` — `/bootstrap`, `/ship`, `/new-agent`, `context-budget` (→ `.claude/skills/`)
  - `agents/templates/` — report + blueprint templates (→ `.claude/templates/`)
  - `AGENTS.md` — cross-tool entry point template (installed into target repos)
  - `CLAUDE.md` — Claude Code memory template (installed into target repos, filled by `/bootstrap`)
  - `agents/settings.json` — hook wiring for Claude Code (→ `.claude/settings.json`)
  - `.github/workflows/quality.yml` — CI that re-runs `verify.sh`

## Agent architecture

**LLM layer (judgment, can be wrong):**
- `architect` — writes blueprints in `design-docs/`, never writes source code
- `tester` — strict TDD executor: writes RED tests from contract, verifies GREEN
- `code-reviewer` — architectural auditor; verdict: `APPROVED` / `CHANGES_REQUESTED` / `ARCHITECTURAL_ALIGNMENT_NEEDED`
- `security-auditor` — read-only, secrets + injection scan
- `perf-auditor` — read-only, measure-first performance audit
- `docs-writer` — minimal documentation updates
- `coder` — optional; production-code implementer for large/parallel tasks (off the default `/ship` pipeline)

**Hook layer (deterministic, cannot be bypassed):**
- `guard.sh` (PreToolUse) — blocks secret file edits and dangerous commands
- `format.sh` (PostToolUse) — auto-formats after every file change
- `verify.sh` (SubagentStop on `tester`) — runs lint + tests after tester finishes
- `gate.sh` (Stop) — blocks session end until lint/tests are green
- `detect.sh` — auto-detects stack from `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`
- `git-pre-commit.sh` — installed to `.git/hooks/pre-commit`; tool-independent barrier

## Working in this repo

No build step, no test suite. Changes are in `template/` (what gets installed) and `install.sh` (the installer). Test by running `install.sh` against a scratch repo and verifying the output.

```bash
# Test the installer locally:
mkdir /tmp/test-repo && git init /tmp/test-repo
./install.sh --tool claude /tmp/test-repo
ls /tmp/test-repo/.claude/
```

## Agent quality bar

Every agent must conform to `template/agents/agents/_STANDARD.md`. Required sections:
frontmatter with justified `model` choice, Role & Purpose, Principles (BAD/GOOD contrasts),
Scope, Workflow, Output, Edge cases, ≥2 concrete `<prompt_examples>` with real paths.

Model tiers: `opus` = hard reasoning/planning; `sonnet` = review/test; `haiku` = cheap/high-volume.

## Hard rules

- Never commit without human approval.
- Never weaken or skip tests/hooks to make something pass.
- Never paste secrets into code or prompts.
- When unsure: ask, don't guess.
- `detect.sh` auto-detects stack — don't hardcode commands in hooks.
