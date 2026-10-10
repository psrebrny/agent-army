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

For new planning, the main session coordinates the planning roles; do not ask an architect subagent to spawn
its own workers. Invoke `planning-analyst` only when a material cause, behavior, source conflict, or repository
constraint is still unknown. A small and clear task may skip it; record the evidence-based reason in
`Planning Session`. Keep the architect as the single user-facing plan author: relay its one-at-a-time question
to the user, save the answer in the blueprint, and return the affected excerpt rather than a full plan dump.
After the architect composes a blueprint, invoke `plan-reviewer` with a fresh, independent context. Its packet
contains the approved goal, confirmed decisions, exact manifest/PR revision, and relevant raw source paths;
exclude the architect transcript/self-review and analyst report. Persist the verdict and revision in
`Planning Session`. If no independent context can be created, record `INSUFFICIENT_EVIDENCE` and stop at the
blueprint gate unless the user explicitly chooses to proceed with that limitation. A review verdict never
authorizes implementation.

## 1 · EXECUTION POLICY
Read the selected PR's `Execution State`. Interaction is selected **per PR**, never per role or command.
If `Interaction policy` is `unset`, ask once and persist one of two user-visible modes:

- **Autonomous** — after the mandatory blueprint + routing + scope gate, continue through normal stages
  without routine pauses. Stop only for a decision condition below, final human review, or commit approval.
- **Interactive** — after that same gate, work one atomic task at a time together with the user. Pauses
  exist so the user keeps the thread and can steer, not to tick off steps: before a task, show its
  `task plan` and wait only when it carries a question or something unexpected; then run RED,
  implementation and GREEN without a routine pause; after the verified result, pause once at `task review`.
  A recorded one-task delegation below lets the main session settle the task's in-scope choices itself; it
  never waives task review.

When asking, give one recommendation with a one-line reason. Recommend **Interactive** if any selected task has `Bottleneck` `design_decision | multiple_approaches | unknown`, or a Verification Command that is not runnable (a manual evaluation such as scorecard rows does not count), and name those tasks. Otherwise recommend **Autonomous**. The user decides: the recommendation never sets the mode, adds no pause and is not repeated after the choice. In Interactive mode, once every remaining selected task would earn the Autonomous recommendation, the task-review card's `Review focus` says "remaining tasks qualify for autonomous"; the existing `switch to autonomous` option does the rest.

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

### DELIVERY-FOCUSED INTERACTION
<!-- interaction-pace:v1 -->
We reach the result together in small steps, not in one long answer. Each turn opens with a progress marker `step X of ~Y`; when the estimate changes, it names the new total and the reason (`step 3 of ~14, was ~12: two more scenarios needed`). Each turn shows one piece sized to what it carries (usually about one screen) with at most one question or decision, recommendation first. Long content goes into the artifact file; the chat links it and names the one part to check. While working with the user, aim for a reply roughly every 30 seconds. When a step will clearly take longer (tests, research, a sub-agent), first say what runs and roughly how long, and ask any question that step will need before it starts. Never pad: no filler updates and no artificial splitting of a step that cannot be split. Results go to review in reviewable pieces (one decision, section or diff at a time). The user can ask for everything at once. Autonomous work does not pause, but its reports follow the same size rule.
<!-- /interaction-pace:v1 -->
This paragraph governs the size and rhythm of every turn of `/ship` and of each role it runs, including
`architect`; the progress line and the architect's progress card below use its `step X of ~Y` marker. Every reply
opens with it, not only a card: a short answer, a refusal and an "everything at once" reply too.

After scope approval, initialize `Execution Progress` using the architect's PR template. Show the selected
scope and goal, a short outcome map, the current milestone and approximate total, and the finish condition.
Use one milestone per selected atomic task plus one explicit closure milestone for audits, documentation
and final verification. Count the selected tasks in the current PR, retaining earlier milestones on resume;
for a multi-PR scope also show the current PR and remaining PRs from the existing scope, then clearly announce
the next PR's map. RED, implementation and GREEN are phases within a milestone, not extra milestones.

At each interactive exchange show a compact progress line in the user's language, together with the
existing Interaction Card when pausing: current step, verified work, current action, remaining outcomes
and finish condition. Link to detailed diffs and results instead of dumping reports or repeating the whole
plan. Label a GREEN task as verified and awaiting audit, not fully complete; `Task status` and the evidence
in `Execution State` remain authoritative. A card's progress line is a view, not separately maintained state.

