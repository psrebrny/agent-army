---
name: ship
description: Resumable SDD executor — resolves a task, PR, feature or small fix from the blueprint, runs strict TDD and repair loops, then returns work ready for human review.
---
# /ship — resumable SDD execution + Testing Trophy + strict TDD

> Token discipline for every step lives in `AGENTS.md` → "Cost & context discipline"
> (cheapest adequate model, pointers not payloads, match the fan-out to task size).
> This pipeline honors the repo's **Project policy** (`.agent-army/config.json`): when the recorded test policy is `none`
> skip the RED-first loop entirely (implement → audit → docs); at `light`/`pragmatic`
> scale the tests down. Security barriers stay on at every level.

## 0 · RESOLVE THE EXECUTION SCOPE
`/ship` is an executor, not the planning agent. It reads `design-docs/**/00_CORE_MANIFEST.md` and
`0*_PR_*.md` first, including every `Execution State`, and resolves the narrowest unambiguous scope:

- explicit task ID → resume or execute that task;
- explicit PR ID/file → execute its unfinished tasks;
- explicit feature/ticket → select its one unfinished PR, or present the candidates and ask;
- a small self-contained description with no blueprint → treat it as one full pipeline scope;
- no argument → resume the single unfinished task or PR only when exactly one exists; when none or
  several exist, present the candidates and ask what to start or resume.

Never select the most recently edited plan merely because it is recent. If no blueprint exists for a
feature/ticket, invoke `architect` to create one, then stop at the mandatory blueprint + routing + scope
gate below. Do not auto-select a task or PR from a new or materially revised blueprint, even when only
one candidate exists. Users may invoke `architect` directly for planning or replanning; it creates/updates
`design-docs/` and never implements source code.

## 1 · EXECUTION POLICY
Read the selected PR's `Execution State`. Interaction is selected **per PR**, never per role or command.
If `Interaction policy` is `unset`, ask once and persist one of two user-visible modes:

- **Autonomous** — after the mandatory blueprint + routing + scope gate, continue through normal stages
  without routine pauses. Stop only for a decision condition below, final human review, or commit approval.
- **Interactive** — after that same gate, work one atomic task at a time and pause with an Interaction Card
  after its RED test and after its GREEN result, before proceeding further.

Never ask the user to choose raw `red`/`green`/`review` checkpoints. The user may say `switch to
autonomous` or `switch to interactive` at any time; persist the new mode immediately and apply it at the
next safe boundary. When resuming a legacy PR with `Interaction policy: supervised`, migrate it once to
`interactive`, remove its `Checkpoints` selection, record `Last verified stage: legacy supervised policy
migrated to interactive`, and continue under the Interactive rules. Do not replay or infer old checkpoints.

At any mode, ask instead of guessing when a requirement is missing, the scope is ambiguous, or a change
needs expanded authority. In both modes, pause with an Interaction Card before an external or irreversible
operation, a security/privacy/compliance decision, a breaking public-contract change, or a scope expansion.
A durable correction, recurring workflow weakness or missing specialist is an occasion to route through
`/adapt-army`. First repair the current task inside scope; then persist and present its separate Army
Improvement Proposal at the next safe boundary. One-off guidance remains only in the selected task/PR.

### INTERACTION CARD
Every pause is durable: write this card into the selected PR file, set `Awaiting decision` to its exact
question, and clear the card only after the user responds. Write the card in the user's language. Never
emit a bare `ok/fix` pause or make the user infer what to inspect.

```md
## Interaction Card
- **Checkpoint:** [blueprint approval | RED acceptance | task review | finding decision | final review | risk decision]
- **Completed:** [what changed or was verified]
- **Evidence:** [test command/result, diff summary, report path/verdict, or decision]
- **Review focus:** [the one to three facts the user should check]
- **Question:** [one concrete, answerable question]
- **Options:** [continue | direct a correction | show details | change scope | switch to autonomous/interactive]
```

For an Interactive RED card, include the contract interpretation, exact RED tests, smallest implementation
plan and planned write scope. For an Interactive task-review card, include the focused diff summary, GREEN
command/result, known limitations, and the next planned task. A finding-decision card names the finding,
its severity, the in-scope repair option, and any decision that needs the user. A final-review card names
the full verification result, review/security verdicts, docs change, and the proposed (not executed) commit.
For a plainly in-scope finding in Autonomous mode, record the same finding-decision card as evidence with
`Question: none` and `Options: none`, then continue the repair immediately. If resolving the finding needs
a decision, it becomes a pause in both modes.

