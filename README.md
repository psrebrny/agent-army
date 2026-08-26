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
| `opencode` | Native agents through APM; skills via shared `.agents/skills`; no runtime-hook adapter |
| `gemini` | Agent sources plus a temporary direct Gemini adapter |
| `windsurf` | Role-skills fallback; Windsurf has no native project subagents |

Use one target per repository. To switch tools, explicitly re-run `/bootstrap`
for the new target.

On Claude, `/bootstrap` is normally a slash command. In the other tools,
including OpenCode, open or invoke `.agents/skills/bootstrap/SKILL.md` directly
when the tool does not register the command natively. Use the corresponding
path for `/ship`, `/new-agent` and `/adapt-army` too.

The install is intentionally passive: it ships four skills and templates only.
`/bootstrap` is the explicit second step that creates the tailored local APM
agent sources and lets APM render the selected target's native agent format.
The `.apm/agents` files remain the authoring source after rendering; do not
delete them just because equivalent native files exist under `.opencode/agents`.

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

- `.apm/agents/agent-army-*.agent.md`, then native target files through
  `apm install --frozen --target <target>`.
- `.apm/hooks/agent-army-*.json` only when runtime hooks are owned by Agent
  Army and the target supports the adapter.
- `.agent-army/runtime.py` and `.agent-army/config.json`; quality commands are
  structured `cwd` plus `argv`, never shell snippets.
- An owned CI workflow only at `.github/workflows/agent-army-quality.yml`.

OpenCode has native agents but no runtime-hook adapter. Windsurf receives
role-skills fallback because it has no native project subagents. All other
listed targets receive the full agent roster through APM.

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
without a model-switch pause. Claude uses its documented tier names; Cursor and
OpenCode receive this routing only after bootstrap is given three real
target-native model IDs. The delivery loop is TDD → independent review/security
→ repairs and re-audit → docs/full verification → ready for human review.

When an architect creates or materially revises a blueprint, `/ship` always
pauses — including in autonomous mode — so the user can review acceptance
criteria and choose one task, one PR or all unfinished PRs before implementation.
For adapters without a configured native model field, every subagent inherits
the active tool/session configuration and `/ship` asks for a manual change only
when the recommendation is material. It never invents a provider/model ID,
changes the main-session setting, or claims that a role-level effort changed:
effort falls back to the tool default unless the adapter explicitly supports it.

`/ship` has two interaction modes per PR. **Autonomous** continues after that
mandatory gate until a real decision, risk, or final human review. **Interactive**
also pauses after each RED test and each verified task. Every pause is an
Interaction Card in the blueprint: completed work, evidence, what to check, one
question, and choices to continue, redirect, inspect details, change scope, or
switch mode. Existing `supervised` PRs migrate to `interactive` when resumed.

## Development

```bash
scripts/check.sh
scripts/smoke.sh
```

Never commit from this repository without human approval.
