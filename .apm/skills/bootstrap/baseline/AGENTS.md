# AGENTS.md — Agent Army (cross-tool entry point)

> Portable instruction file read natively by 20+ agentic coding tools (OpenAI Codex, Cursor,
> GitHub Copilot, Gemini/Antigravity, Aider, Windsurf, Zed, Factory, Jules, Devin, Amp, VS Code,
> JetBrains Junie …; Claude Code reads it too). This is the kickoff for the self-checking Agent
> Army installed in this repo. Keep it focused — deep detail lives in `.claude/skills/` and
> `.claude/agents/`.

## Target tool
Set at install time: **__ARMY_TOOL__**. If this says `auto` or `other`, the bootstrap will ask
once which tool is in use and adapt; otherwise treat it as already chosen (do not re-ask).

## First run — bootstrap ONCE
The team shipped here is a generic, tool-agnostic baseline. Before real work, specialize it to
THIS repo and emit it in this tool's native format.

**Run the bootstrap routine in `.claude/skills/bootstrap/SKILL.md`.**
- **Claude Code:** type `/bootstrap`.
- **Other tools (no slash command):** start a task and paste the Kickoff prompt below, or tell the
  agent: "Follow `.claude/skills/bootstrap/SKILL.md` against this repo."

Bootstrap will: confirm the tool and resolve its Adapter Contract (agent format/location, memory
file, guardrail mechanism, command format, model tiers), read the codebase, ask a few gap
questions, then emit a repo-tailored team in this tool's native format, refresh this `AGENTS.md`
(+ the tool's native memory file), wire the guardrails, and verify the commands actually run. Run
it once.

### Kickoff prompt (copy-paste for tools without slash commands)
> Read `.claude/skills/bootstrap/SKILL.md` and run it against this repository. The target tool is
> __ARMY_TOOL__. Honor `.claude/agents/_STANDARD.md` and `.claude/skills/context-budget/SKILL.md`.
> Ask only for gaps recon can't settle, then specialize the team in this tool's native format.

## Day-to-day — ship a task
For each feature/fix, run the pipeline in `.claude/skills/ship/SKILL.md`:
discovery/interview → blueprint in `design-docs/` → strict TDD (Red → Green) → architectural
review → security → docs → commit (only with your approval).
- **Claude Code:** `/ship "<task>"`.
- **Other tools:** "Follow `.claude/skills/ship/SKILL.md` for this task: <task>."

## The team (delegate by role)
- `architect` — interview (greenfield/existing) + blueprint in `design-docs/` (never writes source)
- `tester` — strict-TDD executor: writes RED tests from the contract, verifies GREEN
- `code-reviewer` — architectural audit of the diff vs blueprint + business goal; routes fixes/escalations
- `security-auditor` — read-only security audit (secrets, injection, unsafe data handling)
- `perf-auditor` — read-only performance audit (measure first, then hotspots)
- `docs-writer` — minimal, truthful documentation updates
**Who writes what code:** `tester` writes and runs the **test** code (never production). **Production code** is written by the `/ship` orchestrator (main session) by default — it holds the warm context (blueprint + RED tests + your conversation), so small/medium tasks need no extra hop. For **large, file-heavy, or parallel-PR** tasks, delegate production coding to the `coder` subagent (ships off the default `/ship` pipeline; `/bootstrap` tailors it): its exploration stays in its own throwaway context window and it returns a short summary, which keeps the orchestrator's session lean (see `context-budget` → "avoid infinite sessions").
Quality bar for every agent: `.claude/agents/_STANDARD.md`. Context discipline (pass pointers, read
scoped, cache the stable prefix, cheapest adequate model tier): `.claude/skills/context-budget/SKILL.md`.

## Keeping the team current — offer `/adapt-army` (do not auto-apply)
The team is only as good as it stays current. When, during ANY conversation, the user states a
**durable, repo-wide** guideline or corrects an architectural behavior that should hold beyond the
current task — e.g. "from now on always X", "we never do Y", "switch to strict TDD", "no custom CSS" —
**offer to propagate it into the whole team**: "That sounds like a new repo convention — want me to bake
it into the army? (`/adapt-army`)". Only OFFER; never rewrite agents silently. Be conservative: a
one-off task tweak ("for this PR skip the e2e") is NOT a guideline — apply it to the task only and leave
the team untouched. The routine lives in `.claude/skills/adapt-army/SKILL.md` (it routes the guideline to
every agent that owns it and keeps `AGENTS.md` the source of truth).

## Hardening the formatter config — offer once, never nag
When an agent keeps hitting the SAME style gap the formatter doesn't enforce (e.g. the diff repeatedly
wants single quotes but `.prettierrc` has no `singleQuote`, or `*.yml` indent drifts because nothing
pins it), it may propose — ONCE — adding that rule to the **formatter's own config that the hooks
already run** (`.prettierrc`/`.editorconfig`/ruff/gofmt — whatever `FMT_CMD` in `army.conf` invokes),
so it's machine-enforced from then on instead of re-litigated every PR.
- **Conservative, not naggy:** a one-off restyle is just diff-noise — revert it (see Hard rules), don't
  raise config. Only a *recurring, repo-wide* gap earns the offer, and only once — if declined, drop it.
- **One source of truth, no hook conflict:** EXTEND the config the formatter already reads; never add a
  second file that contradicts it (e.g. `.editorconfig` indent ≠ `.prettierrc` indent). Keep each style
  key in exactly one place so the hook, the editor and CI can't disagree.
- **Offer, don't apply:** show the proposed config diff and let the human accept — same etiquette as
  `/adapt-army`.

## Guardrails (the "law" the model cannot talk past)
- **git pre-commit + CI (`.github/workflows/quality.yml`)** — the hard, tool-independent gate:
  secret scan + lint + tests. Active on EVERY tool, even if someone bypasses the agent.
- **Claude Code only:** lifecycle hooks in `.claude/settings.json` (PreToolUse / PostToolUse /
  SubagentStop / Stop) add a deterministic runtime barrier. On other tools this file is inert —
  the git pre-commit + CI gate is the active barrier.

## Hard rules
- Do NOT commit without human approval.
- Do NOT weaken or disable tests/hooks to "pass".
- Do NOT paste secrets into code or prompts.
- Do NOT reformat lines you aren't functionally changing — no quote-style flips (`"`↔`'`), re-indentation, key/import reordering, or whitespace churn, including in `*.yml`/`*.json`/`*.toml`. Style is the formatter's job; keep the diff to the actual change.
- Uncertain → ask, don't guess.
