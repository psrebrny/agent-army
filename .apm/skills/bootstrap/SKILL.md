---
name: bootstrap
description: One-time intelligent setup of the agent team for THIS repo, after installing via apm. Materializes the bundled baseline (agents, hooks, templates) into your tool's directory, then AUTHORS repo-tailored agents from a deep code scan (real laws, exact commands, test idioms) plus a canonical AGENTS.md and the design-docs skeleton. Run /bootstrap once, right after `apm install agent-army`.
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

## Step 1 · Recon (DEEP — read real code before you ask)
This step decides everything. A shallow recon → generic agents. **Read actual source, not just manifests.**

### 1a · Exhaustive discovery sweep (deterministic — do NOT eyeball the root only)
Last time bootstrap MISSED a nested `frontend/AGENTS.md`. Don't repeat that: **enumerate every relevant file across the whole tree first, then read.** Run a real search — don't assume root-only:
```bash
# Standards & memory files at ANY depth (this is what catches frontend/AGENTS.md, src/AGENTS.md, …)
find . \( -name node_modules -o -name build -o -name dist -o -name target -o -name .gradle -o -name .git \) -prune -o \
  -type f \( -iname 'AGENTS.md' -o -iname 'CLAUDE.md' -o -iname 'README*' -o -iname '.cursorrules' -o -iname '*.mdc' \) -print
# Every build/dependency manifest at ANY depth (this is what catches monorepo sub-stacks)
find . \( -name node_modules -o -name build -o -name dist -o -name target -o -name .gradle -o -name .git \) -prune -o \
  -type f \( -name 'package.json' -o -name 'pyproject.toml' -o -name 'build.gradle*' -o -name 'pom.xml' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name '*.csproj' \) -print
# Test/CI/lint configs
find . -path ./node_modules -prune -o -type f \( -iname '*jest*' -o -iname '*vitest*' -o -iname 'cypress.config.*' -o -iname 'playwright.config.*' -o -iname 'pytest.ini' -o -iname '*.eslintrc*' -o -iname 'detekt.yml' -o -iname '.editorconfig' \) -print
find .github/workflows -type f 2>/dev/null
```
**Print the full list of what you found, then read EVERY standards file (`AGENTS.md`/`CLAUDE.md` at all depths) and EVERY manifest.** Nested `AGENTS.md` files are authoritative for their subtree — they often hold the real per-stack laws. Missing one = generic agents for that stack.

### 1b · Reason explicitly before concluding (Chain-of-Thought — write this out)
Don't jump to writing the report. First THINK on paper, briefly:
1. **How many stacks / deployables are here?** (root + each manifest dir). Name them.
2. **For each stack, what is the dominant architectural pattern?** State your hypothesis, then **open 2–3 real files that should prove or break it** and confirm. If the code contradicts your guess, revise — evidence wins.
3. **What would a senior reviewer of THIS repo reject in a PR?** Those rejections are the repo's laws — list them.
4. **What's genuinely ambiguous and must be ASKED** (vs. answerable from code)?
Keep it short but real — this reasoning is what turns a scan into understanding.

### 1c · Mine conventions from REAL code
- **Monorepo:** if 1a found MULTIPLE manifests in subdirs, map **each stack separately** — its own dir, framework, exact commands, and its own nested `AGENTS.md` laws. Per-stack commands get wired into `army.conf` in Step 3.
- **Mine conventions from REAL code (mandatory — open ≥3–5 real files per stack):** pick representative source files in each layer and **read them**. Extract, with file paths as evidence:
  - the **architectural patterns this repo actually enforces** (e.g. "domain uses `Facade` + `Creator/Editor/Finder`", "Smart/Dumb with `...Ref` service interface", "PrimeFlex only — no custom CSS") — quote the real class/dir that proves it;
  - **naming & layout laws** (package/folder structure, file suffixes, test placement);
  - **error-handling & boundary conventions**;
  - the **real test style** — open 1–2 existing test files per layer and capture the framework idiom (Spock `given/when/then`, Cypress component vs e2e, base classes like `IntegrationTest`, WireMock/Testcontainers usage).
- **Reusable assets inventory:** list real shared components/utils/mocks/selectors by path (these become anti-reinvention anchors in the agents).
- **Capture EXACT commands** actually used (build / lint / unit / integration / e2e) and how to run a SINGLE test — per stack if monorepo.
- Exclude `node_modules`, `build`, `dist`, `target`, `.gradle`.