Before each task, the first one included, show its `task plan` in two or three lines: behavior, significant cases, verification and exact write list.
When nothing is open and the write list is inside approved scope, show it and continue; it is a heads-up, not
an approval step. It waits only when it carries a question: a missing requirement, trade-off, scope choice or
interpretation that would change the work, or something unexpected such as a needed write outside scope. Read
discoverable facts and reuse confirmed decisions first. Ask one concrete question with a recommendation and
consequences, with `needs_input` and task `awaiting decision`. A gap found later, mid-task, is a
`behavior decision` with the same shape. During the task the chat shows only `step X of ~Y` and what changed;
RED/GREEN evidence and statuses go to the PR file. After resolution restore the appropriate execution stage without discarding prior evidence. This is delivery, not tutoring: never
quiz the user, ask syntax questions, or make them rediscover an answer already supported by the contract.
- On "I don't know", explain the relevant consequence and recommend a resolution, without guided guessing.
- On "decide for me", make the current in-scope choice and record its rationale; do not waive checkpoints.
- After two consecutive exchanges on the same question without a new decision or evidence, name the
  obstacle and propose a concrete resolution or the smallest in-scope experiment. Persist the unresolved
  question and this no-progress count in the card's `Discussion` field so resumption does not restart the
  loop. Reset the count on new evidence/decision. Never infer required approval from silence or the count.
- Save each resolved choice in the affected task contract/evidence before clearing its card, then act on it.
  Send the tester that settled behavior and acceptance criteria, not an implementation-derived expected value.
- Put side ideas in `Deferred ideas`; they do not change the execution scope. When finish criteria are met,
  return the final review result rather than opening another round of improvements.

### EXECUTION PROGRESS AND RESUME
Persist the outcome map, current milestone, finish condition, last map-change reason and deferred ideas
in the existing PR file. Reuse task IDs and the canonical task statuses; never create another status list.
On resume, read `Execution State`, task decisions/evidence, the pending card, progress and any temporary
delegation before acting. If progress is absent in an older PR, derive it from the selected tasks and actual
evidence, preserving already verified work and pending approvals. Initialize a missing temporary delegation
to `none`. Missing evidence stays unknown: inspect or rerun the relevant check without replaying decisions.
When the user returns after a break, open with one sentence on where the work stands (task, last verified
result, the pending question or next step) before anything else. A PR paused at a legacy `RED acceptance`, `baseline acceptance` or `implementation acceptance` card resumes as `task plan`, keeping its saved tests,
baseline and write list. Its saved `Awaiting decision` is still open: show that card once and wait; a request
to "resume" is not its answer. The user's response continues to implementation.
When a simple inline task has no PR file, keep the same compact state in the conversation; do not create a
blueprint solely for a progress counter or claim file-backed resumption where none exists.

Explain each material map change. A repair returns to its existing task milestone and invalidates affected
verification/review evidence; it does not create a new milestone for every attempt. New or removed outcomes
change the estimate only after the required scope decision; proposals stay deferred until accepted. Show
why the end moved, without promising a duration or number of messages. Closure is verified only after all
required audits, documentation and checks for the selected scope, ending at `ready_for_human_review`.

### ONE-TASK DELEGATION
"Do this part yourself" authorizes autonomous execution only for the current, unambiguous approved task
through verification. If "part" is ambiguous, clarify the task boundary first. Keep `Interaction policy:
interactive`; record `Temporary delegation` in `Execution State` with the task ID, the user's authorization,
approved write scope and return point (`task review`). Include this authorization in a delegated coder's
packet; the coder returns to `/ship` for verification/interactive review rather than owning the dialogue.
It is a bounded exception, not a third mode.

Within that task, preserve the usual RED/baseline evidence and the plan/write list, but settle the task's
in-scope choices yourself with a recorded rationale instead of waiting at `task plan` or `behavior decision`.
At verified completion clear the exception
before presenting `task review` and wait. It never grants permission to start the next task, skip checks,
change scope, cross a risk boundary, or bypass blueprint/final review/commit approval. Ordinary required
stops still apply. Cancel the exception on user revocation, explicit mode switch, or a scope/risk/contract
stop; save the stop reason and do not silently reinstate it. A normal verification failure permits in-scope
repair under the existing stop rules, not unbounded retries. On resume, honor only a saved authorization
for the same still-active task; expire it when that task is verified or the boundary no longer matches.

