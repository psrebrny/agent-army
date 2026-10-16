# Agent Army

Agent Army is an [APM](https://microsoft.github.io/apm/) package for creating a
repository-specific team of planner, coder, tester, reviewer, security,
performance and documentation agents.

## Install once, bootstrap per repository

The skills are generic, so install them once for your user. Every repository you open
then has `/ship`, `/product`, `/bootstrap` and the rest:

```bash
apm install -g psrebrny/agent-army --target claude   # user scope; or claude | cursor | codex | gemini | copilot | windsurf | opencode
```

A per-repository install (`apm install psrebrny/agent-army --target <tool>` in the repo) works the same.
In Claude Code a personal skill wins over a project skill with the same name. That is harmless here:
all repo knowledge lives in the repository, not in the skills.

In the repository, run `/bootstrap` once. It writes **one profile for every tool**:

- `.agent-army/agents/agent-army-*.agent`: the role contracts, specialized to this codebase;
- `.agent-army/config.json`: per-tool model routing, quality commands and control ownership.

There is no target and no native agent copy (`.claude/agents`, `.codex/agents`, …). When you call a
skill, it reads `.agent-army/` from the git root of the directory you invoked it in. The deterministic
helper `bootstrap/army.py locate` does the same. The skill then runs each role from its contract: as a
subagent with the role's model in Claude Code, or in the main session in tools without such a call. A
repository without a profile still works on the package's baseline roles, and the skills recommend
`/bootstrap`.

You decide whether the profile is part of the repository (`--visibility`):

| Visibility | Effect |
|---|---|
| `committed` | shared and reviewed like code; only `.agent-army/state.json` is ignored |
| `gitignore` | `.agent-army/` is added to `.gitignore` |
| `exclude` | `.agent-army/` is added to `.git/info/exclude`, private to your clone |

An Agent Army-owned CI needs a committed profile, so with `gitignore`/`exclude` it is reported as `blocked`.

In tools without slash commands, invoke the skill file directly (`<skills dir>/bootstrap/SKILL.md`, and the
same for `/ship`, `/new-agent`, `/new-skill`, `/adapt-army` and the product skills).
The product skills need no bootstrap: they work in any repository.

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

- `.agent-army/agents/agent-army-*.agent` role contracts: the only copy, read by the skills in every tool.
- `.agent-army/runtime.py` and `.agent-army/config.json`; quality commands are
  structured `cwd` plus `argv`, never shell snippets.
- `.apm/hooks/agent-army-*.json` only when runtime hooks are owned by Agent Army; with
  `--tool <tool>` they are rendered for that tool through APM (the only tool-specific step).
- An owned CI workflow only at `.github/workflows/agent-army-quality.yml`.
- The visibility entry in `.gitignore` or `.git/info/exclude`.

Runtime hooks provide quick deterministic feedback. Agent Army only claims
repository enforcement for chosen, active `army` pre-commit and CI layers;
external layers remain the user's responsibility.

Use `architect` directly when you want discovery and a blueprint only; it never
implements source code. `/ship` resolves and resumes the narrowest unambiguous
task or PR from `design-docs/` (plain `/ship` resumes only when one open scope
exists). Each PR persists its interaction mode, Interaction Card and task state,
so a new session can continue without reconstructing chat history.

Architect gives each task an Execution Profile: its reasoning `Bottleneck`, the
rationale and an escalation trigger. `/ship` derives the coordinator profile for
the selected scope from those bottlenecks and escalates from them, while each
role's model comes from the per-tool routing bootstrap records, applied when the skill dispatches
the role (otherwise the tool default). The
static defaults are strong for architect/review/security, mid for coder/perf,
and light for tester/docs, so autonomous execution can move between roles
without a model-switch pause. Claude uses its documented tier names by default; another tool
with a per-call subagent model gets routing only after bootstrap receives three real model IDs
for it (`--tool <tool> --model-light … --model-mid … --model-strong …`). Tools that run roles in the
main session use the main-session model. The delivery loop is TDD → independent review/security
→ repairs and re-audit → docs/full verification → ready for human review.

When an architect creates or materially revises a blueprint, `/ship` always
pauses — including in autonomous mode — so the user can review acceptance
criteria and choose one task, one PR or all unfinished PRs before implementation.
For tools without a configured per-role model, every role inherits
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

Interactive pauses so you keep the thread and can steer, not to tick off steps. Each
task opens with a two- or three-line plan that waits only when it has a question; tests,
implementation and verification then run without a pause, and one task review follows.
It shows progress, the decisive assertion and its expected-result source, the small
behavior-focused diff, verification limits and the next action. After a break it opens
with one sentence on where the work stands. Required checks and independent review/security still apply.

"Decide for me" delegates the current in-scope choice. "Do this task yourself" grants
one explicitly bounded task through verification: the agent records the authorization,
settles that task's in-scope choices itself, then returns automatically to interactive
task review. Risk/scope stops and final approval remain. "Switch to autonomous" changes
the PR policy explicitly. Progress, pending questions and temporary delegation persist
in the PR; older PRs derive missing progress from existing task evidence without
restarting. Existing `supervised` PRs still migrate to `interactive` on resume.

## The 19 skills

Every skill is optional and callable on its own; none runs another. Not sure where to start with a
product? Run `/product`. The full catalog, with inputs, outputs, examples and what reaches `/ship`, is
[`.apm/README.md`](.apm/README.md).

| Skill | Use it for |
|---|---|
| `/bootstrap` | tailor the agent team and control ownership to this repository |
| `/ship` | execute or resume agreed engineering work up to human review |
| `/new-agent` | add a specialised local role |
| `/new-skill` | add a reusable local workflow |
| `/adapt-army` | turn a recurring workflow problem into a targeted improvement |
| `/product` | where am I on the 12-stage product journey, and the one next step |
| `/product-strategy` | audience, problem, advantage, features, revenue model, out of scope |
| `/product-red-team` | attack a plan: "Fails if …", cheapest test, kill criterion |
| `/market-research` | competitors, alternatives and prices with dated sources |
| `/business-case` | costs, scenarios, break-even and pricing you can recheck |
| `/validate-product` | falsifiable experiments and reading their results, incl. post-launch churn |
| `/product-spec` | MVP goal, stories with acceptance and priority |
| `/solution-architecture` | architecture style and stack per layer, recorded as ADRs |
| `/delivery-plan` | walking skeleton and vertical slices as work items for `/ship` |
| `/go-to-market` | channels as written predictions with budget caps |
| `/product-metrics` | decision questions, events, collection checks, honest reads |
| `/ux-review` | heuristic review of the paths that matter |
| `/legal-review` | applicability, dated sources, lawyer and accountant questions |
| `/launch-readiness` | launch verdict per area with evidence |

Product skills write conversation results to `docs/product/` and decisions to `docs/adr/` by default;
`.agent-army/stores.json` can bind a record type to a connected tool instead. They never write product
code: anything that becomes code is a work item you hand to `/ship`.

## Update an installed Army

```bash
apm update -g psrebrny/agent-army    # or without -g for a per-repository install
```

Then run `/bootstrap` in each repository. It detects an older profile or changed package material, previews
a narrow incremental migration, and shows an **Incremental Upgrade Review** before it changes any local
specialization. The review compares the package's skill and baseline-template hashes with the profile's
inventory. You can then apply selected recommendations, apply all, inspect details or skip. The migration
preserves the repo-specialized `.agent-army/agents`, model routing, quality policy and external controls, and
updates only marked Agent Army fragments. A manually edited marked fragment is reported as a conflict and
never overwritten. Use `/bootstrap --mode full` only when you intend to re-specialize the team.

Upgrading a 0.3/0.4 profile to 0.5 also deletes the native role copies those versions rendered, but only
where a copy is identical to its contract: `.claude/agents/agent-army-*.md`, `.codex/agents/…`,
`.github/agents/…`, `.cursor/agents/…`, `.gemini/agents/…`, `.windsurf/skills/agent-army-*` and `.apm/agents`
staging. It also moves generated `model:` lines from the contracts into the profile. An edited copy is kept
and listed as a conflict.

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
