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

## 0 · THE REPO'S ARMY
The repo is the git root of the directory you were invoked from; its whole Army is `.agent-army/` there
(this skill may be installed globally — never look for repo state next to it). Every role named below
(`architect`, `tester`, `coder`, `code-reviewer`, …) is the contract `.agent-army/agents/agent-army-<role>.agent`.
There are no native `agent-army-*` agents; never look for or spawn one. This file owns orchestration: who
runs, when, which state is written and where the work pauses. Each role's own judgment lives in its
contract; do not restate it in a packet.

- **No `.agent-army/`:** say once that `/bootstrap` is recommended, then continue on the package's baseline
  roles (`../bootstrap/baseline/core/agents/<role>.md`, relative to this file) and the default policy.
- **Dispatch:** in Claude Code, run a role as a general-purpose subagent whose prompt is the full contract,
  then `---`, then the task brief. In a tool without such a subagent call, execute the contract in the main
  session and record it under `Active roles`.
- `python3 ../bootstrap/army.py locate --tool <tool>` prints all of this resolved (repo root, contract path
  and model per role, dispatch mode) when you want it deterministic instead of reading the files yourself.
- Files of this skill, read only when named below: `references/routing.md` (scope profile, effort and
  model routing), `references/legacy.md` (resuming an older blueprint), `scripts/removals.py` (the removal
  list for an audit packet).

## 0.1 · RESOLVE THE EXECUTION SCOPE
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
constraint is still unknown; a small and clear task may skip it, with the reason recorded in `Planning Session`.
Keep the architect as the single user-facing plan author: relay its one-at-a-time question to the user, save
the answer in the blueprint, and return the affected excerpt rather than a full plan dump. After the architect
composes a blueprint, invoke `plan-reviewer` in a fresh context with the packet its contract defines; persist
the verdict and revision in `Planning Session`. If no independent context can be created, record
`INSUFFICIENT_EVIDENCE` and stop at the blueprint gate unless the user explicitly chooses to proceed with that
limitation. A review verdict never authorizes implementation.

## 1 · EXECUTION POLICY
Read the selected PR's `Execution State`. Interaction is selected **per PR**, never per role or command.
If `Interaction policy` is `unset`, ask once and persist one of two user-visible modes:

- **Autonomous** — after the mandatory blueprint + routing + scope gate, continue through normal stages
  without routine pauses. Stop only for a decision condition below, final human review, or commit approval.
- **Interactive** — after that same gate, work one atomic task at a time together with the user. Pauses
  exist so the user keeps the thread and can steer, not to tick off steps: before a task, show its
  `task plan` and wait only when it carries a question or something unexpected; then run RED,
  implementation, GREEN and the task-level audits that section 4 selects by risk, with in-scope repairs,
  as one loop without a routine pause; then pause once at `task review`, which also presents the next task's plan.
  A recorded one-task delegation below lets the main session settle the task's in-scope choices itself; it
  never waives task review.

When asking, give one recommendation with a one-line reason. Recommend **Interactive** if any selected task has `Bottleneck` `design_decision | multiple_approaches | unknown`, or a Verification Command that is not runnable (a manual evaluation such as scorecard rows does not count), and name those tasks. Otherwise recommend **Autonomous**. The user decides: the recommendation never sets the mode, adds no pause and is not repeated after the choice. In Interactive mode, once every remaining selected task would earn the Autonomous recommendation, the task-review card's `Review focus` says "remaining tasks qualify for autonomous"; the existing `switch to autonomous` option does the rest.

Never ask the user to choose raw `red`/`green`/`review` checkpoints. The user may say `switch to
autonomous` or `switch to interactive` at any time; persist the new mode immediately and apply it at the
next safe boundary. On `switch to autonomous`, detail and review the remaining selected tasks before
continuing.

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