### INTERACTION CARD
Every pause is durable: write this card into the selected PR file, set `Awaiting decision` to its exact
question, and clear the card only after the user responds. Write the card in the user's language. Never
emit a bare `ok/fix` pause or make the user infer what to inspect.

```md
## Interaction Card
- **Checkpoint:** [blueprint approval | task plan | behavior decision | task review | finding decision | final review | risk decision]
- **Progress:** [step X of approximately Y; current action; remaining outcomes; finish condition, or not yet scoped]
- **Completed:** [what changed or was verified]
- **Evidence:** [test command/result, diff summary, report path/verdict, or decision]
- **Review focus:** [the one to three facts the user should check]
- **Question:** [one concrete, answerable question]
- **Options:** [continue | direct a correction | show details | decide this choice | delegate this task | change scope | switch to autonomous/interactive]
- **Discussion:** [current unresolved topic; consecutive exchanges without new decision/evidence: 0/1/2; or none]
```

A `task plan` that waits names the behavior, significant cases, verification and exact write list, then its
one question with a recommendation; a plan without a question is shown and not persisted as a pause. For an
Interactive task-review card, include the decisive RED assertion and its failure reason (or the passing
baseline for a refactor), the focused diff summary, GREEN command/result, known limitations, and the next
planned task, in about one screen. Group the diff by the behavior just delivered,
with file/line pointers and the important implementation decisions. Explain what the check cannot establish.
For `behavior decision`, include the unknown, recommendation and consequence; do not pause when all are settled.
A finding-decision card names the finding,
its severity, the in-scope repair option, and any decision that needs the user. A final-review card names
the full verification result, review/security verdicts, docs change, and the proposed (not executed) commit.
For a plainly in-scope finding in Autonomous mode, record the same finding-decision card as evidence with
`Question: none` and `Options: none`, then continue the repair immediately. If resolving the finding needs
a decision, it becomes a pause in both modes.

For an explicitly approved behavior-preserving refactor, the `task plan` names the preserved contract,
refactor checkpoint/recovery and exact write list, and the task review shows the passing before-change checks;
do not call a passing baseline RED.

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

Before presenting the gate, verify that `Planning Session.Stage` is `ready`, the review applies to the current
`Plan revision`, and there are no unresolved blocking review findings. If the review is missing, stale or
`INSUFFICIENT_EVIDENCE`, disclose the exact limitation and ask for an explicit decision to pause for independent
review or proceed with that limitation. Never change the review verdict to `APPROVED` on the user's behalf.

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

The task's user-visible `Task status` in its PR file uses this single planning vocabulary (canonical
English tokens, whatever the conversation language): `open`, `in progress`, `in testing`, `in review`,
`done`, `awaiting decision`, `blocked`, `conditional`. Map execution transitions as follows: `planned` →
`open`; tester authoring and implementation → `in progress`; implementation complete and verification
pending → `in testing`; GREEN complete and review pending/in progress → `in review`; all task criteria,
required reviews, documentation and checks verified → `done`; `awaiting_approval` or `needs_input` →
`awaiting decision`; `blocked` → `blocked`; out-of-scope until a stated condition → `conditional`. Record
exact RED/GREEN command results and reviewer verdicts in `Last verified stage` or the task evidence, not as a
second status. A role's Handoff `STATUS: done` alone never marks a blueprint task `done`.
A blueprint written before 0.4.0 may carry the legacy Polish statuses. Accept the legacy value on read, mapped one-to-one (`do zrobienia` → `open`, `w trakcie` → `in progress`, `do testów` → `in testing`, `do review` → `in review`, `wykonane` → `done`, `czeka na decyzję` → `awaiting decision`, `zablokowane` → `blocked`, `warunkowe` → `conditional`), and write the English value on the next update of that task. Ignore `Capability`, `Deliberation` and `Routing rationale` lines in a legacy Execution Profile.

## 1.4 · SCOPE-AWARE ROUTING
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

Show this compactly at the mandatory gate: selected scope, Scope Profile, the next task's profile, and
the next role. A whole feature therefore does not make a `retrieval` ping endpoint run on a stronger
configuration; it only increases coordination when the dependency graph warrants it.

## 1.5 · BOTTLENECK-AWARE EFFORT POLICY
The `Execution Profile` is a recommendation backed by evidence, not a command to blindly use the
strongest model or the highest effort. Before the first dispatch for a task, identify one dominant
reasoning bottleneck and persist it in the task block as `Bottleneck`, `Bottleneck rationale` and
`Escalation trigger`. Use these labels:

