# AGENTS.md — Agent Army (cross-tool entry point)

> Portable instruction file read natively by 20+ agentic coding tools (OpenAI Codex, Cursor,
> GitHub Copilot, Gemini/Antigravity, Aider, Windsurf, Zed, Factory, Jules, Devin, Amp, VS Code,
> JetBrains Junie …; Claude Code reads it too). This is the kickoff for the self-checking Agent
> Army installed in this repo. Keep it focused — deep detail lives in `.claude/skills/` and
> `.claude/agents/`.

## Target tool
Set at install time: **other**. If this says `auto` or `other`, the bootstrap will ask
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
> other. Honor `.claude/agents/_STANDARD.md` and `.claude/skills/context-budget/SKILL.md`.
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
- Uncertain → ask, don't guess.
