---
name: bootstrap
description: One-time intelligent setup of the agent team for THIS repo. Reads the codebase, asks a few smart questions, then GENERATES repo-tailored agents (exact commands, test framework, conventions) plus CLAUDE.md/AGENTS.md and the design-docs skeleton. Run /bootstrap once, right after installing the army.
---
# /bootstrap — tailor the agent team to THIS repo

The installer only COPIED generic baseline agents. Your job now is to turn them into a team
specialized for this exact project. You (the lead) do the thinking and write the files —
bash did none of it.

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
"Assume and go" → record **ASSUMPTIONS** explicitly. **Greenfield** (empty repo): skip code-recon, ask the full set, and choose the stack together with the user.

## Step 3 · Generate the tailored team (write files)
Use the baseline agents in `.claude/agents/` as the starting CONTRACT and **rewrite each in place, specialized to this repo**. Keep every agent's role and guarantees; inject repo specifics — including the model names chosen in Step 2:
- Replace the `model:` frontmatter field in each agent with the concrete model name the user provided for that tier. If the user kept defaults, document the tier label and add a comment explaining the reasoning so the next person knows what to change.
- **Exact verification commands** (lint/test/e2e) + single-test invocation.
- **Test framework + file naming/paths** to mirror; Testing-Trophy mix appropriate to the stack.
- **Conventions** (naming, smart/dumb, layering), domain vocabulary, forbidden zones.
- `architect`: stack-specific manifest defaults + example assertions written in THIS repo's framework.
- `tester`: this repo's test/single-test commands + example specs in the real framework.
- `code-reviewer`: this repo's standards (from `AGENTS.md`) as the explicit checklist.
- `security-auditor` / `perf-auditor`: stack-relevant checks (e.g. the actual ORM's N+1, this framework's injection sinks).

**`<prompt_examples>` — rewrite them, don't keep the generic ones (MANDATORY).** The baseline examples are placeholders (`e2e/user-list.*`, `pesel.validator.*`). For EVERY agent replace them with **≥2–3 examples drawn from THIS repo**, and make them VARIED — not three slants on the same scenario. Cover a spread of the cases each agent actually meets here:
  - use **real file paths** from this repo's layout and **real commands** (incl. single-test invocation), in the repo's actual framework/assertion syntax;
  - span different **Testing-Trophy levels** (E2E/Integration vs Component vs Unit) and different **shapes** the repo really has (e.g. UI feature + backend endpoint + pure-logic util; happy path + error/edge path);
  - mine the codebase for a real reusable asset or pattern and reference it by path, so the example teaches reuse, not invention;
  - keep each example concrete: explicit assertions, RED→GREEN where TDD applies — no abstract `[UNIT]`/`[E2E]` tags without a path.
  If you can't find enough distinct real scenarios for an agent, say so rather than padding with generic filler.
Then:
- **Write/refresh `CLAUDE.md`** (and `AGENTS.md` if the repo uses it) with the decisions: stack, exact commands, conventions, testing strategy, the team roster, the guardrails (hooks).
- **Specialize the blueprint templates** in `.claude/templates/blueprint/` to this repo (real commands, test file naming, framework-specific assertion examples).
- **Create the `design-docs/` skeleton.**
- Before overwriting any agent, save the original as `.claude/agents/<name>.base.md` (reversible).

## Step 4 · Verify & report
- Run the detected verify (lint + tests) ONCE to confirm the wired commands actually work; if wrong, fix them in the agents + CLAUDE.md.
- Print a short report: detected stack, commands wired, which agents were specialized, assumptions made. Suggest next step: `/ship "<first task>"`.

## Rules
- **Do not invent commands** — verify them by running. **Do not weaken** any agent's guarantees while specializing.
- If an agent file looks hand-edited (diverges from the baseline), ASK before overwriting.

## Quality bar (non-negotiable)
Every agent you write or specialize MUST conform to `.claude/agents/_STANDARD.md` and pass its
self-check. Use code analysis (the recon above) so each agent is repo-specific, and match the
depth and care of `.claude/agents/architect.md`. Do not produce thin or generic agents — if you
can't reach that bar for one, say what's missing and ask.