| Bottleneck | First move | Escalate when |
|---|---|---|
| `retrieval` — a file, API, convention or fact is unknown | improve pointers, search scope and the clean packet | the missing fact cannot be resolved from approved paths |
| `design_decision` — several valid designs or a non-trivial trade-off | raise effort by one step of the tool when it supports one, and compare explicit options | the extra effort does not resolve the choice, or the decision changes architecture/scope |
| `capability_gap` — the task is outside the selected role/tier's demonstrated ability | route to the next adequate capability or the proper specialist | the next capability still cannot satisfy the contract |
| `context_noise` — the packet is large or contains distractors | reduce the packet to pointers and relevant slices; usually lower effort | the cleaned packet still leaves a genuine reasoning problem |
| `verification` — the result cannot be checked reliably | strengthen the smallest deterministic test/measurement first | the contract remains unverifiable or a new control needs approval |
| `multiple_approaches` — independent strategies are plausible | run bounded independent attempts when safe, then compare | attempts disagree or require expanded scope |
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

The escalation ladder is therefore: clean/retrieve context → adjust one effort step for a reasoning
problem → route to a stronger role capability or specialist → ask for a decision/scope change. Never spend
unbounded effort on retrieval, context noise or a repeated failed approach.

## 1.6 · MODEL & EFFORT ROUTING
Every atomic task has an `Execution Profile`: `Bottleneck`, `Bottleneck rationale` and `Escalation
trigger`. It carries no capability, deliberation or vendor model ID, and `/ship` makes no per-task
capability recommendation. Each role is routed from `model_routing` (bootstrap) or the tool default.
Bootstrap resolves a target-native model-routing record once in `.agent-army/config.json`; this is
configuration, not an LLM decision.

### Per-role static routing (preferred for native adapters)
When `model_routing.strategy` is `per_role_static`, the native agent definition selects its model before
the agent is spawned. `/ship` dispatches it directly, including in autonomous mode: it does **not** pause
or ask the user to switch at each role boundary. Read `effective_roles` in `model_routing` and record its
configured model and source (`bootstrap` or `user-override`) in that dispatch's Run Configuration.

### Main-thread fallback
When the active adapter reports `capabilities.subagents: false` — including OpenCode in this profile —
do not look for native agent files or try to spawn a worker. Read the relevant contract from
`.agent-army/agents/agent-army-<role>.agent`, execute that role in the main session, and record the
role as `Active roles`. The main-session model and effort remain unchanged; `model_routing` is `inherit`.

The portable defaults intentionally distinguish roles:

| Capability | Roles | Purpose |
|---|---|---|
| `strong` | architect, plan-reviewer, code-reviewer, security-auditor | high-judgment planning and risk decisions |
| `mid` | coder, perf-auditor, planning-analyst | implementation, bounded research, or measurement |
| `light` | tester, docs-writer | focused RED/GREEN work or factual documentation |

The task's Execution Profile remains the planner's evidence for coordination and escalation; it
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
effort value: preserve it only as an adapter-specific execution mode, separate from effort, and never
claim it was selected unless that adapter exposes and records such a mode.

## 1.7 · PERSIST EVERY ROLE TRANSITION
`Execution State` is the resumable source of truth, not the Todo list or a chat message. Immediately
before and after every role dispatch, rewrite the selected PR file: set `PR status`, `Current task`,
`Active roles`, `Last verified stage`, the mapped user-visible task status, `Awaiting decision`, and any
Interaction Card. Never leave the previous worker listed as active after it returns. Keep detailed execution
evidence in `Last verified stage` and test/review reports; do not replace the task's planning status with
the English execution-step label. Update the progress pointer from this evidence, without a second completion ledger.
Whenever a PR's status changes (first dispatch, `awaiting_approval`, `blocked`, `ready_for_human_review`), also
refresh the manifest's Planning Session `Progress` (each PR's status in one line) and `Next action` (the one next
step) in the same write, so the blueprint entry point never shows an older state than its PR files; touch no
other manifest field.

- **Architect:** before → `planned`, active `architect`; after → `awaiting_approval`, active `none`,
  `Execution scope: unset`, `Scope Profile: unset`, blueprint path, current Planning Session stage/revision,
  review verdict/revision, and the mandatory blueprint Interaction Card. New plan tasks remain `open`.