### MANDATORY BLUEPRINT + ROUTING + SCOPE GATE
When `architect` creates or materially revises a blueprint, this gate is mandatory even with
`Interaction policy: autonomous`. Read `.agent-army/config.json` → `model_routing` before returning from
the architect handoff. Persist an Interaction Card for the blueprint decision and:

- `PR status: awaiting_approval`, `Active roles: none`, and `Execution scope: unset`;
- `Scope Profile: unset`, the configured `Model routing`, and `Last manual configuration: unknown` only
  when the adapter falls back to `inherit`;
- `Last verified stage: blueprint path + acceptance criteria reviewed`;
- `Awaiting decision: approve/revise blueprint; select scope` — add `switch and continue/stay current`
  only for an `inherit` fallback whose main-session recommendation is material.

Then show the task's acceptance criteria, verification command, approved write scope, and its Execution
Profile. Ask the user to make these decisions explicitly:

1. Blueprint: `approve and continue` or `request blueprint changes`.
2. Scope: `Task <PR.Task> only`, `PR <ID>`, or `all unfinished PRs for this feature`.
3. Model only for `inherit` fallback: `switch and continue` or `stay current`.

Persist the selected execution scope and the selected `autonomous`/`interactive` policy before dispatching
any tester, coder or main-session implementation.
For `all unfinished PRs`, carry that scope forward to the next unfinished PR only after the current PR
reaches `ready_for_human_review`: Autonomous mode continues after the current final-review card, while
Interactive mode asks in that card whether to proceed to the next PR. Then calculate and persist the Scope
Profile below. Autonomous execution starts after the required decisions. A static role model is already
selected by bootstrap; `/ship` never rewrites an agent file or changes the main-session model/effort during
execution.

Use these execution statuses exactly:
- `planned`, `red`, `implementing`, `green`, `verified`, `review`, `security`, `docs`,
  `ready_for_human_review` for normal progress;
- `awaiting_approval` for a blueprint/scope approval or a precisely described scope expansion;
- `needs_input` for a business/technical decision only the user can provide;
- `blocked` only for an external obstacle that remains after a safe attempt to clarify;
- `done` and `partial` for completed or intentionally incomplete work.

## 1.4 · SCOPE-AWARE ROUTING
Keep two profiles separate:

- **Execution Profile** belongs to each atomic task and determines the cheapest adequate configuration
  for that task's actual work.
- **Scope Profile** belongs to the user-selected scope and determines only coordination burden for the
  main `/ship` session. It must never silently raise every worker to the strongest tier.

Calculate and persist the Scope Profile after scope selection:

| Selected scope | Coordinator recommendation | Worker recommendation |
|---|---|---|
| One task | that task's capability/deliberation; coordination `low` | that task's Execution Profile |
| One PR | highest profile among its unfinished tasks; coordination `low` for one task, otherwise `medium` | each task's own Execution Profile |
| All unfinished PRs | highest profile is used only at cross-PR planning/replanning and final review; coordination `medium`, or `high` only for cross-PR dependencies, migrations, security risk, or an architectural pivot | each task's own Execution Profile |

Show this compactly at the mandatory gate: selected scope, Scope Profile, the next task's profile, and
the next role. A whole feature therefore does not make a `light/low` ping endpoint run on a strong/high
configuration; it only increases the coordinator recommendation when the dependency graph warrants it.

## 1.5 · MODEL & EFFORT ROUTING
Every atomic task has a portable `Execution Profile`: `capability` (`light`, `mid`, `strong`) and
`deliberation` (`none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`). The architect sets the profile from task complexity/risk; it
does not put a vendor model ID in the blueprint. Bootstrap resolves a target-native model-routing record
once in `.agent-army/config.json`; this is configuration, not an LLM decision.

### Per-role static routing (preferred)
When `model_routing.strategy` is `per_role_static`, the native agent definition selects its model before
the agent is spawned. `/ship` dispatches it directly, including in autonomous mode: it does **not** pause
or ask the user to switch at each role boundary. Read `effective_roles` in `model_routing` and record its
configured model and source (`bootstrap` or `user-override`) in that dispatch's Run Configuration.

