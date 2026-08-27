# AGENTS.md — Agent Army source repo

> Universal entry point readable by Claude Code, Cursor, GitHub Copilot, Codex, Gemini, and
> other agentic tools. **This is the SOURCE repo** — you're working on the toolkit itself,
> not a repo where it's already installed.

## What this repo is

**Agent Army** is a deployable toolkit that creates a tailored agent team in a target repo. This
repo is the source, distributed as an **apm package**. `apm install` deploys only skills and
templates; `/bootstrap` creates local APM sources and has the user choose whether runtime hooks,
git pre-commit and CI are owned by Agent Army, external, or disabled.

No build step, no test suite, no installer script — apm is the install mechanism.

## Key files

- `apm.yml` — apm manifest (name, version, `includes`, deps).
- `.apm/skills/` — the four live skills apm deploys: `/bootstrap`, `/ship`, `/new-agent`, `/adapt-army`.
- `.apm/commands/` — thin command wrappers for tools that surface a `command/` dir rather than `skills/`; each just points at the matching `.agents/skills/<skill>/SKILL.md`. (apm's own placement varies by tool/version; when a native command isn't registered, invoke the skill directly by its `.agents/skills/…/SKILL.md` path.)
- `.apm/skills/bootstrap/bootstrap.py` — deterministic v0.3.0 generator/migrator: `python3 bootstrap.py <tool> [--mode auto|incremental|full] [--runtime-hooks …] [--git-precommit …] [--ci …]`. It creates local `.apm/agents`, optional `.apm/hooks`, `.agent-army/runtime.py`, versioned ownership/config state, then invokes APM for native rendering. `assemble.sh` is a no-APM compatibility wrapper.
- `.apm/skills/bootstrap/baseline/` — **the single source of truth** for everything `/bootstrap` installs:
  - `core/agents/` — seven source agent definitions + `_STANDARD.md`; APM converts the generated local `.apm/agents/*.agent.md` to each native format, including Codex TOML.
  - `runtime.py` — the only barrier runtime. It accepts structured `{cwd, argv}` commands and never sources or evaluates project configuration.
  - `tools/` and legacy hook wrappers remain migration references; profile schema v2 does not materialize them as active controls.
  - `AGENTS.md` — canonical cross-tool entry point (written into target repos). `CLAUDE.md` is NOT here — `/bootstrap` writes a thin Claude-only pointer to AGENTS.md.
  - `.github/workflows/quality.yml` — owned CI template which runs `runtime.py verify` and fails if no quality command exists.

## Agent architecture

**LLM layer (judgment, can be wrong):**
- `architect` — writes blueprints in `design-docs/`, never writes source code
- `tester` — strict TDD executor: writes RED tests from contract, verifies GREEN
- `code-reviewer` — architectural auditor; verdict: `APPROVED` / `CHANGES_REQUESTED` / `ARCHITECTURAL_ALIGNMENT_NEEDED`
- `security-auditor` — read-only, secrets + injection scan
- `perf-auditor` — read-only, measure-first performance audit
- `docs-writer` — minimal documentation updates
- `coder` — optional; production-code implementer for large/parallel tasks (off the default `/ship` pipeline)

**Control layer:** runtime hooks offer deterministic feedback; selected pre-commit and CI provide
the repository controls. Each layer can be Agent Army-owned, external, disabled or blocked; no
runtime hook is described as impossible to bypass.

## Working in this repo

No build step. All changes go in `.apm/` (the single source of truth).

**Local "unit" checks (deterministic, zero-LLM) — `scripts/check.sh`.** Validate one piece or everything; it checks frontmatter, `_STANDARD.md` sections, cross-tool safety (a string `tools:` is a hard FAIL when `--target-dir` names a tool whose descriptor says `accepts_tools_field: false`, a WARN otherwise), ≥2 prompt examples, that each agent's Output section embeds a fenced skeleton, and that every `tools/*.yml` descriptor parses with its required keys:
```bash
scripts/check.sh architect        # one agent (piece by piece)
scripts/check.sh tester reviewer  # a few
scripts/check.sh --skills         # the skills + tools/*.yml descriptor schema-lint
scripts/check.sh                  # everything (agents + skills)
scripts/check.sh --pack           # also `apm pack` if apm is installed
scripts/check.sh --target-dir <dir>   # validate a MATERIALIZED tool dir (e.g. after assemble.sh) —
                                       # descriptor-driven: correct agents dir, exact hooks_live set,
                                       # settings.json iff claude-settings, per that tool's tools/<tool>.yml
```
**Generator preview — `python3 .apm/skills/bootstrap/bootstrap.py codex --mode auto --dry-run`** prints what the v0.3.0 profile would create or migrate.

**Smoke test — `scripts/smoke.sh`.** Deterministic gates cover all target profiles, external-control preservation, unsafe hook collision handling, shell secret writes, staged secret content, failing structured commands, and a real frozen APM render for each target. See `tests/GUIDE.md` for the full testing guide.

**End-to-end (the real apm path):**
```bash
apm install psrebrny/agent-army --dry-run --target opencode   # preview placement, no writes
# or install into a scratch repo and run /bootstrap to see the specialized output:
mkdir /tmp/test-repo && git init -q /tmp/test-repo && cd /tmp/test-repo
apm install psrebrny/agent-army --target opencode
```

## Agent quality bar

Every agent must conform to `.apm/skills/bootstrap/baseline/core/agents/_STANDARD.md`. Required sections:
frontmatter with justified `model` choice, Role & Purpose, Principles (BAD/GOOD contrasts),
Scope, Workflow, Output, Edge cases, ≥2 concrete `<prompt_examples>` with real paths.

Model tiers: `opus` = hard reasoning/planning; `sonnet` = review/test; `haiku` = cheap/high-volume.

## Hard rules

- Never commit without human approval.
- Never weaken or skip tests/hooks to make something pass.
- Never paste secrets into code or prompts.
- When unsure: ask, don't guess.
- Keep quality commands as `{cwd, argv}` in `.agent-army/config.json`; never use shell configuration or evaluated command strings.