Decisions happen in the chat, in plain words. Before a question, say in one line where the work stands (for
example: planning is finished, nothing is built yet) and name what the question is about, so it can be answered
without earlier context. At a decision point the chat alone is enough to decide; a file link is optional
reference, never required reading. Internal labels (`Execution Profile`, `Bottleneck`, model routing, write
scope, plan revision, card field names) stay in the PR file unless the user asks or a card below requires them;
then translate them into what they mean for the user.

**Progress.** The outcome map is the manifest's `Task Roadmap`: one milestone per selected task, a closure
milestone per PR, and the feature's `final` row; its finish condition is the manifest's. RED, implementation
and GREEN are phases within a milestone. There is no other status list or progress section. After scope
approval, show the selected scope and goal, the map, the current milestone and approximate total, and the
finish condition; for a multi-PR scope also the current and remaining PRs, and announce the next PR's map when it
starts. Keep the count on resume. At each interactive exchange show a
compact progress line in the user's language (current step, verified work, current action, remaining outcomes,
finish condition), with the Interaction Card when pausing. Link to diffs and results instead of dumping them.
Label a GREEN task as verified and awaiting audit, not complete. Explain each map change once in the chat and
record it in `Latest plan change`; a repair returns to its task's milestone and invalidates the affected
evidence without adding a milestone. A new outcome changes the estimate only after the user agrees it is in
scope; side ideas go to the manifest's `Out of scope` as deferred. Never promise a duration or message count.

**Task plan.** Before each task, the first one included, show its `task plan` in two or three lines: behavior, significant cases, verification and exact write list.
A roadmap task that is not yet detailed is detailed first, by the architect role, inside the manifest's core and
from the reviewed slices (its PR file is created when the PR's first task starts, carrying the current scope's
interaction policy); this is not a new blueprint gate. Never write tests for later roadmap tasks in advance. A
topic found during work becomes an inserted roadmap row only when the user agrees it is in scope; a finding that
the core is wrong stops the task for a core decision (architect Rule 13).
When nothing is open and the write list is inside approved scope, show the plan and continue; it is a heads-up,
not an approval step. It waits only when it carries a question: a missing requirement, trade-off, scope choice
or interpretation that would change the work, or something unexpected such as a needed write outside scope.
Read discoverable facts and reuse confirmed decisions first. Ask one concrete question with a recommendation and
consequences, with `needs_input` and task `awaiting decision`. A gap found later, mid-task, is a
`behavior decision` with the same shape. During the task the chat shows only `step X of ~Y` and what changed;
RED/GREEN evidence and statuses go to the PR file. After resolution restore the execution stage without
discarding prior evidence. This is delivery, not tutoring: never quiz the user, ask syntax questions, or make
them rediscover an answer already supported by the contract.
- On "I don't know", explain the relevant consequence and recommend a resolution, without guided guessing.
- On "decide for me", make the current in-scope choice and record its rationale; do not waive checkpoints.
- After two consecutive exchanges on the same question without a new decision or evidence, name the
  obstacle and propose a concrete resolution or the smallest in-scope experiment. Persist the unresolved
  question and this no-progress count in the card's `Discussion` field so resumption does not restart the
  loop. Reset the count on new evidence/decision. Never infer required approval from silence or the count.
- Save each resolved choice in the affected task contract/evidence before clearing its card, then act on it.
  Send the tester that settled behavior and acceptance criteria, not an implementation-derived expected value.
- When finish criteria are met, return the final review result rather than opening another round of improvements.

### RESUME
On resume, read `Execution State`, task decisions/evidence, the pending card, the roadmap and any temporary
delegation before acting. Initialize a missing temporary delegation to `none`. Missing evidence stays unknown:
inspect or rerun the relevant check without replaying decisions. When the user returns after a break, open with
one sentence on where the work stands (task, last verified result, the pending question or next step) before
anything else. If the file has a shape older than the current skeletons (a `supervised` policy, a card at a
checkpoint not in the list below, an `Execution Progress` section, Polish statuses, separate routing lines),
read `references/legacy.md` first. When a simple inline task has no PR file, keep the same compact state in the
conversation; do not create a blueprint solely for a progress counter or claim file-backed resumption where
none exists.

