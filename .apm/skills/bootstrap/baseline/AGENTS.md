# AGENTS.md — Agent Army (cross-tool entry point)

> Portable instruction file read natively by 20+ agentic coding tools (OpenAI Codex, Cursor,
> GitHub Copilot, Gemini/Antigravity, Aider, Windsurf, Zed, Factory, Jules, Devin, Amp, VS Code,
> JetBrains Junie …; Claude Code reads it too). This is the kickoff for the self-checking Agent
> Army installed in this repo. Keep it focused — deep detail lives in `<SKILLS_DIR>/` and
> `<AGENTS_DIR>/`.

## Target tool
Set at install time: **__ARMY_TOOL__**. If this says `auto` or `other`, the bootstrap will ask
once which tool is in use and adapt; otherwise treat it as already chosen (do not re-ask).

## First run — bootstrap ONCE
The team shipped here is a generic, tool-agnostic baseline. Before real work, specialize it to
THIS repo and emit it in this tool's native format.

**Run the bootstrap routine in `<SKILLS_DIR>/bootstrap/SKILL.md`.**
- **Claude Code:** type `/bootstrap`.
- **Other tools (no slash command):** start a task and paste the Kickoff prompt below, or tell the
  agent: "Follow `<SKILLS_DIR>/bootstrap/SKILL.md` against this repo."

Bootstrap will: confirm the tool and resolve its Adapter Contract (agent format/location, memory
file, guardrail mechanism, command format, model controls), read the codebase, ask a few gap
questions, then emit a repo-tailored team in this tool's native format, refresh this `AGENTS.md`
(+ the tool's native memory file), wire the guardrails, and verify the commands actually run. Run
it once.

### Kickoff prompt (copy-paste for tools without slash commands)
> Read `<SKILLS_DIR>/bootstrap/SKILL.md` and run it against this repository. The target tool is
> __ARMY_TOOL__. Honor `<AGENTS_DIR>/_STANDARD.md` and the "Cost & context discipline" section below.
> Ask only for gaps recon can't settle, then specialize the team in this tool's native format.

## Day-to-day — plan, ship, resume
Invoke `architect` directly when you want only discovery and a blueprint in `design-docs/`; it never
implements source code. Use `<SKILLS_DIR>/ship/SKILL.md` to execute or resume work:

- **Claude Code:** `/ship "<task, PR, ticket, or small fix>"`, or plain `/ship` to resume the one
  unambiguous open scope.
- **Other tools:** "Follow `<SKILLS_DIR>/ship/SKILL.md` for this task: <task>."

`/ship` resolves the narrowest unambiguous scope from blueprint state. If no scope or several candidates
exist, it asks; it never guesses from recency. Its closed loop is strict TDD (Red → Green) → independent
review + security → repairs → Green + re-audit → docs + full verification → `ready_for_human_review`.

## The team (delegate by role)
- `architect` — interview (greenfield/existing) + blueprint in `design-docs/` (never writes source)
- `tester` — strict-TDD executor: writes RED tests from the contract, verifies GREEN
- `code-reviewer` — architectural audit of the diff vs blueprint + business goal; routes fixes/escalations
- `security-auditor` — read-only security audit (secrets, injection, unsafe data handling)
- `perf-auditor` — read-only performance audit (measure first, then hotspots)
- `docs-writer` — minimal, truthful documentation updates
**Who writes what code:** `tester` writes and runs the **test** code (never production). **Production code** is written by the `/ship` orchestrator (main session) by default — it holds the warm context (blueprint + RED tests + your conversation), so small/medium tasks need no extra hop. For **large, file-heavy, or parallel-PR** tasks, delegate production coding to the `coder` subagent (ships off the default `/ship` pipeline; `/bootstrap` tailors it): its exploration stays in its own throwaway context window and it returns a short summary, which keeps the orchestrator's session lean (see "Cost & context discipline" below).
Quality bar for every agent: `<AGENTS_DIR>/_STANDARD.md`.

## Delegation, review & model gates
- **Contract before action:** every delegated task names its goal, allowed read/write paths, forbidden paths and stop conditions. A worker stops and reports when it needs to leave that scope or a contract assumption is unproved; it never silently broadens a task.
- **Supervised preflight:** before delegated production coding, the coder returns its plan and exact write list, then waits for `GO`. In autonomous mode it may continue only when that list is inside the blueprint's write scope.
- **Fresh review:** give `code-reviewer` only the task contract, diff and human decisions. Do not forward implementation/tester reports, reasoning or transcripts; call a missing contract a `Diff-Only Review`.
- **Execution state:** each PR blueprint persists its interaction policy, selected checkpoints and task/PR status. `/ship` resumes that state across sessions; it asks when a preference, requirement or scope is not unambiguous.
- **Model & effort routing:** architect sets portable per-task `Execution Profile` (`light`/`mid`/`strong`, `low`/`medium`/`high`). `/ship` uses only the active adapter's confirmed `model_control`: it may configure fresh subagents where supported, otherwise inherits and reports the limitation. A main-session change remains a user decision (`switch and continue` or `stay current`), recorded with the task rather than the feature manifest.
- **Closure:** review and security run from independent evidence. Every confirmed security finding must be repaired and re-audited inside the contract; an expansion becomes `awaiting_approval`, never a silent scope change.

## Cost & context discipline
The team already bakes most cost control into its parts (per-task profiles in blueprints; plan-before-code in `architect`; trivial-task-inline + parallel read-only audits in `ship`; delegate-and-summarize in `coder`). Agent definitions do not pin a vendor model; `/ship` recommends a model only when task evidence justifies it, and the user decides whether to switch. On top of that, every agent honors:
- **Pointers, not payloads** — hand subagents file paths + the blueprint section, not pasted file bodies; read the slice you need (`offset`/`limit`, the touched function), not whole files "for safety".
- **Keep the stable prefix cached** — `AGENTS.md`, `CLAUDE.md` and agent defs stay stable and pointer-shaped (not encyclopedias), so volatile detail loads on demand instead of re-paying tokens every turn.
- **Script, don't prompt, for bulk** — never ask a model to map/filter/transform a large file in chat; write a script and run it locally (~0 tokens). Mechanical checks belong in a hook/script, not a prompt.
- **English + right-sized model** — agent-facing text in English (Polish morphology costs ~1.5× the tokens); prefer a local/open model when it's adequate for routine, low-judgment work.

## Keeping the team current — offer `/adapt-army` (do not auto-apply)
The team is only as good as it stays current. When, during ANY conversation, the user states a
**durable, repo-wide** guideline or corrects an architectural behavior that should hold beyond the
current task — e.g. "from now on always X", "we never do Y", "switch to strict TDD", "no custom CSS" —
**offer to propagate it into the whole team**: "That sounds like a new repo convention — want me to bake
it into the army? (`/adapt-army`)". Only OFFER; never rewrite agents silently. Be conservative: a
one-off task tweak ("for this PR skip the e2e") is NOT a guideline — apply it to the task only and leave
the team untouched. The routine lives in `<SKILLS_DIR>/adapt-army/SKILL.md` (it routes the guideline to
every agent that owns it and keeps `AGENTS.md` the source of truth).

## Hardening the formatter config — offer once, never nag
When an agent keeps hitting the SAME style gap the formatter doesn't enforce (e.g. the diff repeatedly
wants single quotes but `.prettierrc` has no `singleQuote`, or `*.yml` indent drifts because nothing
pins it), it may propose — ONCE — adding that rule to the **formatter's own config that the hooks
already run** (`.prettierrc`/`.editorconfig`/ruff/gofmt — whatever structured `quality.format` in `.agent-army/config.json` invokes),
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