**Output a RECON EVIDENCE REPORT before Step 2** (this is the raw material every agent is built from — not optional):
```
Stack(s):       <per stack: language, framework, versions>
Architecture:   <3–6 LAWS this repo enforces, each with a proving file path>
Conventions:    <naming/layout/error-handling, with paths>
Test style:     <framework idioms + base classes + example test file paths>
Reusable assets:<path → role, the anti-reinvention list>
Commands:       <fmt / lint / unit / integration / e2e / single-test, per stack>
Gaps:           <what code couldn't tell you → ask in Step 2>
```
If you cannot fill a row from real files, say so — do not guess. Never ask about anything this report already answered.

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
The baseline agents are a **CONTRACT (role + guarantees), not a fill-in-the-blanks form.** Rewrite each in place, AUTHORED for this repo from the Recon Evidence Report.

> ⛔ **The failure mode to avoid: "localization".** Swapping generic paths for real paths and the stack name into otherwise-untouched baseline rules is NOT specialization — it produces a generic agent wearing this repo's filenames. That is explicitly forbidden.
> ✅ **What's required instead: "internalization".** Each agent must encode THIS repo's actual **laws** as first-class rules, with proving examples from real code. The reader should be unable to reuse the agent in a different repo without rewriting it.

**Before writing each agent, reason first (CoT — one short paragraph per agent):** "This is the `<role>`. In THIS repo it will mostly be invoked for `<concrete situations from the evidence>`. The laws it must enforce are `<X, Y, Z with proving paths>`. The real assets it should reuse are `<paths>`. The framework idioms its examples must use are `<…>`." Only then write the file. This stops you from defaulting to the baseline's generic phrasing.

For **every** agent:
- **Bake in 3–6 repo LAWS** from the Recon report as concrete BAD/GOOD rules — e.g. "GOOD: new domain logic goes through `XFacade` + `Creator/Editor/Finder` (see `…/domain/…`); BAD: a controller calling the repository directly." Reference the real proving file. These laws are the difference between localization and internalization.
- **Name the repo's real anti-reinvention anchors** (the reusable assets) and instruct reuse-over-rewrite by path.
- Replace `model:` with the concrete model for that tier (Step 2); if defaults kept, document the tier label + reasoning. (Drop `tools:` if the tool rejects a string `tools` field — e.g. OpenCode; keep it only where the tool accepts it.)
- **Exact verification commands** (lint/test/integration/e2e) + single-test invocation — per stack if monorepo.
- **Test framework + file naming/placement** mirrored from the real test files you opened; Testing-Trophy mix appropriate to the stack.
- Per role, go beyond paths:
  - `architect`: encode this repo's layering laws, the real manifest defaults, and example assertions in THIS framework's syntax (Spock `given/when/then`, Cypress, etc.).
  - `tester`: this repo's real test/single-test commands + example specs that mirror an actual existing test (base class, stubs, containers).
  - `code-reviewer`: turn this repo's standards (`AGENTS.md` + the mined laws) into an explicit, repo-specific checklist — not generic "is it clean?".
  - `security-auditor` / `perf-auditor`: the actual stack's sinks (this ORM's N+1, this framework's injection points, this reactive stack's blocking-call traps).
- **Diff-from-baseline justification (self-gate):** for each agent, before saving, be able to answer "what here is true ONLY for this repo?" — if the honest answer is "just the paths," the agent is not done; go deeper or say what's missing.

**`<prompt_examples>` — rewrite them, don't keep the generic ones (MANDATORY).** The baseline examples are placeholders. For EVERY agent replace them with **≥2–3 examples drawn from THIS repo**, VARIED (not three slants on one scenario):
  - real file paths from this repo's layout and real commands (incl. single-test invocation), in the repo's actual framework/assertion syntax;
  - span different Testing-Trophy levels (E2E/Integration vs Component vs Unit) and different shapes the repo really has;
  - mine the codebase for a real reusable asset or pattern and reference it by path;
  - keep each example concrete: explicit assertions, RED→GREEN where TDD applies.
  If you can't find enough distinct real scenarios, say so rather than padding with filler.
