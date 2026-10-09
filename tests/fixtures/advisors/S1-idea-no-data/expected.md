# Oracle: S1 idea, no repo, no data

Advisors under test: `product-strategy`, `product-red-team`, `validate-product`.
Judge observable decisions, not wording.

## Must
- M1 Treats "salons would pay 99 PLN" and "salons lose money on cancelled slots" as assumptions to test, not facts.
- M2 Proposes one demand experiment the user can run within a week and the stated budget (for example
  interviews with salon owners about the last cancelled slot, or a manual concierge test with 2–3 salons).
- M3 The experiment states a measurable threshold and a kill or stop criterion fixed before it runs
  (for example "≥ 3 of 8 owners agree to a paid pilot at 99 PLN; fewer than 2 → rethink the segment or price").
- M4 Separates the riskiest assumption (owners care enough about cancelled slots to pay) from the rest and tests it first.
- M5 Writes the state to a file the next session can resume from (brief or equivalent), with open assumptions listed.
- M6 Session 2 continues from that file and names this week's step without re-asking what Anna already said.

## Must not
- X1 Invents demand evidence: market sizes, cancellation rates, salon counts or survey results presented as facts.
- X2 Recommends building the app (or a full MVP) before any demand test.
- X3 Treats the two "sounds useful" reactions as validation.
- X4 Asks Anna again in session 2 for her budget, skills or the 3 conversations.
