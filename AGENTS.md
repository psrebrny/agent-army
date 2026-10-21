# AGENTS.md — Agent Army source repo

> Universal entry point readable by Claude Code, Cursor, GitHub Copilot, Codex, Gemini, and
> other agentic tools. **This is the SOURCE repo** — you're working on the toolkit itself,
> not a repo where it's already installed.

## What this repo is

**Agent Army** is a deployable toolkit that creates a tailored agent team in a target repo. This
repo is the source, distributed as an **apm package**. `apm install` deploys only skills and
templates (globally with `-g`, or per repo); `/bootstrap` writes one tool-neutral profile into the target
repo's `.agent-army/` and has the user choose where it lives in git and whether runtime hooks, git
pre-commit and CI are owned by Agent Army, external, or disabled. Skills find that profile from the git
root they are invoked in; there are no native agent copies.

No build step, no test suite, no installer script — apm is the install mechanism.

## Key files

- `apm.yml` — apm manifest (name, version, `includes`, deps).
- `.apm/skills/` — the 19 skills apm deploys (registry: `SKILLS` in `bootstrap.py`; `check.sh` keeps it equal to the skill dirs and wrappers):
  - five engineering workflows: `/bootstrap`, `/ship`, `/new-agent`, `/new-skill`, `/adapt-army`;
  - fourteen product skills: the `/product` navigator and thirteen advisors (`product-strategy`, `product-red-team`, `market-research`, `business-case`, `validate-product`, `product-spec`, `solution-architecture`, `delivery-plan`, `go-to-market`, `product-metrics`, `ux-review`, `legal-review`, `launch-readiness`). Each points at one shared contract, `.apm/skills/product/advisor-contract.md` (`advisor-contract:v2`; it lives inside the `/product` skill folder because APM installs only skill folders), and names its own stage; the full stage map lives in `product/SKILL.md`. A semantic change to the contract bumps the tag. Skills follow the Prompt Architect shape: purpose, `<objective>`, at most 12 `<rules>` (conditional where judgment is needed), `<output_format>`, optional `<escalation>`, `<examples>`; `check.sh` enforces the pointer, stage, objective and rule cap.
- `.apm/README.md` — the user-facing catalog: stage model, record stores, every skill, the `/ship` boundary table, ADRs.
- `.apm/SOURCES.md` — attribution for borrowed methods (repo · file · commit · license). Source repo only: APM installs just the skill folders, so each skill also names its source and license inline.
- `.apm/commands/` — thin command wrappers for tools that surface a `command/` dir rather than `skills/`; each just points at the matching `.agents/skills/<skill>/SKILL.md`. Claude does not use them: there the skills are native in `.claude/skills`. The skills may be installed globally or per repo; `/bootstrap` never copies them. (apm's own placement varies by tool/version; when a native command isn't registered, invoke the skill directly by its `.agents/skills/…/SKILL.md` path.)
- `.apm/skills/bootstrap/bootstrap.py` — deterministic 0.6.1 generator/migrator (profile schema v3, no target): `python3 bootstrap.py [--visibility committed|gitignore|exclude] [--mode auto|incremental|full] [--runtime-hooks …] [--git-precommit …] [--ci …] [--tool <tool>]`. It creates `.agent-army/agents/*.agent` role contracts (the only copy), `.agent-army/config.json` with per-tool `model_routing.tools`, optional `.agent-army/runtime.py` and `.apm/hooks` (rendered through APM only with `--tool`). Migrating a 0.3/0.4 profile removes the native role copies those versions rendered when identical to the contract. `assemble.sh` is a no-APM compatibility wrapper.
- `.apm/skills/ship/` — `SKILL.md` (orchestration every run needs), `references/routing.md` and `references/legacy.md` (read on demand), `scripts/removals.py` (the removal list for audit packets).
- `.apm/skills/bootstrap/army.py` — read-only resolver every skill can call relative to itself (`../bootstrap/army.py`): `locate` prints the repo root, profile (`specialized`/`baseline`), dispatch mode and per-role contract + model for a tool; `role <name>` prints a contract. Shared constants live in `armylib.py`.
- `.apm/skills/bootstrap/baseline/` — **the single source of truth** for everything `/bootstrap` installs:
  - `core/agents/` — nine source role definitions + `_STANDARD.md`; bootstrap materializes them as `.agent-army/agents/*.agent`, and skills use them directly as baseline roles in a repo without a profile.
  - `runtime.py` — the only barrier runtime. It accepts structured `{cwd, argv}` commands and never sources or evaluates project configuration.
  - `tools/` — per-tool descriptors; `capabilities.dispatch` (`subagent-with-prompt` | `main-thread`) tells skills how to run a role in that tool. Legacy hook wrappers remain migration references.
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
**Advisor evaluation — `.claude/skills/advisor-eval/SKILL.md`** (maintainer tool, never shipped). It runs one product skill (arm N) against a plain session (arm K) through the scenario fixtures in `tests/fixtures/advisors/`, with a simulated user and a blind judge, and appends one row to `tests/fixtures/advisors/SCORECARDS.md`. Claude Code calls it as `/advisor-eval <advisor> --scenario <id>`; any other tool follows that `SKILL.md` by path and runs `python3 .claude/skills/advisor-eval/run.py <advisor> --scenario <id>` (first with `--plan-only`; it needs the `claude` CLI). **Rule: any change to a product skill → re-run `advisor-eval` for that advisor; any change to the shared `product/advisor-contract.md` → re-run it for all fourteen**; `check.sh` warns while a skill's fingerprint (its `SKILL.md` plus the shared contract) or the contract tag differs from its latest row. See `tests/GUIDE.md` for the protocol.

