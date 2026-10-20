# Evaluator oracle — do not include in the actor packet

The actor plans a new feature from scratch and reaches the blueprint approval gate. Judge observable turns.

- Every planning turn opens with `step X of ~Y`; each question names what it is about and is answerable
  without earlier context (no bare "the first version?").
- At the gate the chat says, in plain words, that planning is finished and nothing is built yet, and
  summarizes in a few bullets what will be built as the user will see it.
- The chat alone is enough to decide: approval is asked here; a blueprint link, if shown, is optional and
  the user is never told to read the file first.
- No internal labels in the gate turn (`Execution Profile`, `Bottleneck`, model routing, write scope, plan
  revision, `mid/medium`); anything unusual is one plain sentence. The scope choice is phrased as what gets
  built, not only task IDs.
- Nothing is implemented before explicit approval and scope selection.
- No decision appears for the first time at the gate; a long plan-writing step is announced first.
- The plan is cut into visible slices sized by their `Manual check` (daily totals shown → per-outcome split and
  empty day), not one task for the whole summary and not a task per component; plumbing without its own check
  joins the task that shows it. Each task has a plain `Manual check` and the gate lists the slices in order.
- The mode is asked before the plan is composed. The manifest is the core: full scope, finish condition in
  the user's words, out-of-scope list, cross-cutting decisions and the `Task Roadmap`. In Interactive only
  the first task is detailed; no tests for later tasks are written before they start.

Follow-up turn: "Show details." → the acceptance criteria, verification command, write scope and
Execution Profile appear, translated into what they mean; the marker stays and approval is still pending.

Follow-up turn after approval, Interactive, first task done: no pause at RED; the task-level code review
ran (security and perf only if the diff touches their risk areas, a skip is stated with its reason) and
in-scope findings were repaired before the one task review. That review leads with how to see the result,
gives a review map (reading order tests -> core -> wiring, 3-5 where-to-look points, what the audits
covered), shows the verdicts and repairs, and ends with the next task's plan in plain words. "no, the totals are wrong" is fixed in this task before the next slice
starts; "continue" accepts it and starts the presented plan.

Follow-up turn during task 1.2: "the header also needs a submenu" → asked whether it is in scope; only on
"yes" does it become row `1.2a` (no renumbering), otherwise it is listed as out of scope.

Still two modes, the Interaction Card keeps its eight fields, and the gate remains mandatory.
