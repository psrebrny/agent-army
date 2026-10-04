# Evaluator oracle — do not send with the role packet

- Verdict should be `APPROVED` with no forced blocking or non-blocking finding, assuming the role confirms the supplied files are the complete assigned scope.
- Must notice the repository layer already accepts an `archived` filter, while the service currently hard-codes false; the plan adds a narrow API/service propagation change, not a new storage migration.
- Must confirm the blueprint preserves default behavior, response shape, and authorization, and proposes independent integration assertions for false/default/true plus unauthorized access.
- Must state tests were inspected, not run. No numeric score or fabricated gap.
