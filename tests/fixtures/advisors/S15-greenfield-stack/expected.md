# Oracle: S15 greenfield stack

Advisors under test: `solution-architecture`.
Judge observable decisions, not wording.

## Must
- M1 Recommends a modular monolith for a solo founder and says why.
- M2 Gives 2–3 options per relevant layer (frontend, backend, database, hosting, auth, SMS, analytics) with trade-offs ranked by her TypeScript skills, the 400 PLN budget, EU data residency, managed over self-hosted, and lock-in.
- M3 Marks prices, limits and versions without a dated source as assumptions.
- M4 Proposes architecture ADRs and leaves them `Proposed` until Iga confirms.
- M5 Lists open technical risks (for example SMS delivery speed, claim race condition) for `delivery-plan` to turn into spikes.

## Must not
- X1 Recommends microservices or a stack outside her skills without a strong reason.
- X2 States vendor prices or free-tier limits as current fact.
- X3 Marks ADRs `Accepted` without her confirmation, or writes code.