The portable defaults intentionally distinguish roles:

| Capability | Roles | Purpose |
|---|---|---|
| `strong` | architect, code-reviewer, security-auditor | high-judgment planning and risk decisions |
| `mid` | coder, perf-auditor | implementation or measurement with bounded scope |
| `light` | tester, docs-writer | focused RED/GREEN work or factual documentation |

The task's Execution Profile remains the planner's evidence for scope, coordination and escalation; it
does not silently mutate a static native agent definition mid-run. If a task demonstrably needs a model
above the configured role profile, record a `needs_input` configuration gap at the mandatory gate and ask
for an explicit re-bootstrap with the selected target's real model IDs. Never fake a provider/model ID.

### Inherit fallback
When the adapter has no confirmed model field, or bootstrap lacks all three exact target-native IDs,
`model_routing.strategy` is `inherit`. The subagent uses the tool/session configuration and effort remains
the tool default. `/ship` cannot observe that actual setting and must not claim it changed. Only then, when
a material recommendation differs, pause at the mandatory gate and show:
```
Model & Effort Recommendation
- Scope / role: [task ID / main session or role]
- Recommended: [confirmed model or adapter-defined tier] / [confirmed effort or tool default]
- Why: [task evidence]
- Lower-cost alternative: [profile] — [trade-off]
- Decision needed: switch and continue | stay current
```
The user changes the main-session model/effort in the UI/CLI, then tells `/ship` to continue. If the user
chooses `stay current`, record that explicit decision and proceed. Never change a UI/CLI/API model or
effort setting yourself. Persist it in `Last manual configuration` and Run Configuration; do not ask again
until the selected scope, next task profile, or contract materially changes. `subagent_effort: unsupported`
always means effort inherits the tool default — do not present it as a role-level setting.

`xhigh` and `max` are canonical portable labels where an adapter supports them. `ultra` is not a portable
effort value: preserve it only as an adapter-specific execution mode, separate from deliberation, and never
claim it was selected unless that adapter exposes and records such a mode.

## 1.6 · PERSIST EVERY ROLE TRANSITION
`Execution State` is the resumable source of truth, not the Todo list or a chat message. Immediately
before and after every role dispatch, rewrite the selected PR file: set `PR status`, `Current task`,
`Active roles`, `Last verified stage`, task status, `Awaiting decision`, and any Interaction Card. Never
leave the previous worker listed as active after it returns.

- **Architect:** before → `planned`, active `architect`; after → `awaiting_approval`, active `none`,
  `Execution scope: unset`, `Scope Profile: unset`, blueprint path, and the mandatory blueprint Interaction
  Card.
- **Tester RED:** before → PR `implementing`, task `red`, active `tester`; after → active `none`,
  persist the exact RED command and result. In Interactive mode, write `RED acceptance` Interaction Card
  and wait before production implementation.
- **Implementation:** before → task `implementing`, active `main session` or `coder`; after → retain
  `implementing` until the independent GREEN result is persisted.
- **Tester GREEN:** before → active `tester`; after → task `green` then `verified`, active `none`,
  persist the exact GREEN command and result. In Interactive mode, write `task review` Interaction Card
  and wait before the next task or PR-level audit.
- **Review + security:** before → PR `review`, active `code-reviewer, security-auditor`; after →
  active `none`, persist both verdicts. A confirmed finding writes `finding decision` Interaction Card;
  an in-scope repair then moves the task back to `red`, never directly to coder implementation.
- **Docs + final:** before → PR `docs`, active `docs-writer`; after full verification →
  `ready_for_human_review`, active `none`, task `done`, final evidence and a `final review` Interaction Card.

## 2 · BLUEPRINT OR RESUME  → `architect`
Architect writes `design-docs/[Task-ID]/00_CORE_MANIFEST.md` plus `0X_PR_*.md` (one PR per file) and
never writes production code. Each atomic task has an API contract, a Delegation Contract, an Execution
Profile and an Execution State. On a review escalation, architect updates only affected plan blocks and
the relevant state; it does not silently rewrite completed work.

