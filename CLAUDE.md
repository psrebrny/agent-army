# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**Claude Agent Army** is a deployable toolkit that injects a self-checking agent team + deterministic hook barriers into any target repo. This repo itself is the *source* — it contains the `template/` directory and `install.sh` that get copied out. There is no build step, no package manager, no test suite here.

## Key files

- `install.sh` — the installer. Copies `template/` to a target repo. Supports `--tool` flag (`claude|cursor|copilot|codex|opencode|gemini|auto|other`). Pure bash, no LLM calls.
- `template/` — everything that gets installed into a target repo:
  - `.claude/agents/` — six subagent definition files + `_STANDARD.md` quality bar
  - `.claude/hooks/` — bash scripts wired as Claude Code lifecycle hooks
  - `.claude/skills/` — slash-command skills (`/bootstrap`, `/ship`, `/new-agent`)
  - `.claude/templates/` — report and blueprint templates agents must use
  - `CLAUDE.md` — project memory template (filled in by `/bootstrap` in the target repo)
  - `AGENTS.md` — cross-tool entry point (readable by Cursor, Copilot, Codex, etc.)
  - `.claude/settings.json` — hook wiring for Claude Code
  - `.github/workflows/quality.yml` — CI that re-runs `verify.sh`

## Agent architecture

The installed team has two layers:

**LLM layer (judgment, can be wrong):**
- `architect` — writes blueprints in `design-docs/`, never writes source code
- `tester` — strict TDD executor: writes RED tests from contract, verifies GREEN
- `code-reviewer` — architectural auditor; verdict: `APPROVED` / `CHANGES_REQUESTED` / `ARCHITECTURAL_ALIGNMENT_NEEDED`
- `security-auditor` — read-only, secrets + injection scan
- `perf-auditor` — read-only, measure-first performance audit
- `docs-writer` — minimal documentation updates

**Hook layer (deterministic, cannot be bypassed):**
- `guard.sh` (PreToolUse on Bash/Edit/Write/MultiEdit) — blocks secret file edits and dangerous commands
- `format.sh` (PostToolUse on Edit/Write/MultiEdit) — auto-formats after every file change
- `verify.sh` (SubagentStop on `tester`) — runs lint + tests after tester finishes
- `gate.sh` (Stop) — blocks session end until lint/tests are green; respects `stop_hook_active` to avoid infinite loops
- `detect.sh` — sourced by other hooks; auto-detects stack from `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`
- `git-pre-commit.sh` — installed to `.git/hooks/pre-commit`; secret scan + lint/tests, independent of Claude Code

## Running the installer

```bash
# Into current directory
./install.sh .

# Into a specific repo, for a specific tool
./install.sh --tool cursor ~/projects/my-repo

# Available --tool values: claude (default), cursor, copilot, codex, opencode, gemini, auto, other
```

The installer: copies `.claude/`, installs git pre-commit hook, creates/protects `CLAUDE.md` and `AGENTS.md`, adds `.claude/settings.local.json` to `.gitignore`, optionally adds CI workflow (only if `quality.yml` doesn't already exist).

## After installing into a target repo

```bash
cd target-repo
claude
/bootstrap    # ONE-TIME: reads repo, asks gap questions, specializes all agents to this repo
/ship "add /health endpoint with test"   # full pipeline: blueprint → TDD → review → security → docs
/new-agent    # add a new agent to the team
```

## Agent quality bar

Every agent (shipped, bootstrapped, or created by `/new-agent`) must conform to `.claude/agents/_STANDARD.md`. The reference exemplar is `.claude/agents/architect.md`. Required sections: frontmatter with justified `model` choice, Role & Purpose, Principles (with BAD/GOOD contrasts), Scope, Workflow, Output (pointing to a template), Edge cases, and ≥2 concrete `<prompt_examples>` with real paths.

Model tiers: `opus` = hard reasoning/planning; `sonnet` = review/test; `haiku` = cheap/high-volume.

## Hard rules (apply here and in any installed target)

- Never commit without human approval.
- Never weaken or skip tests/hooks to make something pass.
- Never paste secrets into code or prompts.
- When unsure: ask, don't guess.
- `detect.sh` auto-detects stack — don't hardcode commands in hooks; override only in `CLAUDE.md` of the target repo.
