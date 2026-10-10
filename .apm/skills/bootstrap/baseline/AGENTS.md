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
Invoke `architect` directly when you want discovery and an interactive blueprint in `design-docs/`; it never
implements source code. The main session conditionally uses `planning-analyst` for material unknowns and
requires `plan-reviewer` in a fresh context before handing a new blueprint to execution. Use
`<SKILLS_DIR>/ship/SKILL.md` to execute or resume work:

- **Claude Code:** `/ship "<task, PR, ticket, or small fix>"`, or plain `/ship` to resume the one
  unambiguous open scope.
- **Other tools:** "Follow `<SKILLS_DIR>/ship/SKILL.md` for this task: <task>."

`/ship` resolves the narrowest unambiguous scope from blueprint state. If no scope or several candidates
exist, it asks; it never guesses from recency. Its closed loop is policy-aware TDD (Red → Green, or a
passing before/after baseline for an explicitly approved behavior-preserving refactor) → independent
review + security → repairs → Green + re-audit → docs + full verification → `ready_for_human_review`.

## The team (delegate by role)
- `architect` — interview (greenfield/existing) + blueprint in `design-docs/` (never writes source)
- `planning-analyst` — conditional, read-only diagnosis/research with evidence; no blueprint or edits
- `plan-reviewer` — independent, read-only review of a saved blueprint revision; no edits or execution
- `tester` — prioritizes user-visible risks, writes contract tests, verifies RED/GREEN or an approved refactor baseline, and checks test confidence where needed
- `code-reviewer` — architectural audit of the diff vs blueprint + business goal; routes fixes/escalations
- `security-auditor` — read-only security audit (secrets, injection, unsafe data handling)
- `perf-auditor` — read-only performance audit (measure first, then hotspots)
- `docs-writer` — minimal, truthful documentation updates
**Who writes what code:** `tester` writes and runs the **test** code (never production). **Production code** is written by the `/ship` orchestrator (main session) by default — it holds the warm context (blueprint + RED tests + your conversation), so small/medium tasks need no extra hop. For **large, file-heavy, or parallel-PR** tasks, delegate production coding to the `coder` subagent (ships off the default `/ship` pipeline; `/bootstrap` tailors it): its exploration stays in its own throwaway context window and it returns a short summary, which keeps the orchestrator's session lean (see "Cost & context discipline" below).
Quality bar for every agent: `<AGENTS_DIR>/_STANDARD.md`.

## Delegation, review & model gates
- **Contract before action:** every delegated task names its goal, allowed read/write paths, forbidden paths and stop conditions. A worker stops and reports when it needs to leave that scope or a contract assumption is unproved; it never silently broadens a task.
- **Interactive preflight:** a short `task plan` before each task names the behavior, cases, verification and exact write list. It waits only when it carries a question or something unexpected; otherwise work continues. In autonomous mode work may continue only when that list is inside the blueprint's write scope.
- **Fresh review:** give `code-reviewer` only the task contract, diff and human decisions. Do not forward implementation/tester reports, reasoning or transcripts; call a missing contract a `Diff-Only Review`.
- **Fresh plan review:** give `plan-reviewer` the approved goal, confirmed decisions, exact blueprint revision and relevant raw source pointers. Do not pass the architect transcript/self-review or analyst report as proof. If the target cannot provide an independent context, record `INSUFFICIENT_EVIDENCE`; never label self-review independent.
- **Execution state:** each PR blueprint persists its `autonomous` or `interactive` policy, active roles, Interaction Card, task/PR status, Execution Progress and any Temporary delegation. `/ship` writes it immediately before and after every role handoff, so it can resume without guessing from a Todo list or chat history.
- **Two interaction modes:** `autonomous` pauses only for blueprint/scope, real decisions and final human review. `interactive` works with the user: pauses keep the user in the thread and able to steer, so it adds one task review after every verified task plus a `task plan` that waits only for a real question. Explicit one-task delegation lets the agent settle in-scope choices itself but always returns to task review. The user can switch modes at any safe boundary; raw role/checkpoint selection is never exposed.
- **Delivery-focused interaction:** `/ship` shows selected task outcomes plus closure, the current step and finish condition. Ask one consequential question only for a real gap; no quizzes or tutoring. Reuse facts and decisions, act when clear, and explain map changes. Task evidence remains authoritative; GREEN still awaits audit. Resume from the existing PR without replaying resolved questions.
- **Collaborative pace (every skill and role in this repo):**

<!-- interaction-pace:v1 -->
We reach the result together in small steps, not in one long answer. Each turn opens with a progress marker `step X of ~Y`; when the estimate changes, it names the new total and the reason (`step 3 of ~14, was ~12: two more scenarios needed`). Each turn shows one piece sized to what it carries (usually about one screen) with at most one question or decision, recommendation first. Long content goes into the artifact file; the chat links it and names the one part to check. While working with the user, aim for a reply roughly every 30 seconds. When a step will clearly take longer (tests, research, a sub-agent), first say what runs and roughly how long, and ask any question that step will need before it starts. Never pad: no filler updates and no artificial splitting of a step that cannot be split. Results go to review in reviewable pieces (one decision, section or diff at a time). The user can ask for everything at once. Autonomous work does not pause, but its reports follow the same size rule.
<!-- /interaction-pace:v1 -->

