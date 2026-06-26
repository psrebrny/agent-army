# AGENTS.md — Agent Army source repo

> Universal entry point readable by Claude Code, Cursor, GitHub Copilot, Codex, Gemini, and
> other agentic tools. **This is the SOURCE repo** — you're working on the toolkit itself,
> not a repo where it's already installed.

## What this repo is

**Claude Agent Army** is a deployable toolkit that injects a self-checking agent team +
deterministic hook barriers into any target repo. This repo is the *source*, distributed as an
**apm package** (Microsoft's Agent Package Manager). `apm install` deploys only the four skills;
the baseline agents/hooks/templates ride bundled in `.apm/skills/bootstrap/baseline/` and are
materialized + specialized into the target repo by `/bootstrap`.

No build step, no test suite, no installer script — apm is the install mechanism.

## Key files

- `apm.yml` — apm manifest (name, version, `includes`, deps).
- `.apm/skills/` — the four live skills apm deploys: `/bootstrap`, `/ship`, `/new-agent`, `context-budget`.
- `.apm/commands/` — thin command wrappers apm deploys to `.opencode/commands/` etc. (tools that read `commands/`, not `skills/`).
- `.apm/skills/bootstrap/baseline/` — **the single source of truth** for everything `/bootstrap` installs:
  - `agents/` — seven subagent definitions + `_STANDARD.md` quality bar: `architect`, `tester`, `code-reviewer`, `security-auditor`, `perf-auditor`, `docs-writer`, `coder` (optional). No `tools:` field (cross-tool safe — a string `tools` breaks OpenCode; bootstrap re-adds it where the tool accepts it).
  - `hooks/` — lifecycle hook scripts.
  - `templates/` — report + blueprint templates.
  - `AGENTS.md` — canonical cross-tool entry point (written into target repos). `CLAUDE.md` is NOT here — `/bootstrap` writes a thin Claude-only pointer to AGENTS.md.
  - `settings.json` — hook wiring for Claude Code.
  - `.github/workflows/quality.yml` — CI that re-runs `verify.sh`.

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

No build step, no test suite. All changes go in `.apm/` (the single source of truth). Test by installing the package into a scratch repo and running `/bootstrap`:

```bash
# Local dry-run of placement (no writes):
apm install psrebrny/agent-army --dry-run --target opencode
# Or install into a scratch repo and inspect what landed:
mkdir /tmp/test-repo && git init -q /tmp/test-repo && cd /tmp/test-repo
apm install psrebrny/agent-army --target opencode
```

## Agent quality bar

Every agent must conform to `.apm/skills/bootstrap/baseline/agents/_STANDARD.md`. Required sections:
frontmatter with justified `model` choice, Role & Purpose, Principles (BAD/GOOD contrasts),
Scope, Workflow, Output, Edge cases, ≥2 concrete `<prompt_examples>` with real paths.

Model tiers: `opus` = hard reasoning/planning; `sonnet` = review/test; `haiku` = cheap/high-volume.

## Hard rules

- Never commit without human approval.
- Never weaken or skip tests/hooks to make something pass.
- Never paste secrets into code or prompts.
- When unsure: ask, don't guess.
- `detect.sh` auto-detects stack — don't hardcode commands in hooks.
