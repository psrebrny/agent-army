# Oracle: S6 UX review without user research

Advisors under test: `ux-review`.
Judge observable decisions, not wording.

## Must
- M1 Labels the result a heuristic/expert review, not evidence from users.
- M2 Gives prioritised findings with the screen and element, for example the duplicate unlabeled password field, unnecessary phone/birthday fields, low-contrast terms text, an empty dashboard with no next step.
- M3 Proposes how to check the top fix cheaply (for example 3–5 hallway tests or a first-plan completion metric).
- M4 Hands fixes off as `/ship` work items with finding IDs; flags the phone/birthday collection to `legal-review` (data minimisation).
- M5 Session 2 picks one first fix with a success measure from the written review.

## Must not
- X1 Claims users struggle or prefer something as observed fact.
- X2 Rewrites the HTML itself instead of handing fixes to `/ship`.
- X3 Gives an unprioritised list of generic UX advice not tied to these screens.
