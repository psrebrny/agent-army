# AGENTS.md — Agent Army source repo

> Universal entry point readable by Claude Code, Cursor, GitHub Copilot, Codex, Gemini, and
> other agentic tools. **This is the SOURCE repo** — you're working on the toolkit itself,
> not a repo where it's already installed.

## What this repo is

**Claude Agent Army** is a deployable toolkit that injects a self-checking agent team +
deterministic hook barriers into any target repo. This repo is the *source*, distributed as an
**apm package** (Microsoft's Agent Package Manager). `apm install` deploys only the four skills;
the baseline agents/hooks ride bundled in `.apm/skills/bootstrap/baseline/` and are
materialized + specialized into the target repo by `/bootstrap`.

No build step, no test suite, no installer script — apm is the install mechanism.

## Key files

- `apm.yml` — apm manifest (name, version, `includes`, deps).
- `.apm/skills/` — the four live skills apm deploys: `/bootstrap`, `/ship`, `/new-agent`, `/adapt-army`.
- `.apm/commands/` — thin command wrappers for tools that surface a `command/` dir rather than `skills/`; each just points at the matching `.agents/skills/<skill>/SKILL.md`. (apm's own placement varies by tool/version; when a native command isn't registered, invoke the skill directly by its `.agents/skills/…/SKILL.md` path.)
- `.apm/skills/bootstrap/assemble.sh` — the **deterministic assembler**: `bash assemble.sh <tool> [--dry-run] [--reconcile]` materializes a tool-native team from `baseline/core/` + `baseline/tools/<tool>.yml`, zero LLM. This is what `/bootstrap` Step 0 calls — it owns 100% of "which files go where per tool"; no packaging branching lives in `SKILL.md` prose anymore.
- `.apm/skills/bootstrap/baseline/` — **the single source of truth** for everything `/bootstrap` installs:
  - `core/agents/` — seven subagent definitions + `_STANDARD.md` quality bar: `architect`, `tester`, `code-reviewer`, `security-auditor`, `perf-auditor`, `docs-writer`, `coder` (optional). Tool-agnostic content — no hardcoded `.claude/`, only `<SKILLS_DIR>`/`<AGENTS_DIR>`/`<TOOL_DIR>` placeholders that `assemble.sh` resolves per tool. No `tools:` field either (cross-tool safe — a string `tools` breaks several tools; the assembler adds/keeps it only where `tools/<tool>.yml` says `accepts_tools_field: true`). Each agent embeds its own output skeleton (blueprint / report) inline in its `## Output` section — there is no separate templates dir. `_STANDARD.md` is authoring reference, not a loadable agent — the assembler always lands it OUTSIDE the tool's agent-load dir (at `<TOOL_DIR>/_STANDARD.md`).
  - `tools/<tool>.yml` — one **data** descriptor per tool (dirs, frontmatter rules, capabilities, `hooks_live`); see `tools/README.md` for the schema. `claude.yml`/`opencode.yml`/`cursor.yml`/`gemini.yml`/`copilot.yml` are verified against each tool's current docs; `codex.yml` and `windsurf.yml` stay conservative stubs (Codex's real subagents are TOML, which the assembler can't emit yet; Windsurf has no per-agent file mechanism at all). `_default.yml` is the honest fallback for any unrecognized tool. Adding tool support means adding one file here, not editing prose anywhere.
  - `hooks/` — lifecycle hook scripts. `assemble.sh` copies only the subset each tool's descriptor lists in `hooks_live` — inert ones are never materialized.
  - `AGENTS.md` — canonical cross-tool entry point (written into target repos). `CLAUDE.md` is NOT here — `/bootstrap` writes a thin Claude-only pointer to AGENTS.md.
  - `settings.json` — hook wiring for Claude Code; the assembler writes it only when a tool's descriptor says `hook_mechanism: claude-settings`.
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
**Assembler dry-run (no writes) — `bash .apm/skills/bootstrap/assemble.sh <tool> --dry-run`** prints exactly what a real run would materialize.

**e2e smoke test — `scripts/smoke.sh`.** Two independent gates: **GATE 0** (deterministic, zero-LLM, always runs) exercises `assemble.sh` directly for `claude`+`opencode` in scratch repos — layout, non-clobber on re-run, husky-barrier idempotency, no `.claude/` leakage into non-Claude output. **GATE A/B** (needs the `claude` CLI) drives `/bootstrap` headless against a fixture and asserts the specialized output is repo-tailored. See `tests/GUIDE.md` for the full testing guide.

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
- `detect.sh` auto-detects stack — don't hardcode commands in hooks.
