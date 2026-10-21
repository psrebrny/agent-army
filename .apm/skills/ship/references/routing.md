# /ship reference — scope profile, effort and model routing

Read this file when `/ship` section 1.4–1.6 sends you here: to calculate the Scope Profile after scope
selection, to escalate a task after a failed attempt, when `army.py locate` reports `inherit` or a null
role model, or when a task seems to need a model above its role's configured tier.

## SCOPE-AWARE ROUTING
Keep two profiles separate:

- **Execution Profile** belongs to each atomic task and determines the cheapest adequate configuration
  for that task's actual work.
- **Scope Profile** belongs to the user-selected scope and determines only coordination burden for the
  main `/ship` session, derived from the selected scope and its tasks' bottlenecks, never from a task
  capability. It must never silently raise every worker to the strongest tier.

Calculate and persist the Scope Profile after scope selection:

| Selected scope | Coordinator recommendation | Worker recommendation |
|---|---|---|
| One task | that task's `Bottleneck`; coordination `low` | that task's Execution Profile |
| One PR | the hardest `Bottleneck` among its unfinished tasks; coordination `low` for one task, otherwise `medium` | each task's own Execution Profile |
| All unfinished PRs | the hardest `Bottleneck` matters only at cross-PR planning/replanning and final review; coordination `medium`, or `high` only for cross-PR dependencies, migrations, security risk, or an architectural pivot | each task's own Execution Profile |

Record it in the PR file's `Routing` line, next to the selected scope; at the gate it is shown on
`show details`. A whole feature therefore does not make a `retrieval` ping endpoint run on a stronger
configuration; it only increases coordination when the dependency graph warrants it.

## BOTTLENECK-AWARE EFFORT POLICY
The architect writes each task's `Bottleneck`, `Bottleneck rationale` and `Escalation trigger` (architect
Rule 5). The profile is a recommendation backed by evidence, not a command to use the strongest model or
the highest effort.

| Bottleneck | First move | Escalate when |
|---|---|---|
| `retrieval` | improve pointers, search scope and the clean packet | the missing fact cannot be resolved from approved paths |
| `design_decision` | raise effort by one step of the tool when it supports one, and compare explicit options | the extra effort does not resolve the choice, or the decision changes architecture/scope |
| `capability_gap` | route to the next adequate capability or the proper specialist | the next capability still cannot satisfy the contract |
| `context_noise` | reduce the packet to pointers and relevant slices; usually lower effort | the cleaned packet still leaves a genuine reasoning problem |
| `verification` | strengthen the smallest deterministic test/measurement first | the contract remains unverifiable or a new control needs approval |
| `multiple_approaches` | run bounded independent attempts when safe, then compare | attempts disagree or require expanded scope |
| `unknown` | start with the cheapest adequate profile and gather evidence | the first verified result shows a concrete bottleneck |

Routing rules:

- Prefer the cheapest role capability that is adequate for the contract. Within it, spend effort on
  judgment, not on missing information. `high`, `xhigh` and `max` effort are justified by
  architectural/security decisions, a hard reasoning problem or a failed lower setting — never by task
  size alone.
- Raise effort by at most one step of the tool per retry, when the tool supports it. If that does not
  improve the verified result, stop repeating the same approach: improve context or route to a stronger
  role or specialist. Effort is not a substitute for a missing capability.
- A strong verifier (tests, type-checker, contract or measurement) permits a cheaper worker plus
  another short repair loop. With no reliable verifier, invest in the verification step before buying
  more effort.
- Do not use a whole-feature scope as a reason to raise every task. Scope affects coordination; the
  task bottleneck affects worker routing.
- This policy does not fabricate or mutate a native model/effort setting. With `per_role_static`, use
  the configured role model and record the bottleneck as rationale. With `inherit` or an
  unsupported effort selector, write a `needs_input` configuration gap only when the recommendation is
  material; the user changes the UI/CLI setting and `/ship` resumes at the next safe boundary.

## MODEL & EFFORT ROUTING
An Execution Profile carries no capability, deliberation or vendor model ID, and `/ship` makes no per-task
capability recommendation. Each role is routed from `model_routing` (bootstrap) or the tool default.
Bootstrap records per-tool model tiers once in `.agent-army/config.json`; `army.py locate --tool <tool>`
resolves them into `roles.<role>.model`. This is configuration, not an LLM decision.

### Per-role static routing (`dispatch: subagent-with-prompt`)
Pass the role's model (`model_routing.tools.<tool>.<capability>`, or the contract's own `model:` line,
which wins; `army.py locate` resolves both as `roles.<role>.model`) as the subagent's model. `/ship`
dispatches directly, including in autonomous mode: it does **not** pause or ask the user to switch at each
role boundary. Record the model and its `model_source` (`profile`, `package-default` or `user-override`) in
that task's Run Configuration.

### Main-thread fallback (`dispatch: main-thread`)
Do not try to spawn a worker. Read the role's contract (`army.py role <role>`), execute that role in the
main session, and record it as `Active roles`. The main-session model and effort remain unchanged.

The portable defaults intentionally distinguish roles:

| Capability | Roles | Purpose |
|---|---|---|
| `strong` | architect, plan-reviewer, code-reviewer, security-auditor | high-judgment planning and risk decisions |
| `mid` | coder, perf-auditor, planning-analyst | implementation, bounded research, or measurement |
| `light` | tester, docs-writer | focused RED/GREEN work or factual documentation |

The task's Execution Profile remains the planner's evidence for coordination and escalation; it does not
silently change a role's configured model mid-run. If a task demonstrably needs a model above the
configured role profile, record a `needs_input` configuration gap at the mandatory gate and ask for an
explicit re-bootstrap with that tool's real model IDs (`--tool <tool> --model-…`). Never fake a
provider/model ID.

### Inherit fallback
When `roles.<role>.model` is null (the tool has no per-role model, or bootstrap lacks its three exact
model IDs, or `model_routing.strategy` is `inherit`), the role inherits. The subagent uses the
tool/session configuration and effort remains the tool default. `/ship` cannot observe that actual setting
and must not claim it changed. Only then, when a material recommendation differs, pause at the mandatory
gate and show:
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
effort setting yourself. Persist it as the manual setting in `Routing` and in Run Configuration; do not ask
again until the selected scope, next task profile, or contract materially changes.
`subagent_effort: unsupported` always means effort inherits the tool default — do not present it as a
role-level setting.

`xhigh` and `max` are canonical portable labels where an adapter supports them. `ultra` is not a portable
effort value: preserve it only as an adapter-specific execution mode, separate from effort, and never
claim it was selected unless that adapter exposes and records such a mode.
