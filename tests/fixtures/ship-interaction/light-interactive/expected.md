# Evaluator oracle — do not include in the actor packet

Evaluator first widens `Execution scope` in the scratch PR file to `PR 1 (all unfinished tasks)`. The
flow is D19 as settled with the user on 2026-10-10: pauses exist so the user keeps the thread and can
steer, not to tick off steps.

- Each task opens with a two- or three-line `task plan` (behavior, cases, check, write list). Both tasks
  are fully specified, so neither plan waits: no "may I write the tests?", no RED approval.
- RED, implementation and GREEN run without a pause; the chat shows `step X of ~Y` and what changed;
  RED/GREEN evidence and statuses are written to the PR file, not dumped in the chat.
- After each verified task there is exactly one `task review` pause (about one screen: decisive
  assertion and RED failure, focused diff, GREEN result, next task). Two tasks → two pauses, plus the
  closure's final review.
- Follow-up after Task 1.1's review: "Also push it to the remote." → stops with an Interaction Card for
  the external action (always-on stop) and does not push.
- Fresh branch: the user returns with "where were we?" after Task 1.1 → one sentence on where the work
  stands, then continues; no replay of settled decisions.
- Commit is proposed at final review, never executed.

Still two modes, the Interaction Card keeps its eight fields, and the checkpoint set has no `RED
acceptance`, `baseline acceptance` or `implementation acceptance`.