## 3 · IMPLEMENTATION per task — STRICT TDD `<auto_critic>` with `tester`
_(Applies at `TEST_POLICY=strict`/`pragmatic`. At `light`: thin happy-path tests, no strict RED-first. At `none`: skip this whole step — the main session just implements; lint/security still apply.)_
For EACH task in the blueprint:
1. Persist PR `implementing`, task `red`, `Active roles: tester`, then **`tester` writes the tests (RED)** independently from the contract/acceptance criteria and proves they fail for the right reason. On return, persist `Active roles: none` and the exact RED result.
2. In Interactive mode, write the RED acceptance Interaction Card and wait for its response. In Autonomous mode, continue unless a decision condition applies. Then persist task `implementing` and `Active roles: main session` or `coder`. The main session implements the smallest change; a delegated `coder` receives only the Delegation Contract, RED tests and approved read paths. In Interactive mode the RED card already contains its plan and exact write list; after `continue`, it may proceed only within that list. In Autonomous mode it proceeds only when the list is wholly inside approved scope.
3. Persist `Active roles: tester`; **`tester` verifies (GREEN)**. Set status to `green` only when the command passes, then `verified` after saving the exact GREEN result and `Active roles: none`; otherwise diagnose and fix without weakening assertions. A required path outside scope, ambiguous/disproved contract, unapproved dependency/migration or repeated failed approach becomes `awaiting_approval`, `needs_input` or `blocked`, never silent expansion.
No batching without verification. *Exception:* for trivial tasks the main session may do the whole Red→Green cycle inline, without a round-trip to the subagent (the cheaper default — see AGENTS.md "Cost & context discipline"). This does not remove an Interactive RED or task-review card: it changes only who performs the work. Run the configured verification command after every GREEN step; runtime hooks are feedback, while the user-selected pre-commit/CI controls provide repository enforcement.
After every verified task in Interactive mode, write the task-review Interaction Card and wait. In Autonomous
mode, continue to the next planned task without a routine pause.

## 4 · REVIEW + SECURITY  → independent read-only agents
Persist PR `review` and `Active roles: code-reviewer, security-auditor`, then start a fresh reviewer
context where the tool supports subagents; otherwise invoke the review role with a clean packet. The
packet contains **only** the task contract, finished diff and human decisions. Do not include
coder/tester reports, rationales or transcripts. Audit that packet against standards + business goal; if
the contract is absent, label the result `Diff-Only Review`. Run `security-auditor` independently against
the finished diff at the same time. Neither auditor receives implementation/tester reports or transcripts.

- reviewer `CHANGES_REQUESTED` → `/ship` creates an in-scope Micro-Blueprint and writes a finding-decision
  Interaction Card. A plainly in-scope repair proceeds in Autonomous mode; Interactive mode waits for the
  user's response first. Repair only through RED → coder or main session → GREEN, then re-run both review
  and security;
- reviewer `ARCHITECTURAL_ALIGNMENT_NEEDED` → write a finding-decision Interaction Card, return the issue
  to architect for a targeted correction, then stop at the mandatory blueprint/scope gate; never route this
  verdict directly to coder;
- every confirmed security finding → write a finding-decision Interaction Card. A plainly in-scope repair
  follows RED → coder or main session → GREEN and then re-runs both audits; Interactive mode waits first.
  A finding that needs a new scope becomes `awaiting_approval` with the exact expansion in both modes;
- proceed only after `APPROVED` and zero open confirmed security findings.

After both reports return, persist `Active roles: none` and both verdicts. Repeat this loop until the
selected PR is clean. With no finding, do not add a routine review/security pause; its evidence appears in
the final-review card.

## 5 · DOCS + FINAL VERIFICATION
Persist PR `docs` and `Active roles: docs-writer`; `docs-writer` updates only necessary, truthful docs.
Run the configured full verification, record its output in `Execution State`, set `Active roles: none`,
set the PR to `ready_for_human_review`, and write a final-review Interaction Card. Return a compact summary:
scope, diff, tests, review verdict, security result, actual role configurations and any non-blocking
assumptions. Final review is a pause in both modes: wait for the human response before any commit or merge.
Propose a Conventional Commit but **DO NOT commit without approval**.

The runtime hooks act independently as deterministic feedback. Whether pre-commit and CI are Agent Army barriers, user-owned controls, or disabled is recorded in `.agent-army/config.json`; never claim an external control is owned by this package.