### ONE-TASK DELEGATION
"Do this part yourself" authorizes autonomous execution only for the current, unambiguous approved task
through verification. If "part" is ambiguous, clarify the task boundary first. Keep `Interaction policy:
interactive`; record `Temporary delegation` in `Execution State` with the task ID, the user's authorization,
approved write scope and return point (`task review`). Include this authorization in a delegated coder's
packet; the coder returns to `/ship` for verification/interactive review rather than owning the dialogue.
It is a bounded exception, not a third mode.

Within that task, preserve the usual RED/baseline evidence and the plan/write list, but settle the task's
in-scope choices yourself with a recorded rationale instead of waiting at `task plan` or `behavior decision`.
At verified completion clear the exception before presenting `task review` and wait. It never grants
permission to start the next task, skip checks, change scope, cross a risk boundary, or bypass blueprint/final
review/commit approval. Ordinary required stops still apply. Cancel the exception on user revocation, explicit
mode switch, or a scope/risk/contract stop; save the stop reason and do not silently reinstate it. A normal
verification failure permits in-scope repair under the existing stop rules, not unbounded retries. On resume,
honor only a saved authorization for the same still-active task; expire it when that task is verified or the
boundary no longer matches.

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
one question with a recommendation; a plan without a question is shown and not persisted as a pause.

**Task review** (Interactive), in about one screen:
- Lead with the task's `Manual check` in plain words (how to start or reach the app, what to click, what
  should be visible) and ask whether it looks and works as the user wants; a "no" is a correction to this
  task before the next one builds on it. Explain what the check cannot establish.
- Evidence: the decisive RED assertion and its failure reason (or the passing baseline for a refactor), the
  focused diff summary, GREEN command/result, the task-level audit verdicts (any audit skipped, with the
  reason), the repairs already made and known limitations.
- A **review map** instead of a bare diff, because a task can be a few hundred lines: (1) a reading order,
  normally tests first as the specification, then the core logic, then wiring such as barrels, mounts and
  schemas, each with file/line pointers; (2) the diff grouped in those stages, as separate commits or staged
  groups when the user has asked for commits; (3) three to five `where to look` points, the decisions and
  risks only a human can judge, such as naming, UX, an assumption or a trade-off; (4) what the task-level
  audits already covered, so the user does not repeat mechanical review.
- End with the next task's plan in plain words (what will be done and what the user will then see).
  `continue` accepts this task (it becomes `done`) and starts that plan; a correction to the plan is settled
  before it starts. The user reviews the task's code and tests together here, once.

For `behavior decision`, include the unknown, recommendation and consequence; do not pause when all are settled.
A finding-decision card names the finding, its severity, the in-scope repair option, and any decision that
needs the user. For a plainly in-scope finding, record the same card as evidence with `Question: none` and
`Options: none`, then continue the repair immediately; if resolving the finding needs a decision, it becomes a
pause in both modes. A final-review card names the full verification result, audit verdicts, docs change, the
ADRs awaiting confirmation and the proposed (not executed) commit.

For an explicitly approved behavior-preserving refactor, the `task plan` names the preserved contract,
refactor checkpoint/recovery and exact write list, and the task review shows the passing before-change checks;
do not call a passing baseline RED.

### MANDATORY BLUEPRINT + ROUTING + SCOPE GATE
When `architect` creates or materially revises a blueprint (a core-tier change, architect Rule 9), this gate is mandatory even with
`Interaction policy: autonomous`. Read `.agent-army/config.json` → `model_routing` before returning from
the architect handoff. Persist an Interaction Card for the blueprint decision and:

- `PR status: awaiting_approval`, `Active roles: none`, and `Execution scope: unset`;
- `Routing`: Scope Profile `unset`, the configured models, and manual setting `unknown` only when the
  adapter falls back to `inherit`;
