---
name: bootstrap
description: One-time intelligent setup of the agent team for THIS repo, after installing via apm. Materializes the bundled baseline (agents, hooks, templates) into your tool's directory, then GENERATES repo-tailored agents (exact commands, test framework, conventions) plus AGENTS.md/CLAUDE.md and the design-docs skeleton. Run /bootstrap once, right after `apm install agent-army`.
---
# /bootstrap (apm) — materialize + tailor the agent team to THIS repo

> **OpenCode note:** if `/bootstrap` is not yet a recognised command (skills landed in
> `.agents/skills/` instead of `.opencode/commands/`), invoke this skill directly:
> type `@.agents/skills/bootstrap/SKILL.md` in the chat. Bootstrap will then place
> everything in the right directories so future commands work normally.

`apm install` deployed only the SKILLS (this one, plus `ship`, `new-agent`,
`context-budget`). It did **not** drop generic agents/hooks into your repo —
those ride bundled as raw assets in `baseline/` next to this file. Your job: copy
them into the right place for THIS tool, then specialize them to THIS codebase.
You (the lead) do the thinking and write the files — apm did none of it.

## Step 0 · Materialize the baseline into the right directory (tool-aware)
The baseline is NOT hardcoded to `.claude/`. Detect the tool and pick its dir:

| Tool | Agents dir | Skills/commands | Hooks wiring |
|---|---|---|---|
| Claude Code | `.claude/agents/` | `.claude/skills/` (apm already placed these) | `.claude/settings.json` (active) |
| OpenCode | `.opencode/agent/` | `.opencode/command/` | git pre-commit + CI (Claude hooks inert) |
| Cursor / Copilot / Codex / Gemini / Windsurf | per-tool dir | per-tool | git pre-commit + CI (Claude hooks inert) |

- Detect from existing config (`.claude/`, `.opencode/`, `.cursor/` …) or ask the user **once** which tool this repo uses; default to Claude Code if it's the only one present.
- Copy from this skill's `baseline/` into the chosen tool dir:
  - `baseline/agents/` → `<tool>/agents/` (the seven `*.md` + `_STANDARD.md`)
  - `baseline/templates/` → `<tool>/templates/`
  - `baseline/hooks/` → `<tool>/hooks/` and `chmod +x` the `*.sh`
  - `baseline/settings.json` → `.claude/settings.json` **only if** the tool is Claude Code (otherwise hooks are inert; skip).
  - `baseline/army.conf` → `<tool>/army.conf`