- **Planning analyst:** before → active `planning-analyst`, task status unchanged; after → active `none`,
  save evidence pointers and the Handoff result for the architect. Never persist an unverified analyst claim as a user decision.
- **Plan reviewer:** before → active `plan-reviewer`, `Planning Session.Stage: review`; after → active `none`,
  persist verdict and exact reviewed revision. If the plan changes materially, update the revision and mark this result stale.
- **Tester RED:** before → PR `implementing`, task `in progress`, active `tester`; after → active `none`,
  persist the exact RED command and result and continue to implementation in both modes; the task remains
  `in progress`. A RED that fails for the wrong reason or disproves the contract is a `behavior decision`.
- **Tester refactor baseline:** for an approved behavior-preserving task, before → PR `implementing`,
  task `in progress`, active `tester`; after → active `none`, persist the actual passing baseline.
  Do not move to `in testing` until the refactor is implemented.
- **Implementation:** before → task `in progress`, active `main session` or `coder`; after implementation →
  task `in testing`, active `none`, and record the exact next verification.
- **Tester GREEN:** before → active `tester`, task `in testing`; after a passing result → task `in review`,
  active `none`, persist the exact command and result. On failure, return to `in progress` with the failure
  evidence and next corrective action. On verified completion clear any one-task delegation. In Interactive mode, write `task review` Interaction Card and wait.
- **Review + security:** before → PR `review`, active `code-reviewer, security-auditor`; after →
  active `none`, persist both verdicts. Keep `in review` until both required reviews pass; a confirmed
  finding writes `finding decision` Interaction Card, then moves to `in progress` for an in-scope repair and
  back to `in testing` before renewed review. Never skip the test status.
- **Docs + final:** before → PR `docs`, active `docs-writer`; after full verification →
  `ready_for_human_review`, active `none`, task `done`, final evidence and a `final review` Interaction Card.

## 2 · BLUEPRINT OR RESUME  → `architect`
Architect writes `design-docs/[Task-ID]/00_CORE_MANIFEST.md` plus `0X_PR_*.md` (one PR per file) and
never writes production code. Each atomic task has an API contract, a Delegation Contract, an Execution
Profile and an Execution State. On a review escalation, architect updates only affected plan blocks and
the relevant state; it does not silently rewrite completed work.
For a new blueprint, use the interactive Planning Session and planning-role orchestration from section 0.
For a resumed blueprint, read its saved Planning Session first and continue at `Next action`; never restart
resolved decisions. Every task starts as `open`. If a user decision is pending, set the task to
`awaiting decision` only when the decision blocks that task, preserve the exact question in the Interaction Card,
and leave unrelated task statuses unchanged.
If the architect finds that the goal is already met or recommends no implementation, return that finding
and its evidence to the user without inventing a PR, selecting work, or activating a suggested service.
A proposed configuration/adoption change still needs a concrete approved scope before execution.

## 3 · IMPLEMENTATION per task — STRICT TDD `<auto_critic>` with `tester`
_(The RED-first loop applies at `TEST_POLICY=strict`/`pragmatic`. At `light`: thin happy-path tests, no strict RED-first. At `none`: no authored tests; implement and check acceptance behavior, with required lint/security still active. The interaction and progress rules apply at every policy.)_
For EACH task in the blueprint, first show its `task plan` and resolve only genuine behavior gaps as above.
At `light`/`none`, when no RED or baseline exists, the `task plan` names the proposed check, smallest
implementation plan and write list before coding. After implementation,
record the actual policy-appropriate verification and, in Interactive mode, pause at task review, without inventing RED/GREEN
evidence for a test that was not run.
Use the tester's risk-based selection and test-confidence guidance. Required repository checks remain
mandatory; additional fault checks are targeted experiments, not a new gate for every task. Run mutations
only in the tester's permitted isolated subject; never pass a mutated failure off as final verification.
For an explicitly approved behavior-preserving refactor, substitute its passing before-change checks
for RED in steps 1–2, preserving the same write-scope and interaction gates.
This exception does not let a bugfix or new feature claim success without demonstrating the required behavior.
1. Persist PR `implementing`, task `in progress`, `Active roles: tester`, then **`tester` writes the tests (RED)** independently from the contract/acceptance criteria and proves they fail for the right reason. On return, persist `Active roles: none` and the exact RED result in `Last verified stage`; task status remains `in progress` while implementation is pending.
2. Continue in both modes unless a decision condition applies. Persist task `in progress` and `Active roles: main session` or `coder`. The main session implements the smallest change; a delegated `coder` receives only the Delegation Contract, RED tests and approved read paths. It proceeds only within the `task plan` write list, and only when that list is wholly inside approved scope; anything else is a stop.
3. After implementation, persist task `in testing`, `Active roles: tester` and the exact next command; **`tester` verifies (GREEN)**. A passing command moves the task to `in review` only after the GREEN result is saved. On failure, persist `in progress` with the failure evidence and correction. A required path outside scope, ambiguous/disproved contract, unapproved dependency/migration or repeated failed approach becomes `awaiting decision` or `blocked`, never silent expansion.
No batching without verification. *Exception:* for trivial tasks the main session may do the whole Red→Green cycle inline, without a round-trip to the subagent (the cheaper default — see AGENTS.md "Cost & context discipline"). This does not remove an Interactive `task plan` or task-review card: it changes only who performs the work. Run the configured verification command after every GREEN step; runtime hooks are feedback, while the user-selected pre-commit/CI controls provide repository enforcement.
After every verified task in Interactive mode, clear any one-task delegation, write the task-review Interaction Card and wait. In Autonomous
mode, continue to the next planned task without a routine pause.