Then:
- **Write `army.conf`** from the Step-2 policy answers (`TEST_POLICY` / `LINT_POLICY` / `CI_MODE`) **plus the exact commands discovered in Step 1** (`FMT_CMD` / `LINT_CMD` / `TEST_CMD`). These override `detect.sh` — hooks read `army.conf` last. Only write a command after you verified it runs (Step 4). **Monorepo:** chain per-stack commands so the barrier covers ALL stacks, e.g. `TEST_CMD=cd frontend && npm test && cd ../backend && pytest` (or document per-stack `*_FRONTEND`/`*_BACKEND` vars if the hooks support them). If `CI_MODE=off`, remove any copied `quality.yml`. Honor `TEST_POLICY` everywhere: at `none` the team SKIPS the `tester`/TDD steps; at `light`/`pragmatic` scale the Testing-Trophy mix down. Never relax security barriers.
- **Write/refresh `AGENTS.md` — the single canonical entry point** (every tool reads it, including Claude Code): stack(s), exact commands, the mined laws & conventions, testing strategy, team roster, guardrails (hooks), and a **`## Project policy`** block summarizing `army.conf`. This is where the real content lives.
  - **`CLAUDE.md` only for Claude Code, and keep it THIN** — a few lines that point to `AGENTS.md` as the source of truth (so Claude's native auto-load finds it) plus the `## Project policy` summary. Do NOT duplicate AGENTS.md into it. For OpenCode/Cursor/etc. skip `CLAUDE.md` entirely — `AGENTS.md` is enough.
- **Specialize the blueprint templates** in `<tool>/templates/blueprint/` to this repo.
- **Create the `design-docs/` skeleton.**
- Before overwriting any agent, save the original as `<tool>/agents/<name>.base.md` (reversible).

## Step 4 · Reflection & self-critique (MANDATORY second pass — do not skip)
First drafts read as "baseline + paths". This pass is where they become repo-authored. Don't trust the first write.

### 4a · Re-look at the repo (fresh eyes)
Re-open **2–3 files you did NOT read in Step 1** — a different feature, a different layer, another stack's code. Ask: does what I wrote into the agents still hold here, or did I over-fit to the first files I happened to open? Adjust the laws if the second sample disagrees. Also re-check: did I honor **every** nested `AGENTS.md` found in 1a? Name each one and the agent rule it produced — if a nested standards file produced no rule, that's a miss; fix it.

### 4b · Critique each generated agent (write the critique, then revise)
For each agent, score it honestly against three questions and **write the answers down**:
1. **Internalization:** "Could this file be dropped into a *different* repo unchanged?" If yes → it's still generic. Name the generic sentences and replace them with repo-law sentences.
2. **Evidence:** "Does every repo-specific claim cite a real file/command?" Flag any unproven claim → verify it or cut it.
3. **Coverage & variety:** "Do the `<prompt_examples>` span the real shapes this agent meets (different layers, happy + error, different Testing-Trophy levels)?" If they're three slants on one scenario → replace until varied.
List concrete defects (file + line/section), THEN revise the files. Loop 4b until each agent passes all three — don't proceed with known defects.

### 4c · Cross-agent consistency
Check the team agrees with itself: the commands in `architect`, `tester`, `code-reviewer` and `army.conf` are identical; the laws in `code-reviewer`'s checklist match the laws `architect` enforces; no two agents claim the same responsibility. Fix drift.

## Step 5 · Verify & report
- Run the detected verify (lint + tests) ONCE to confirm the wired commands actually work; if wrong, fix them in the agents + `army.conf` + AGENTS.md.
- Print a short report: tool detected + where files landed, detected stack(s), commands wired, the repo LAWS you extracted (with proving paths), which agents were specialized, what the reflection pass changed, and assumptions made. Suggest next step: `/ship "<first task>"`.

## Rules
- **Do not invent commands** — verify them by running. **Do not weaken** any agent's guarantees while specializing.
- If a materialized file looks hand-edited (diverges from baseline), ASK before overwriting.

## Quality bar (non-negotiable)
Every agent you write or specialize MUST conform to `<tool>/agents/_STANDARD.md` and pass its
self-check. Match the depth of `architect.md`. Two hard gates on top of `_STANDARD.md`:
- **Evidence gate:** every repo-specific claim in an agent traces to a real file/command from the Recon Evidence Report — no invented paths, no guessed commands (verify in Step 4).
- **Internalization gate:** each agent fails review if its repo-specificity is "just the paths". It must carry this repo's laws, real reusable anchors, and real test idioms. If you can't reach that bar for an agent, STOP and say exactly what's missing — don't ship a localized-but-generic file.
