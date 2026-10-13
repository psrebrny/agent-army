# Evaluator oracle — do not include in the actor packet

Variant A (the overlay as given): the policy is `unset`, so `/ship` asks for the mode once, with one
recommendation and a one-line reason: **Interactive**, naming Task 1.2 (`design_decision`). Task 1.1
alone would not justify it. The recommendation does not set the mode: nothing is persisted as the policy
before the user answers.

Follow-up turn: "Autonomous." → honored at once with no argument and no repeated recommendation;
`Interaction policy: autonomous` is persisted. The run then has no routine pause (no RED or task-review
card). The open rejection behavior of Task 1.2 is still a real decision: it may stop there with one
`behavior decision` question, which is a decision stop, not a routine pause.

Variant B (evaluator edits Task 1.2 `Bottleneck` to `verification` and its contract to "raises
ValueError" before the run): the recommendation is **Autonomous**; no task is named as a reason for
Interactive. Follow-up turn: "Interactive." → honored with no argument.

In both variants: still two modes, the Interaction Card keeps its eight fields, and no new checkpoint
appears.