## 4 · REVIEW + SECURITY  → independent read-only agents
Persist PR `review` and `Active roles: code-reviewer, security-auditor`, then start a fresh reviewer
context where the tool supports subagents; otherwise invoke the review role with a clean packet. The
packet contains **only** the task contract, finished diff and human decisions. Do not include
coder/tester reports, rationales or transcripts. Audit that packet against standards + business goal; if
the contract is absent, label the result `Diff-Only Review`. Run `security-auditor` independently against
the finished diff at the same time. Neither auditor receives implementation/tester reports or transcripts.
The change scope includes relevant committed, staged, unstaged and untracked files; provide the comparison
base and source pointers so a branch-only diff cannot hide current changes. Authoritative schemas and
contract indices are source context, not implementation reports. Keep the packet focused on affected boundaries.

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
Before the task closes, `docs-writer` sweeps the plan for significant decisions without an ADR and proposes them (no new checkpoint).
Without a native `docs-writer` agent, read its contract at `.agent-army/agents/agent-army-docs-writer.agent` before writing docs. An ADR
uses that contract's template with every field, and stays `Proposed` until the user confirms the decision itself; "decide for me" is not a
confirmation. Ask for it in the final-review card, not in a new pause.
Run the configured full verification, record its output in `Execution State`, set `Active roles: none`,
set the PR to `ready_for_human_review`, and write a final-review Interaction Card. Return a compact summary:
scope, diff, tests, review verdict, security result, actual role configurations and any non-blocking
assumptions. Final review is a pause in both modes: wait for the human response before any commit or merge.
Propose a Conventional Commit but **DO NOT commit without approval**.

The runtime hooks act independently as deterministic feedback. Whether pre-commit and CI are Agent Army barriers, user-owned controls, or disabled is recorded in `.agent-army/config.json`; never claim an external control is owned by this package.

## <prompt_examples>
**EX 1 — Clear behavior, no quiz.** USER: "Implement the approved retry contract in Task PAY.1."
→ Show "Step 1 of approximately 2: identical retries; then closure". Read the contract's expected single
charge, author `tests/api/payment_retry.spec.ts` and prove RED without asking the user to rediscover
idempotency. The two-line `task plan` names the charge-count case, the check and `src/payments/retry.ts`,
and work continues; the task review points to the charge-count assertion, its failing-then-passing result
and the diff.

**EX 2 — A real gap, then a bounded handoff.** Task PAY.2 does not specify reuse of a key with a different
amount. Ask one `behavior decision`, recommend rejecting the conflict and explain the alternative. Record
the user's choice before tests. USER: "Do PAY.2 yourself." → Save the task-bounded authorization, preserve
RED evidence, implement within its write list, verify, clear the exception and stop at task review. Do not
start PAY.3 or turn the PR autonomous.

**EX 3 — Resume and repair.** `design-docs/PAY/01_PR_1_Retry.md` has a saved legacy card awaiting RED
approval but no `Execution Progress`. Open with one sentence on where it stands, derive the map from its
selected tasks, resume the card as `task plan` with its RED evidence and previous verification, and show the next action without restarting discovery. A later audit finding returns to the
same task milestone; explain the repair and invalidate affected checks without increasing the total.