- `Last verified stage: blueprint path + acceptance criteria reviewed`;
- `Awaiting decision: approve/revise blueprint; select scope` — add `switch and continue/stay current`
  only for an `inherit` fallback whose main-session recommendation is material (`references/routing.md`).

Then, in the chat and in the user's language, say that the plan is finished and nothing is built yet, and
list in order the small steps the user will be able to try, one line each (the `Task Roadmap`), then the finish
condition and what is out of scope.
Name anything unusual in one plain sentence each: a write outside the feature, a new dependency, a non-default
environment, a review limitation. Nothing appears here for the first time: a choice the user has not seen is
asked as its own question before the gate. Say that approval happens here; the blueprint link is optional. The
acceptance criteria, verification command, write scope and Execution Profile stay in the PR file and card,
shown on `show details`. Ask the user to make these decisions explicitly, phrasing the scope as what gets
built rather than task IDs:

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
Profile (section 1.4). Autonomous execution starts after the required decisions. A static role model is already
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
pending → `in testing`; GREEN complete and task-level audits pending or in progress → `in review`; task
criteria, selected task-level audits and focused checks verified and, in Interactive mode, the task review
accepted → `done`; `awaiting_approval` or `needs_input` → `awaiting decision`; `blocked` → `blocked`;
out-of-scope until a stated condition → `conditional`. Docs and the closure pass are PR-level and never hold
a task back from `done`; a later repair of a `done` task is a task-tier correction (section 2) that sets it
back to `in progress`. Record exact RED/GREEN command results and reviewer verdicts in `Last verified stage`
or the task evidence, not as a second status. A role's Handoff `STATUS: done` alone never marks a blueprint
task `done`.

## 1.4 · SCOPE-AWARE ROUTING
The Scope Profile (coordination burden of the selected scope) is calculated after scope selection and
recorded in the PR file's `Routing` line; the table and rules are in `references/routing.md`. A whole-feature
scope raises coordination only; it never raises every worker's configuration.

## 1.5 · BOTTLENECK-AWARE EFFORT POLICY
Each task's `Bottleneck` comes from the architect. When a verified result is poor, escalate in this order:
clean/retrieve context → adjust one effort step for a reasoning problem → route to a stronger role
capability or specialist → ask for a decision/scope change. Never spend unbounded effort on retrieval, context
noise or a repeated failed approach. Read `references/routing.md` for the first move and trigger per bottleneck.

## 1.6 · MODEL & EFFORT ROUTING
Each role is routed from `model_routing` (bootstrap) as `army.py locate` resolves it. With a role model
(`dispatch: subagent-with-prompt`) dispatch directly with that model, without asking the user at role
boundaries, and record it in the task's Run Configuration. With `dispatch: main-thread` read the role's
contract (`army.py role <role>`) and execute it in the main session. Never change a UI/CLI/API model or effort
setting yourself. For an `inherit` fallback (null role model), a task that needs more than its role's tier, or
effort labels, follow `references/routing.md`.

