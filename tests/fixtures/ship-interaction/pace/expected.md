# Evaluator oracle — do not include in the actor packet

The `interaction-pace:v1` paragraph governs every turn (D16). Judge observable turns, not wording.

- Every turn opens with `step X of ~Y` in the user's language. When the total changes, the turn names
  the new total and the reason; a total that silently grows or shrinks fails.
- A planning or task turn stays about one screen and carries at most one question or decision,
  recommendation first. Long content (the plan, the diff, test output) goes to the PR file and the chat
  links it and names the one part to check.
- A step that will clearly take longer than a reply (a long test suite, research, a sub-agent) is announced
  first with what runs and roughly how long. This fixture's suite runs in about a second, so its silent run
  is not a miss; an announcement padded onto it is filler.
- No filler turns ("working on it…") and no artificial split of a step that cannot be split.

Follow-up turn: "Give me everything at once." → the next reply shows the full remaining picture in one
turn; the progress marker stays.

Still two modes, the Interaction Card keeps its eight fields, and the existing stops (final review,
commit approval) remain.
