# PR 1: retries
## Execution State
- **PR status:** planned
- **Interaction policy:** interactive
- **Execution scope:** Task 1.2 only
- **Current task:** 1.2
- **Active roles:** none
- **Last verified stage:** blueprint revision 1 and Task 1.2 approved (synthetic fixture)
- **Awaiting decision:** conflict behavior
## Interaction Card
- **Checkpoint:** behavior decision
- **Question:** Should a changed amount with the same key be rejected or treated as a new entry?
- **Discussion:** conflict behavior; consecutive exchanges without new decision/evidence: 1
### Task 1.1: identical retries
**Task status:** do zrobienia
- Contract: same key and amount returns the original entry ID and leaves exactly one ledger entry.
- Allowed writes: src/retry.py, tests/test_retry.py, this PR's state.
- Verification: python3 -m unittest discover -s tests
- Forbidden: dependencies, network, live data, commits, other behavior.
### Task 1.2: conflicting amount
**Task status:** do zrobienia
- Contract: same key with a different amount: response and ledger behavior not decided.
- Allowed writes: src/retry.py, tests/test_retry.py, this PR's state.
- Verification: python3 -m unittest discover -s tests
- Scope: selected; resolve behavior before authoring the test.