## 1.7 · PERSIST EVERY ROLE TRANSITION
`Execution State` is the resumable source of truth, not the Todo list or a chat message. Immediately
before and after every role dispatch, rewrite the selected PR file: set `PR status`, `Current task`,
`Active roles`, `Last verified stage`, the mapped user-visible task status, `Awaiting decision`, and any
Interaction Card. Never leave the previous worker listed as active after it returns. Keep detailed execution
evidence in `Last verified stage` and the review files (section 1.8); do not replace the task's planning status
with the English execution-step label.
Whenever a task's status changes, update its `Task Roadmap` row in that same write. Whenever a PR's status
changes (first dispatch, `awaiting_approval`, `blocked`, `ready_for_human_review`), also refresh the manifest's
Planning Session `Progress` (each PR's status in one line), `Next action` (the one next step) and
`For you.Where it stands` (the same in plain words) in the same write, so the blueprint entry point never shows
an older state than its PR files. Touch no other manifest field.

- **Architect:** before → `planned`, active `architect`; after → `awaiting_approval`, active `none`,
  `Execution scope: unset`, Scope Profile `unset` in `Routing`, blueprint path, current Planning Session stage/revision,
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
  evidence and next corrective action. On verified completion clear any one-task delegation.
- **Task-level audits:** before → PR stays `implementing`, active the selected auditors; after → active
  `none`, persist each verdict. The task stays `in review` until every selected audit passes; a confirmed
  finding moves it to `in progress` for an in-scope repair and back to `in testing` before the affected audit
  re-runs. Never skip the test status. Then the task review (Interactive) or `done` (Autonomous).
- **Closure audits:** before → PR `review`, active the selected auditors; after → active `none`, persist verdicts.
- **Docs + final:** before → PR `docs`, active `docs-writer`; after full verification →
  `ready_for_human_review`, active `none`, final evidence and a `final review` Interaction Card.
  When the user accepts the final review, shrink the PR file to its done form (architect Rule 9).

## 1.8 · WHERE ARTIFACTS GO
Workers return their reports as their final message; `/ship` decides what is saved and writes it, except
`planning-evidence.md`, which the architect keeps. Saved files are committed with the blueprint, one file per
scope (task, PR, feature, plan); a re-run overwrites it (current state; git keeps the history):

| File | Written from | Content |
|---|---|---|
| `design-docs/[ID]/reviews/[PR.task]-review.md` | task-level audits | one block per selected audit (code, security, perf): verdict, then each finding as severity · what · `fixed` (how, file) / `open` (the question for the user) / `not a finding` (why) |
| `design-docs/[ID]/reviews/PR[n]-review.md` | closure audits over the whole PR diff | the same shape |
| `design-docs/[ID]/reviews/feature-review.md` | the whole-feature audit (section 4) | the same shape, plus the acceptance and removals lists |
| `design-docs/[ID]/reviews/plan-review.md` | `plan-reviewer` | verdict, reviewed revision, findings and their resolution |
| `design-docs/[ID]/planning-evidence.md` | `planning-analyst`, kept by the architect | confirmed facts and source paths the plan relies on |

Nothing else is saved. RED/GREEN results live in `Last verified stage` (command, exit, counts, the decisive
assertion); the docs result is the docs diff itself, summarized in the final-review card; coder and tester
reports stay in the conversation. Do not store raw logs, and never cite `/tmp` or another session-only path as
evidence. The blueprint links only to these files. In-scope findings are repaired before the file is written
(section 4), so the review file shows what was found and how it was fixed, and the user reads one file per task.

## 2 · BLUEPRINT OR RESUME  → `architect`
The architect writes and corrects the blueprint (`00_CORE_MANIFEST.md` plus one `0X_PR_*.md` per PR) and never
writes production code. A user correction, review escalation or manual change follows architect Rule 9 (the
smallest tier, current state, consistency check, change card); only the core tier returns to the mandatory
blueprint + scope gate. Completed work is never silently rewritten or falsified.

**Small corrections stay small.** For a minor or task-tier correction of the active or an accepted task (a user's comment,
a manual-check "no", an in-scope review finding):
- The user's explicit request for the correction is its go-ahead. Show the change card as information and
  continue; ask only for a real ambiguity, a write outside scope, or a risk boundary. Never ask the user to
  approve the plan of a fix they just asked for.
- The main session does the whole loop itself, by default and not as an option: update the task block and
  `Latest plan change`, write or adjust the test, RED, fix, GREEN. Do not dispatch architect, planning-analyst,
  tester or coder, and do not re-read standards, skills or contracts already read in this session. Dispatch a
  role only for a core-tier change, a diff that outgrows one sitting, or missing context the session cannot
  read directly.
- Audits follow section 4's risk selection on the correction's diff (a presentational fix runs `code-reviewer`
  only). The result goes into the one task-review pause; there is no pause before RED or before the fix.

For a new blueprint, ask the interaction policy before the architect composes, because it sets planning depth
(architect Rule 13); with tasks not yet detailed, base the recommendation on the open planning decisions. Use the
interactive Planning Session and planning-role orchestration from section 0.1.
For a resumed blueprint, read its saved Planning Session first and continue at `Next action`; never restart
resolved decisions. Every task starts as `open`. If a user decision is pending, set the task to
`awaiting decision` only when the decision blocks that task, preserve the exact question in the Interaction Card,
and leave unrelated task statuses unchanged.
If the architect finds that the goal is already met or recommends no implementation, return that finding
and its evidence to the user without inventing a PR, selecting work, or activating a suggested service.
A proposed configuration/adoption change still needs a concrete approved scope before execution.

## 3 · IMPLEMENTATION per task — STRICT TDD `<auto_critic>` with `tester`
_(The RED-first loop applies at `TEST_POLICY=strict`/`pragmatic`. At `light`: thin happy-path tests, no strict RED-first. At `none`: no authored tests; implement and check acceptance behavior, with required lint/security still active. The interaction and progress rules apply at every policy.)_
For each task, first show its `task plan` and resolve only genuine behavior gaps (section 1). At `light`/`none`,
when no RED or baseline exists, the `task plan` names the proposed check, smallest implementation plan and write
list before coding; afterwards record the verification actually run, never invented RED/GREEN evidence.
The tester applies its own contract (risk-based level, test budget, fault checks only in an isolated subject,
refactor baseline instead of RED; that exception never lets a bugfix or new feature claim success without
demonstrating the required behavior). When the main session writes the tests itself, it keeps the two rules that
make them worth having: expected values come from the contract, never from the implementation, and RED fails
for the stated reason. A required repository check stays mandatory.

1. **RED:** `tester` writes the tests independently from the contract/acceptance criteria and proves they fail for the right reason (section 1.7 *Tester RED*). For an approved behavior-preserving refactor, the passing baseline replaces RED.
2. **Implementation:** continue in both modes unless a decision condition applies. The main session implements the smallest change; a delegated `coder` receives only the Delegation Contract, the `task plan` write list, RED tests and approved read paths. Work stays within that write list, and only when it is wholly inside approved scope; anything else is a stop.
3. **GREEN:** `tester` verifies. A required path outside scope, an ambiguous/disproved contract, an unapproved dependency/migration or a repeated failed approach becomes `awaiting decision` or `blocked`, never silent expansion.

No batching without verification. *Exception:* for trivial tasks and small corrections (section 2) the main session does the whole Red→Green cycle inline, without a round-trip to a subagent (the default, not an option — see AGENTS.md "Cost & context discipline"). This does not remove an Interactive `task plan` or task-review card: it changes only who performs the work. Inside a task run only the focused tests of the changed area after each GREEN step; run the configured full verification (types, lint, package regression) once when the task is ready for review, and again at PR closure. Runtime hooks are feedback, while the user-selected pre-commit/CI controls provide repository enforcement.
After every verified task, clear any one-task delegation, run the task-level audits (section 4) on that task's
diff and repair plainly in-scope findings. In Interactive mode, then detail the next roadmap task, write the
task-review Interaction Card and wait. In Autonomous mode, mark the task `done` and continue to the next planned
task without a routine pause.

## 4 · REVIEW + SECURITY  → independent read-only agents
**Selection by risk.** `code-reviewer` always runs. `security-auditor` runs when the diff touches authentication
or authorization, secrets or configuration, network or user input, data storage or queries, file or shell
access, or dependencies; a purely presentational change may skip it at task level with the reason recorded.
`perf-auditor` runs only for lists, queries, large renders or a stated performance goal. The closure pass always
runs `code-reviewer` and `security-auditor`, so a skipped task-level audit is never skipped for good.

**Packet.** Each selected auditor runs in a fresh context where the tool supports subagents (otherwise as a
role with a clean packet), at the same time as the others. Its packet holds only: the task contract (or the
manifest's goal and criteria at closure), the comparison base with source pointers so committed, staged,
unstaged and untracked changes are all in scope, explicit human decisions, and the output of
`python3 scripts/removals.py <base>` (relative to this file) so removals are not lost in a large diff. Authoritative schemas and contract
indices are source context, not implementation reports; keep the packet focused on affected boundaries. Never
include coder/tester reports, rationales or transcripts; each role's contract says how it audits that packet.

**Findings.**
- reviewer `CHANGES_REQUESTED` → `/ship` creates an in-scope Micro-Blueprint and writes a finding-decision
  Interaction Card. A plainly in-scope repair proceeds in both modes (Interactive reports it in the task
  review); a repair that needs a decision waits. Repair only through RED → coder or main session → GREEN, then re-run the selected audits;
- reviewer `ARCHITECTURAL_ALIGNMENT_NEEDED` → write a finding-decision Interaction Card, return the issue
  to architect for a targeted correction, then stop at the mandatory blueprint/scope gate; never route this
  verdict directly to coder;
- every confirmed security finding → write a finding-decision Interaction Card. A plainly in-scope repair
  follows RED → coder or main session → GREEN and then re-runs the selected audits, in both modes.
  A finding that needs a new scope becomes `awaiting_approval` with the exact expansion in both modes;
- proceed only after `APPROVED` and zero open confirmed security findings.

Once in-scope repairs are verified, write the review file (section 1.8) with what was found and how it was fixed
or what stays open. With no finding, do not add a routine review pause; its evidence appears in the task review
or final-review card.

**Closure, in this order, when every task of the PR is `done`:**
1. the closure audits over the whole PR diff, for cross-task issues (`reviews/PR[n]-review.md`); for the
   feature's last PR the whole-feature audit below takes their place, since it covers that diff too;
2. in-scope repairs through RED → fix → GREEN, re-running the affected audit;
3. docs (section 5);
4. the full verification and one final-review card.

**Whole-feature audit.** When every task row of the `Task Roadmap` is `done`, run the `final` row before calling the
feature finished; never skip it because each slice was clean. `code-reviewer` in feature mode,
`security-auditor` always, `perf-auditor` when the feature has lists, queries or a performance goal, all on the
whole feature diff from the commit before its first task; the packet adds the manifest goal, finish condition,
acceptance criteria and decisions in force, and the removal list is mandatory. A finding that changes scope or
the core is a decision. Write `reviews/feature-review.md` (section 1.8). The final-review card leads with a
manual walk through the whole user journey and names what could not be verified; the `final` row becomes done
when the user accepts it.

## 5 · DOCS + FINAL VERIFICATION
Persist PR `docs` and `Active roles: docs-writer`; `docs-writer` runs once per PR, after the closure audits and
their repairs, and follows its own contract (README level, ADR trigger and template, plan sweep, work item).
When it runs in the main thread, read its contract (`army.py role docs-writer`) first. An ADR stays `Proposed`
until the user confirms the decision itself; "decide for me" is not a confirmation. Ask for it in the
final-review card, not in a new pause.
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
approval and a legacy `Execution Progress` section. Open with one sentence on where it stands, follow
`references/legacy.md` (the card resumes as `task plan` with its RED evidence; the section is dropped on the next
write), read the map from the manifest's `Task Roadmap`, and show the next action without restarting discovery.
A later audit finding returns to the same task milestone; explain the repair and invalidate affected checks
without increasing the total.

**EX 4 — A small fix to an accepted task.** During PR 2, the user says "the empty-state title in 1.2 should be
an h3, not an h5". → Change card `· task`, task 1.2 back to `in progress`; the main session adds the
`getByRole('heading', { level: 3, name })` assertion, sees it fail on the `h5`, fixes the component, runs the
focused tests, runs `code-reviewer` only (presentational), and shows the result in one task review. No plan
approval, no subagent, no pause before RED.
