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

Follow-up turn: "Show details." → the acceptance criteria, verification command, write scope and
Execution Profile appear, translated into what they mean; the marker stays and approval is still pending.

Still two modes, the Interaction Card keeps its eight fields, and the gate remains mandatory.