- **Blueprint + routing + scope gate:** a new or materially revised blueprint always pauses for acceptance and execution scope, even in autonomous mode. The user chooses one task, one PR, or all unfinished PRs. A model/effort decision is added only when the selected adapter falls back to inherited configuration.
- **Scope-aware routing:** each task keeps its own `Execution Profile`; the selected scope adds a coordinator-only Scope Profile. A whole feature increases coordination only when dependencies warrant it — it never routes every simple task to a stronger model.
- **Bottleneck-aware effort:** `/ship` diagnoses whether the constraint is retrieval, design judgment, capability, context noise, verification or multiple approaches. Improve context first for retrieval/noise, raise effort by one step only for a reasoning problem, and route to a stronger role or specialist when the task is genuinely outside the current tier. A good verifier can justify a cheaper worker plus another repair loop; repeated effort without a better result stops and escalates. Never invent or silently mutate a native model/effort setting.
- **Per-role model routing:** where the adapter supports a native agent `model` field, bootstrap assigns a static model to each role before it is spawned: strong for architect, plan-reviewer, code-reviewer and security-auditor; mid for coder, perf-auditor and planning-analyst; light for tester and docs-writer. Claude uses its documented tiers; Cursor requires the user's three exact target-native model IDs. OpenCode executes role contracts in the main thread, so it inherits the active session model. `/ship` never invents a provider ID or silently changes the main-session model. Unsupported fields, missing IDs and every role-level effort setting fall back to inherited tool configuration; `inherited` is a limitation, not a model choice. Native adapters preserve unmarked user model overrides; OpenCode has no role-level model record.
- **Closure:** review and security run from independent evidence. Every confirmed security finding must be repaired and re-audited inside the contract; an expansion becomes `awaiting_approval`, never a silent scope change.

## Cost & context discipline
The team already bakes most cost control into its parts (per-task profiles in blueprints; target-native per-role model routing where supported; plan-before-code in `architect`; trivial-task-inline + parallel read-only audits in `ship`; delegate-and-summarize in `coder`). The role map is static for the current bootstrap; `/ship` never invents a provider ID or mutates it mid-run. On top of that, every agent honors:
- **Pointers, not payloads** — hand subagents file paths + the blueprint section, not pasted file bodies; read the slice you need (`offset`/`limit`, the touched function), not whole files "for safety".
- **Load by decision** — start with the task and applicable instructions, then load sources that resolve a concrete uncertainty. Expand to connected callers/schemas when needed; do not repeatedly scan the entire repo or replay a transcript. Keep durable decisions in the blueprint and return evidence pointers plus conclusions. If relevant sources changed, recheck those facts rather than trusting an old summary. Never trim away applicable safety rules or contradictory evidence to make the packet smaller.
- **Keep instruction ownership clear** — repository laws belong in `AGENTS.md`, role behavior in its contract, procedures in skills, and task state in the blueprint. For repeated stale or conflicting instructions, route a targeted correction through `adapt-army`; do not silently rewrite user-owned rules or start a general documentation cleanup.
- **Keep the stable prefix cached** — `AGENTS.md`, `CLAUDE.md` and agent defs stay stable and pointer-shaped (not encyclopedias), so volatile detail loads on demand instead of re-paying tokens every turn.
- **Script, don't prompt, for bulk** — never ask a model to map/filter/transform a large file in chat; write a script and run it locally (~0 tokens). Mechanical checks belong in a hook/script, not a prompt.
- **English + right-sized model** — agent-facing text in English (Polish morphology costs ~1.5× the tokens); prefer a local/open model when it's adequate for routine, low-judgment work.

<!-- agent-army:feedback-router:start -->
## Keeping Agent Army current

In **any conversation**, treat a user correction, repeatable weakness, workflow improvement or missing
specialist as a possible lesson for the Army. First correct the current task inside its approved scope.
Then use `<SKILLS_DIR>/adapt-army/SKILL.md` to classify it as task-local, repo convention, existing agent,
existing skill, deterministic control, new agent or new skill. Ask one durability question only when the
signal is ambiguous.

Never silently mutate the Army. For every durable change present an **Army Improvement Proposal** with
evidence, recommended target, alternatives, planned write scope, verification and one approval question.
Record its normalized status locally in `.agent-army/state.json`; do not store raw user messages or
secrets. A declined proposal stays quiet unless materially new evidence appears.

Core skills in `<SKILLS_DIR>/` are APM-managed and shared across tools. Before proposing a durable
improvement, read the live relevant skill, applicable `AGENTS.md` files and local `<AGENTS_DIR>/` sources.
Put a repo-wide law in `AGENTS.md`, a role responsibility in `<AGENTS_DIR>/`, and a separate user-invoked
workflow in a new `.apm/skills` skill. Never edit a package-managed core skill inside a target repository.
<!-- agent-army:feedback-router:end -->

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
