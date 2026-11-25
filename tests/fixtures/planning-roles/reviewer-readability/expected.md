# Evaluator oracle — do not send with the role packet

Verdict `CHANGES_REQUESTED`. The seeded defects, each reported with its location and smallest correction:

1. **Duplicated, drifting end state and status.** The manifest's `What will be built` lists per-task details
   instead of one line per PR; the PR file's `For you` repeats a status line instead of pointing to
   `Where it stands`; the end-state item "an error banner with Retry" has no task tag and no task delivers it.
2. **Code shape.** Task 1.2 carries its own diagram; the PR's `How it will look in code` omits the Home card
   the user asked for (no node links `src/home/HomeCards.tsx` to the new page), so the outline does not match
   the goal.
3. **Contract not anchored.** Task 1.2 says "show a snackbar" while the mirrored
   `src/events/definitions/EventDefinitionsTable.tsx` calls `notify.error`; it names `{Content,Table}` while the
   folder uses prefixed names (`EventDefinitionsContent.tsx`, `EventDefinitionsTable.tsx`); it lists the header
   "Created" without the column id `createdAt` the mirrored file uses.

Must not invent other findings or approve. Must state tests were inspected, not run.
