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
feature/ticket, invoke `architect` to create one. Continue automatically only if that plan contains one
unambiguous PR; otherwise ask which PR/task to execute. Users may invoke `architect` directly for
planning or replanning; it creates/updates `design-docs/` and never implements source code.

## 1 · EXECUTION POLICY
Read the selected PR's `Execution State`. If its interaction policy or checkpoints are absent, ask once
and persist the answer in that PR file:

- **Autonomous** — continue through normal stages without pauses and return only at
  `ready_for_human_review`, a configured checkpoint, or a stop condition.
- **Supervised** — pause only at the selected checkpoints: `blueprint`, `red`, `green`, `review`,
  `security`, and/or `final`.

At any mode, ask instead of guessing when a requirement is missing, the scope is ambiguous, or a change
needs expanded authority. A durable repo-wide correction is an occasion to offer `/adapt-army`; one-off
guidance remains in the selected task/PR.

Use these execution statuses exactly:
- `planned`, `red`, `implementing`, `green`, `verified`, `review`, `security`, `docs`,
  `ready_for_human_review` for normal progress;
- `awaiting_approval` for a precisely described scope expansion;
- `needs_input` for a business/technical decision only the user can provide;
- `blocked` only for an external obstacle that remains after a safe attempt to clarify;
- `done` and `partial` for completed or intentionally incomplete work.

## 1.5 · MODEL & EFFORT ROUTING
Every atomic task has a portable `Execution Profile`: `capability` (`light`, `mid`, `strong`) and
`deliberation` (`low`, `medium`, `high`). The architect sets the profile from task complexity/risk; it
does not put a vendor model ID in the manifest. Agent definitions also do not pin a model by default:
an absent `model` field means inherit the active session/tool configuration.

Before dispatching a role, consult the active adapter's `model_control`. For `per_spawn`, use the
profile only to form a recommendation unless the user explicitly approves a model switch. For
`per_role_static`, an absent role-level model still means inherit; never manufacture a vendor/model ID
from a tier. For `inherit` or `unsupported`, retain the current configuration and state that limitation.
For every atomic task, show or record the recommendation before its first role dispatch. If the current
model is adequate, say `no configuration change recommended` and continue without a pause. If a switch
would materially affect quality, risk or cost, pause and ask the user. Record the role, profile,
recommendation, actual configuration or limitation, and any user decision in the selected task's `Run
Configuration` history.

Before the first architect dispatch for every non-trivial task, show a model recommendation and pause
for the user's decision. The recommendation may be that the current model is sufficient; the pause is
not permission to force a stronger model. Show:
```
Model & Effort Recommendation
- Scope / role: [task ID / main session or role]
- Recommended: [confirmed model or adapter-defined tier] / [confirmed effort or tool default]
- Why: [task evidence]
- Lower-cost alternative: [profile] — [trade-off]
- Decision needed: switch and continue | stay current
```
The user changes the model in the UI/CLI, then tells `/ship` to continue. If the user chooses `stay
current`, invoke the architect with the current model and continue. Never change a UI/CLI/API model
setting yourself. Record the response in that task's `Run Configuration`; do not ask again for the same
role/task unless the contract materially changes. After the architect returns, honor the `blueprint`
checkpoint in supervised mode and wait for `ok` or requested changes before implementation.

## 2 · BLUEPRINT OR RESUME  → `architect`
Architect writes `design-docs/[Task-ID]/00_CORE_MANIFEST.md` plus `0X_PR_*.md` (one PR per file) and
never writes production code. Each atomic task has an API contract, a Delegation Contract, an Execution
Profile and an Execution State. On a review escalation, architect updates only affected plan blocks and
the relevant state; it does not silently rewrite completed work.

## 3 · IMPLEMENTATION per task — STRICT TDD `<auto_critic>` with `tester`
_(Applies at `TEST_POLICY=strict`/`pragmatic`. At `light`: thin happy-path tests, no strict RED-first. At `none`: skip this whole step — the main session just implements; lint/security still apply.)_
For EACH task in the blueprint:
1. Set task status to `red`; **`tester` writes the tests (RED)** independently from the contract/acceptance criteria and proves they fail for the right reason.
2. At a `red` checkpoint, pause only when configured. Then set status to `implementing`. The main session implements the smallest change; a delegated `coder` receives only the Delegation Contract, RED tests and approved read paths. In Supervised mode it returns its plan + exact write list and waits for `GO`; in Autonomous mode it proceeds only when that list is wholly inside approved scope.
3. **`tester` verifies (GREEN)**. Set status to `green` only when the command passes; otherwise diagnose and fix without weakening assertions. A required path outside scope, ambiguous/disproved contract, unapproved dependency/migration or repeated failed approach becomes `awaiting_approval`, `needs_input` or `blocked`, never silent expansion.
No batching without verification. *Exception:* for trivial tasks the main session may do the whole Red→Green cycle inline, without a round-trip to the subagent (the cheaper default — see AGENTS.md "Cost & context discipline"). Run the configured verification command after every GREEN step; runtime hooks are feedback, while the user-selected pre-commit/CI controls provide repository enforcement.
At a configured `green` checkpoint, pause; otherwise mark the task `verified` and continue.

## 4 · REVIEW + SECURITY  → independent read-only agents
Start a fresh reviewer context where the tool supports subagents; otherwise invoke the review role with a
clean packet. The packet contains **only** the task contract, finished diff and human decisions. Do not
include coder/tester reports, rationales or transcripts. Audit that packet against standards + business
goal; if the contract is absent, label the result `Diff-Only Review`. Run `security-auditor` independently
against the finished diff at the same time. Neither auditor receives implementation/tester reports or
transcripts.

- reviewer `CHANGES_REQUESTED` → create an in-scope Micro-Blueprint, repair it through RED/GREEN,
  then re-run both review and security;
- reviewer `ARCHITECTURAL_ALIGNMENT_NEEDED` → architect performs targeted course correction, then
  return to implementation;
- every confirmed security finding → repair within the existing contract, prove GREEN, then re-run both
  audits; one that needs a new scope becomes `awaiting_approval` with the exact expansion;
- proceed only after `APPROVED` and zero open confirmed security findings.

Repeat this loop until the selected PR is clean. At configured `review` or `security` checkpoints, pause
with the relevant evidence; otherwise continue autonomously.

## 5 · DOCS + FINAL VERIFICATION
`docs-writer` updates only necessary, truthful docs. Run the configured full verification, record its
output in `Execution State`, set the PR to `ready_for_human_review`, and pause at `final` when configured.
Return a compact summary: scope, diff, tests, review verdict, security result, actual role configurations
and any non-blocking assumptions. Propose a Conventional Commit but **DO NOT commit without approval**.

The runtime hooks act independently as deterministic feedback. Whether pre-commit and CI are Agent Army barriers, user-owned controls, or disabled is recorded in `.agent-army/config.json`; never claim an external control is owned by this package.
