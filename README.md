# Claude Agent Army 🛡️

A universal toolkit you drop into **any repo** that turns Claude Code into a self-checking agent
team: architect, tester, reviewer, security auditor, performance auditor and docs editor — keeping
each other honest — plus deterministic **barriers (hooks)** no agent can bypass.

## Install

Installed via [apm](https://microsoft.github.io/apm/) (Microsoft's cross-tool Agent Package Manager) — one command across Claude / Cursor / OpenCode / Codex / Gemini / Windsurf / Copilot — then `/bootstrap` once per repo to specialize the team.

apm ships only the four **skills** (`bootstrap`, `ship`, `new-agent`, `context-budget`) as live. The baseline agents/hooks/templates ride bundled inside the `bootstrap` skill as raw assets — apm does **not** drop generic agents into your repo. `/bootstrap` materializes them into your tool's directory (not hardcoded to `.claude/`) and specializes them to the codebase.

**1. Install apm** (if you don't have it): `pipx install apm-cli` (or `pip install apm-cli`).

**2. Install the package** into your target repo. apm needs a `--target` when it detects more than one harness:

```bash
cd ~/my-repo
apm install psrebrny/agent-army --target opencode   # or: claude | cursor | codex | gemini | copilot | windsurf
```

If the repo is **private**, set a token first (fine-grained PAT, `Contents: Read`):
```bash
export GITHUB_APM_PAT=github_pat_xxxx
```

**3. Run bootstrap** inside the repo, in your AI tool:
```
/bootstrap
```
> **OpenCode:** if `/bootstrap` isn't a recognised command yet (apm landed the skill in `.agents/skills/` rather than `.opencode/commands/`), invoke it directly — type `@.agents/skills/bootstrap/SKILL.md` in the chat. Bootstrap then places everything in the right dirs so future commands work normally.

Pin a version with `psrebrny/agent-army#<tag-or-commit>`. Package layout: `apm.yml` (manifest) + `.apm/` (the four skills + `.apm/commands/` wrappers; `bootstrap/baseline/` holds the raw agents/hooks/templates — the single source of truth).

### Updating

```bash
apm update                 # pull the latest pinned versions
# then, in the repo, re-run to re-specialize against the current code:
/bootstrap
```
Already-specialized agents are your repo's files — re-running `/bootstrap` refreshes them (it saves the prior version as `<agent>.base.md` first).

### After installing into a repo

```
/bootstrap     # ONCE: deep-scans the repo, asks your project policy (test rigor, lint, CI), AUTHORS the team
/ship "add a /health endpoint with a test"   # then drive tasks through the pipeline
```
On Claude Code you also get `/agents` to inspect the team and active lifecycle hooks. On other tools the hard barrier is git pre-commit + CI. Requirements: `bash`, `python3` (security barriers); Claude Code v2.x for full hook mode.

**Before running `/bootstrap`, read the policy section in [GUIDE.md](GUIDE.md)** — it explains the choices `/bootstrap` will ask you (test rigor, lint, CI) so you're ready.

## What you get
```
.claude/
  settings.json          # hook registration (barriers)
  agents/                # the subagent team
    _STANDARD.md         #  → quality bar for EVERY agent
    architect.md         #  → plan + acceptance criteria (never writes source)
    tester.md            #  → writes and runs tests (strict TDD)
    code-reviewer.md     #  → audits the diff; verdict APPROVED / CHANGES_REQUESTED / …
    security-auditor.md  #  → security audit (read-only)
    perf-auditor.md      #  → performance audit (read-only)
    docs-writer.md       #  → updates documentation
    coder.md             #  → production-code implementer (OPTIONAL, off the default pipeline; for big/parallel tasks)
  hooks/                 # deterministic barriers
    guard.sh             #  PreToolUse  → blocks secrets + dangerous commands
    format.sh            #  PostToolUse → auto-format after every change
    verify.sh            #  lint + tests (auto-detects the stack)
    gate.sh              #  Stop        → won't finish until tests/lint are green
    detect.sh            #  stack detection (npm/pnpm/yarn, pytest/ruff, go, cargo)
    git-pre-commit.sh    #  git barrier: secret scan + lint/tests (installed to .git/hooks)
  skills/                # bootstrap (entry) · ship (orchestrator) · new-agent · context-budget
  templates/             # blueprint + report templates the agents must use
  rules/                 # path-scoped rules (optional)
CLAUDE.md                # project memory (universal template)
.github/workflows/quality.yml  # CI: the same gate (verify.sh) on push/PR
```

## How the agents "keep each other honest"
1. **architect** writes the plan and acceptance criteria — before a line of code.
2. The main session implements the smallest change.
3. **tester** writes and runs tests independently (never weakens assertions).
4. **code-reviewer** audits the diff — on blockers returns `CHANGES_REQUESTED` and the loop goes back to fixes.
5. **security-auditor** hunts for secrets and vulnerabilities (read-only).
6. **docs-writer** updates the documentation.

Above all of it sit the **hooks** — a layer the model cannot talk past:
- **PreToolUse (guard.sh)** — hard-blocks editing `.env`/keys and commands like `rm -rf /`.
- **PostToolUse (format.sh)** — formats code after every change.
- **SubagentStop (verify.sh)** — runs lint+tests after the tester finishes.
- **Stop (gate.sh)** — won't let the turn end until lint/tests are green.

It's a division of labor: **agents = judgment** (LLM, can be wrong), **hooks = law** (scripts, deterministic).

## Universal by design
`detect.sh` recognizes the stack from files (`package.json`, `pyproject.toml`, `go.mod`,
`Cargo.toml`…) and substitutes the right format/lint/test commands. Nothing to configure to make
it work in a new repo. You can override the commands in `CLAUDE.md`.

## Customizing
- Add an agent: a new `.claude/agents/<name>.md` (frontmatter `name/description/tools/model` + prompt), or run `/new-agent` to hold it to `_STANDARD.md`.
- Tighten/loosen a barrier: edit the patterns in `hooks/guard.sh`.
- Add your own gate: register a hook in `settings.json` (events: PreToolUse, PostToolUse, SubagentStop, Stop, UserPromptSubmit, SessionStart…).
- Token/context discipline: `.claude/skills/context-budget/SKILL.md` (cheapest adequate model, plan first, short sessions).

## Two layers: distribution vs intelligence
`apm install` is **deterministic** — it deploys the four skills 1:1, generates nothing (zero LLM, zero tokens). The baseline agents/hooks/templates ride bundled as raw assets, NOT as live generic agents.

Tailoring to the repo is done by **`/bootstrap`** — a skill run inside your AI tool that:
1. **deep-scans the repo** (every nested `AGENTS.md` + manifest, real source, test/lint commands),
2. **reasons + asks a few smart questions** (only the gaps recon didn't cover),
3. **authors agents tailored to this repo** (the repo's actual architectural laws, exact commands, test idioms) + a canonical `AGENTS.md` + a `design-docs/` skeleton, then **self-critiques and revises**, and verifies the commands actually run.

So: **apm = mechanical distribution**, **/bootstrap = intelligent runtime authoring**. Run `/bootstrap` once, right after install.

## Hardening
- **Stop without an infinite loop** — `gate.sh` respects `stop_hook_active`: after a forced fix it lets the model finish instead of blocking in circles.
- **Fail-closed without python3** — when `python3` is missing, `guard.sh` still blocks the worst patterns (`rm -rf /`, `curl | sh`, editing secrets) with a coarse bash fallback.
- **Git barrier (pre-commit)** — the installer adds `.git/hooks/pre-commit`: blocks committing secrets and won't let red tests through (works even when someone bypasses Claude Code).
- **CI** — `.github/workflows/quality.yml` runs the same `verify.sh` on push/PR (add setup-node/setup-python for your stack).
- **perf-auditor** — a sixth agent: performance audit (measure first, then hotspots).

## Security
The barriers are an extra layer, not a guarantee. Keep `.claude/settings.local.json` out of git
(the installer adds an entry to `.gitignore`). Review diffs before committing — human approval is
written into the CLAUDE.md rules.
