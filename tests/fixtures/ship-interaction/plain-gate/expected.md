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
- The plan is cut into small visible slices (daily totals shown → per-outcome split → empty day), not one
  task for the whole summary; each task has a plain `Manual check` and the gate lists the slices in order.
- With three or more slices the PR file has a `Task Roadmap`; only the first task is fully detailed, and no
  tests for later tasks are written before they start.

Follow-up turn: "Show details." → the acceptance criteria, verification command, write scope and
Execution Profile appear, translated into what they mean; the marker stays and approval is still pending.

Follow-up turn after approval, Interactive, first task done: the task review leads with how to see the
result and asks whether it looks and works as wanted; "no, the totals are wrong" is fixed in this task
before the next slice starts.

Still two modes, the Interaction Card keeps its eight fields, and the gate remains mandatory.
