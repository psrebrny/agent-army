# Claude Agent Army 🛡️

A universal toolkit you drop into **any repo** that turns Claude Code into a self-checking agent
team: architect, tester, reviewer, security auditor, performance auditor and docs editor — keeping
each other honest — plus deterministic **barriers (hooks)** no agent can bypass.

## Install

Two phases: **install once** globally, then **use from any repo**.

### Phase 1 — install `army` globally (one time)

**Private repo — use `gh` CLI (recommended while repo is private):**
```bash
gh release download --repo pawel-srebrny/agent-army --pattern "*.tar.gz" --dir /tmp/army && \
  tar xzf /tmp/army/*.tar.gz -C /tmp/army && \
  /tmp/army/agent-army/install.sh --global
```

**Public repo — one-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/pawel-srebrny/agent-army/main/.github/scripts/install-latest.sh | bash -s -- --global
```

**Or clone + install (always works):**
```bash
git clone https://github.com/pawel-srebrny/agent-army
agent-army/install.sh --global
```

This adds the `army` command to `~/.local/bin/` and stores the toolkit in `~/.local/share/agent-army/`.
Add `~/.local/bin` to your PATH if it isn't there already (the installer will tell you if it's missing).

### Phase 2 — use from any repo

```bash
cd ~/my-project    # go to any git repo
army               # install into current directory, defaults to --tool claude
```

**All options:**

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--tool` | `claude` `cursor` `copilot` `codex` `opencode` `gemini` `auto` `other` | `claude` | Which AI tool you use in this repo |
| `--no-ci` | — | off | Skip adding Agent Army's CI workflow (`quality.yml`) |

```bash
army                          # Claude Code, with CI
army --tool cursor            # Cursor IDE (hooks inert; barrier = git pre-commit + CI)
army --tool claude --no-ci    # Claude Code, skip adding CI (repo already has its own)
army --tool auto              # unknown/mixed — bootstrap will confirm the tool later
```

**Tool modes:**
- `claude` — full hook mode: lifecycle barriers (`guard`, `format`, `verify`, `gate`) + slash commands
- `cursor` / `copilot` / `codex` / `opencode` / `gemini` — hooks inert; hard barrier = git pre-commit + CI; entry point = `AGENTS.md`
- `auto` — Claude hooks active; bootstrap confirms the actual tool on first run
- `other` — hooks inert; barrier = git pre-commit + CI

### Manual / pinned version

```bash
# Specific release:
VERSION=v0.2.0
curl -fsSL https://github.com/pawel-srebrny/agent-army/releases/download/$VERSION/agent-army-$VERSION.tar.gz | tar xz
cd agent-army && ./install.sh --global
```

### Updating to a new version

The `--global` install just overwrites `~/.local/share/agent-army/` — run the same command again:

```bash
# Update via one-liner (always fetches latest release):
curl -fsSL https://raw.githubusercontent.com/pawel-srebrny/agent-army/main/.github/scripts/install-latest.sh | bash -s -- --global

# Or update via git clone:
git -C agent-army pull && agent-army/install.sh --global
```

This updates the `army` command itself. **Already-installed repos are not affected** — their `.claude/`
directories are independent copies. To update an existing repo, re-run `army` inside it:

```bash
cd ~/my-project
army --tool claude    # overwrites .claude/ with the new version; preserves CLAUDE.md/AGENTS.md
```

### After installing into a repo

```bash
claude
/bootstrap         # ONCE: reads the repo, asks your project policy (test rigor, lint, CI), tailors the agents
/agents            # see the team
/ship "add a /health endpoint with a test"
```
Requirements: Claude Code v2.x, `bash`, `python3` (security barriers). On Windows: WSL or Git Bash.

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

## Two layers: copying vs intelligence
`install.sh` is **deterministic** — it copies finished files 1:1, generates nothing (zero LLM, zero tokens). That gives reproducibility.

Tailoring to the repo is done by **`/bootstrap`** — a skill run inside a Claude Code session that:
1. **reads the repo** (stack, standards, conventions, real test/lint commands),
2. **asks a few smart questions** (only the gaps recon didn't cover),
3. **generates agents tailored to this repo** (exact commands, test framework, conventions) + `CLAUDE.md`/`AGENTS.md` + a `design-docs/` skeleton, and verifies the commands actually run.

So: **install = mechanical baseline**, **/bootstrap = intelligent runtime tailoring**. Run `/bootstrap` once, right after install.

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