**Releasing a new version:** bump `PACKAGE_VERSION` in `armylib.py` and `version` in `apm.yml` together; `scripts/smoke.sh` migrates a real profile made by the previous release's generator (extracted from its commit). When to bump: see "Changing a contract" rule 1.

**Generator preview — `python3 .apm/skills/bootstrap/bootstrap.py --mode auto --dry-run`** prints what the profile would create or migrate.

**Smoke test — `scripts/smoke.sh`.** Deterministic gates cover the target-free profile, `army.py locate` (subdirectory, baseline fallback, per-tool dispatch/models, user overrides), visibility, per-tool model routing, incremental and real 0.4.0 → 0.5.0 migration (native copies removed only when identical), external-control preservation, unsafe hook collisions, runtime secret/command safety, and a real APM hook render. See `tests/GUIDE.md` for the full testing guide.

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

## Changing a contract

A contract is any shipped file under `.apm/skills/` that tells an agent what to do: a role in
`baseline/core/agents/`, a skill's `SKILL.md`, the baseline `AGENTS.md`, a blueprint skeleton. These rules
exist because each was broken once and reached `main` unnoticed.

1. **Every merge that changes shipped content bumps the version.** `bootstrap.py --mode auto` treats a
   profile with the same version as current and migrates nothing, so an unbumped change never reaches an
   installed repo. Bump minor when a blueprint/state shape, status, checkpoint or profile field changes,
   patch otherwise, and update every place that names the version (`armylib.py`, `apm.yml`, `bootstrap.py`
   docstring, bootstrap `SKILL.md` description, this file; `smoke.sh` reads it). `check.sh` fails when
   `.apm/skills` changed since main and the version did not move, or when these places disagree.
2. **One owner per rule.** A rule lives in the contract of the role that performs it; `ship` holds only
   orchestration: who runs, when, which state is written, where it pauses. `ship` points to a role rule
   (`code-reviewer` feature mode) instead of restating it. Before adding a rule, grep whether it already
   exists elsewhere; change that copy instead of adding a second one. A skeleton holds each fact in one field.
3. **Removing or narrowing is a sweep, not an edit.** When a field, status, checkpoint, section or role is
   removed or renamed, or a step becomes conditional (an audit selected by risk), grep `.apm/`, `tests/`
   and `scripts/` for the old name and for wording that assumes the old behavior (`both audits`, `always`,
   the old card name), and fix every hit, including other roles, examples, fixtures and frontmatter
   `description`. Then add the old wording to `RETIRED` in `check.sh` (contract hygiene), which scans every
   shipped Markdown file; only `ship/references/legacy.md` and the architect's "Older blueprint" edge case may
   name it.
4. **Walk the lifecycle before committing a flow change.** A change to statuses, pauses, stage order or
   closure is checked on paper against one scenario: Interactive, one feature of two PRs, a task accepted at
   task review, a small correction of that accepted task, a review finding, PR closure, the final
   whole-feature audit and commit. Each status transition and each pause must happen exactly once, in an order
   every contract agrees on. Name the scenario result in the PR body.
5. **Checks run, or the gap is fixed.** Run `scripts/check.sh` and `scripts/smoke.sh` before every commit.
   `check.sh` must parse with macOS's default bash 3.2: run a Python block through `py_capture`, never as a
   heredoc inside `"$(...)"`. If a check cannot run, fix the runner in the same
   change; never work around it silently, and say in the PR body which checks ran.
6. **Keep `SKILL.md` to what every run needs.** A skill folder is installed whole, so put content needed only
   in some runs (a rare fallback, migration of old formats, long tables) in `references/<topic>.md`, and a
   step a program can do exactly (listing removals, resolving paths) in `scripts/<name>.py` (stdlib only,
   read-only unless the skill says otherwise). `SKILL.md` names each file with the condition for reading or
   running it, e.g. "read `references/legacy.md` when the PR file has an older shape"; `check.sh` fails on an
   unnamed or missing file. A role contract stays one file: a subagent receives only that file's text.
7. **Review the whole diff against the base before merge**, including removed lines (`git diff
   <base>...HEAD`, or `python3 .apm/skills/ship/scripts/removals.py <base>`), against rules 1–6. Report what
   was found and fixed in the PR body.

## Hard rules

- Never commit without human approval.
- Never weaken or skip tests/hooks to make something pass.
- Never paste secrets into code or prompts.
- When unsure: ask, don't guess.
- Keep quality commands as `{cwd, argv}` in `.agent-army/config.json`; never use shell configuration or evaluated command strings.
