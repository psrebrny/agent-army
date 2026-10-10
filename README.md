# Agent Army

Agent Army is an [APM](https://microsoft.github.io/apm/) package for creating a
repository-specific team of planner, coder, tester, reviewer, security,
performance and documentation agents.

## Install, then bootstrap

```bash
cd my-repository
apm install psrebrny/agent-army --target opencode
# choose one target: claude | cursor | codex | gemini | copilot | windsurf | opencode
```

Choose the tool that is active for this repository:

| `--target` | Agent delivery |
|---|---|
| `claude` | Native agents through APM; runtime hook adapter available |
| `codex` | Native Codex TOML agents through APM |
| `cursor` | Native Cursor agents through APM |
| `copilot` | Native `.github/agents/*.agent.md` through APM |
| `opencode` | Canonical role contracts in `.agent-army/agents`; main-thread execution via shared skills |
| `gemini` | Agent sources plus a temporary direct Gemini adapter |
| `windsurf` | Role-skills fallback; Windsurf has no native project subagents |

Use one target per repository. To switch tools, explicitly re-run `/bootstrap`
for the new target.

On Claude, `/bootstrap` is normally a slash command. In the other tools,
including OpenCode, open or invoke `.agents/skills/bootstrap/SKILL.md` directly
when the tool does not register the command natively. Use the corresponding
path for `/ship`, `/new-agent`, `/new-skill` and `/adapt-army` too.

The install is intentionally passive: it ships five skills and templates only.
`/bootstrap` is the explicit second step that creates the tailored local role contracts.
For OpenCode, `.agent-army/agents/*.agent` is the only agent artifact: skills read it and
`/ship` executes roles in the main thread. Other targets may use their native APM adapter.

During bootstrap, choose the owner of each layer independently:

| Layer | Choices |
|---|---|
| Runtime hooks | Agent Army, existing user controls, disabled |
| Git pre-commit | Agent Army, existing user controls, disabled |
| CI | Agent Army, existing user controls, disabled |

Existing controls are detected and preserved by default. Agent Army never
rewrites an unmanaged pre-commit hook or workflow. The resulting
`.agent-army/config.json` makes each layer's status explicit: `army`,
`external`, `disabled`, or `blocked`.

## What bootstrap creates

- `.agent-army/agents/agent-army-*.agent` role contracts. OpenCode does not create `.apm/agents`
  or `.opencode/agents` agent files; other native targets may create temporary APM staging and
  native output through `apm install --frozen --target <target>`.
- `.apm/hooks/agent-army-*.json` only when runtime hooks are owned by Agent
  Army and the target supports the adapter.
- `.agent-army/runtime.py` and `.agent-army/config.json`; quality commands are
  structured `cwd` plus `argv`, never shell snippets.
- An owned CI workflow only at `.github/workflows/agent-army-quality.yml`.

OpenCode uses the main-thread role-contract fallback in this profile. Windsurf
receives role-skills fallback because it has no native project subagents. All
other listed targets may receive the full agent roster through APM.

Runtime hooks provide quick deterministic feedback. Agent Army only claims
repository enforcement for chosen, active `army` pre-commit and CI layers;
external layers remain the user's responsibility.

Use `architect` directly when you want discovery and a blueprint only; it never
implements source code. `/ship` resolves and resumes the narrowest unambiguous
task or PR from `design-docs/` (plain `/ship` resumes only when one open scope
exists). Each PR persists its interaction mode, Interaction Card and task state,
so a new session can continue without reconstructing chat history.

Architect assigns each task a portable capability/effort profile. `/ship`
combines it with the selected scope's coordinator profile, while bootstrap maps
roles to the target's native model field where that field is confirmed. The
static defaults are strong for architect/review/security, mid for coder/perf,
and light for tester/docs, so autonomous execution can move between roles
without a model-switch pause. Claude uses its documented tier names; Cursor
receives this routing only after bootstrap is given three real target-native
model IDs. OpenCode uses the main-session model because this profile does not
spawn native subagents. The delivery loop is TDD → independent review/security
→ repairs and re-audit → docs/full verification → ready for human review.

When an architect creates or materially revises a blueprint, `/ship` always
pauses — including in autonomous mode — so the user can review acceptance
criteria and choose one task, one PR or all unfinished PRs before implementation.
For adapters without a configured native model field, every subagent inherits
the active tool/session configuration and `/ship` asks for a manual change only
when the recommendation is material. It never invents a provider/model ID,
changes the main-session setting, or claims that a role-level effort changed:
effort falls back to the tool default unless the adapter explicitly supports it.

`/ship` has two interaction modes per PR. When it asks, it recommends one with a
reason: Interactive when a task still has an open design choice or no runnable check,
otherwise Autonomous; your choice wins. **Autonomous** continues after the
mandatory gate until a real decision, risk, or final human review. **Interactive**
works through small, verifiable outcomes with you. It shows "Step X of approximately
Y", the current action, remaining outcomes and a finish condition. Each selected
task is one milestone; audits, docs and final verification form the closure milestone.
RED and GREEN stay phases of the task, and GREEN still awaits independent review.

Before tests, the agent resolves only real gaps in the required behavior, one question
with a recommendation at a time. Clear requirements lead directly to work. This is
collaboration toward delivery, not tutoring or a quiz. After two exchanges without
new evidence or a decision, it names the obstacle and proposes a resolution or small
experiment. Side ideas stay deferred; a scope change needs your decision and an
explained update to the map.

Interactive pauses after RED (or an approved refactor baseline) and after verified
implementation. A lighter test policy uses implementation acceptance when no RED
exists. One combined Interaction Card shows progress, the decisive assertion and its
expected-result source, the small behavior-focused diff, verification limits and the
next action. Required checks and independent review/security still apply.

"Decide for me" delegates the current in-scope choice. "Do this task yourself" grants
one explicitly bounded task through verification: the agent records the authorization,
waives its routine pre-implementation pause, then returns automatically to interactive
task review. Risk/scope stops and final approval remain. "Switch to autonomous" changes
the PR policy explicitly. Progress, pending questions and temporary delegation persist
in the PR; older PRs derive missing progress from existing task evidence without
restarting. Existing `supervised` PRs still migrate to `interactive` on resume.

## Update an installed Army

```bash
apm update psrebrny/agent-army --target opencode
```

Then run `/bootstrap`. It detects an older profile or changed live package materials, previews a narrow
incremental migration and shows an **Incremental Upgrade Review** before any local specialization changes.
The review compares shared `.agents/skills` and baseline-template hashes with the local inventory, then
asks whether to apply selected recommendations, apply all, inspect details or skip. The migration preserves
repo-specialized `.agent-army/agents`, model routing, quality policy and external controls; it updates only marked
Agent Army fragments. A manually edited marked fragment is reported as a conflict, never overwritten. Use
`/bootstrap --mode full` only when you want to intentionally re-specialize the team or change target.

## Keeping the team current

When you correct an agent or identify a recurring workflow gap, Agent Army first fixes the current task
and then offers an `Army Improvement Proposal`. `/adapt-army` recommends whether the lesson belongs in a
repo convention, an existing agent, a deterministic control, a new agent or a new `/new-skill`. Core skills
stay APM-managed; durable local changes go only to `AGENTS.md`, a local `.agent-army/agents` role, or a distinct
local `.apm/skills` workflow after explicit approval.

## Development

```bash
scripts/check.sh
scripts/smoke.sh
```

Never commit from this repository without human approval.