- **Git pre-commit (tool-independent hard barrier):** copy `baseline/hooks/git-pre-commit.sh` → `.git/hooks/pre-commit`, `chmod +x`. Skip with a note if there's no `.git`.
- **CI:** if the repo has no existing workflow, offer to add a `quality.yml` that re-runs `verify.sh`; if it already has CI, leave it and set `CI_MODE=off` in `army.conf`.
- Add `.claude/settings.local.json` (and the chosen tool's local-state file) to `.gitignore`.
Report what landed where before moving on.

## Step 1 · Recon (read before you ask)
- **Detect stack & tooling:** read `package.json` / `pyproject.toml` / `build.gradle` / `pom.xml` / `go.mod` / `Cargo.toml`; test & CI configs (jest/vitest/cypress/playwright/pytest…); lint/format config; `.editorconfig`.
- **Read standards if present:** `AGENTS.md`, `CLAUDE.md`, `README`.
- **Infer conventions from REAL code:** directory layout, naming, smart/dumb split, error handling; open 1–2 existing test files and mirror their style.
- **Capture EXACT commands** actually used (build / lint / unit / e2e) and how to run a SINGLE test.
- Exclude `node_modules`, `build`, `dist`.
Summarize findings in a few lines. Never ask about anything recon already answered.

## Step 2 · Smart questions (only the gaps)
Ask a short, grouped, numbered batch — only what recon couldn't settle:
- **Business** — what the project is / who uses it / MVP scope (if README is silent).
- **Architecture intent** — target style, state management, boundaries you must respect, "never touch" zones.
- **Testing** — confirm Testing-Trophy weighting; which layers exist; exact commands if ambiguous.
- **NFR** — performance, security, compliance constraints.
- **Process** — Task-ID format, branch/PR rules, commit convention.
- **Model tiers** — ask: "Which models are available in your tool, and which should map to each tier?" Present the three roles and their default logic, then let the user name concrete models:
  - **Strong tier** (hard reasoning / planning / architectural audit) — default: the strongest available
  - **Mid tier** (review, testing, structured analysis) — default: the balanced option
  - **Light tier** (docs, high-volume, cheap edits) — default: the cheapest adequate model
  Don't suggest specific model names or versions — they change and vary by tool. If the user says "use defaults" or skips, keep the tier labels as-is and note them as ASSUMPTIONS.
- **Project policy** (rigor knobs → written to `army.conf`; **security barriers are NOT a knob — always on**). Ask which level fits THIS repo on each axis:
  - **Testing** — `strict` (TDD RED→GREEN + Testing Trophy, default) · `pragmatic` (tests, not strict-RED-first) · `light` (smoke/happy-path) · `none` (no tests — throwaway/side project). Respect `none` if the user picks it.
  - **Lint** — `on` (gate blocks on lint errors, default) · `off`.
  - **CI** — `on` (use our `quality.yml`) · `off` (the repo has its own, richer CI).
  Default everything to the strict end if the user doesn't care.
"Assume and go" → record **ASSUMPTIONS** explicitly. **Greenfield** (empty repo): skip code-recon, ask the full set, and choose the stack together with the user.

## Step 3 · Generate the tailored team (write files)
Use the just-materialized agents in `<tool>/agents/` as the starting CONTRACT and **rewrite each in place, specialized to this repo**. Keep every agent's role and guarantees; inject repo specifics — including the model names chosen in Step 2:
- Replace the `model:` frontmatter field in each agent with the concrete model name the user provided for that tier. If the user kept defaults, document the tier label and add a comment explaining the reasoning.
- **Exact verification commands** (lint/test/e2e) + single-test invocation.
- **Test framework + file naming/paths** to mirror; Testing-Trophy mix appropriate to the stack.
- **Conventions** (naming, smart/dumb, layering), domain vocabulary, forbidden zones.
- `architect`: stack-specific manifest defaults + example assertions in THIS repo's framework.
- `tester`: this repo's test/single-test commands + example specs in the real framework.
- `code-reviewer`: this repo's standards (from `AGENTS.md`) as the explicit checklist.
- `security-auditor` / `perf-auditor`: stack-relevant checks (e.g. the actual ORM's N+1, this framework's injection sinks).

**`<prompt_examples>` — rewrite them, don't keep the generic ones (MANDATORY).** The baseline examples are placeholders. For EVERY agent replace them with **≥2–3 examples drawn from THIS repo**, VARIED (not three slants on one scenario):
  - real file paths from this repo's layout and real commands (incl. single-test invocation), in the repo's actual framework/assertion syntax;
  - span different Testing-Trophy levels (E2E/Integration vs Component vs Unit) and different shapes the repo really has;
  - mine the codebase for a real reusable asset or pattern and reference it by path;
  - keep each example concrete: explicit assertions, RED→GREEN where TDD applies.
  If you can't find enough distinct real scenarios, say so rather than padding with filler.
Then:
- **Write `army.conf`** from the Step-2 policy answers (`TEST_POLICY` / `LINT_POLICY` / `CI_MODE`) **plus the exact commands discovered in Step 1** (`FMT_CMD` / `LINT_CMD` / `TEST_CMD`). These override `detect.sh` — hooks read `army.conf` last. Only write a command after you verified it runs (Step 4). If `CI_MODE=off`, remove any copied `quality.yml`. Honor `TEST_POLICY` everywhere: at `none` the team SKIPS the `tester`/TDD steps; at `light`/`pragmatic` scale the Testing-Trophy mix down. Never relax security barriers.
- **Write/refresh `CLAUDE.md`** (and `AGENTS.md` — the cross-tool entry point every tool reads) with the decisions: stack, exact commands, conventions, testing strategy, the team roster, the guardrails (hooks), and a **`## Project policy`** block summarizing `army.conf`.
- **Specialize the blueprint templates** in `<tool>/templates/blueprint/` to this repo.
- **Create the `design-docs/` skeleton.**
- Before overwriting any agent, save the original as `<tool>/agents/<name>.base.md` (reversible).

## Step 4 · Verify & report
- Run the detected verify (lint + tests) ONCE to confirm the wired commands actually work; if wrong, fix them in the agents + CLAUDE.md.
- Print a short report: tool detected + where files landed, detected stack, commands wired, which agents were specialized, assumptions made. Suggest next step: `/ship "<first task>"`.

## Rules
- **Do not invent commands** — verify them by running. **Do not weaken** any agent's guarantees while specializing.
- If a materialized file looks hand-edited (diverges from baseline), ASK before overwriting.

## Quality bar (non-negotiable)
Every agent you write or specialize MUST conform to `<tool>/agents/_STANDARD.md` and pass its
self-check. Use the recon above so each agent is repo-specific, and match the depth of
`architect.md`. Do not produce thin or generic agents — if you can't reach that bar for one,
say what's missing and ask.
