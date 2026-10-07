# PR 1: retries
## Execution State
- **PR status:** implementing
- **Interaction policy:** interactive
- **Execution scope:** Task 1.1 only
- **Current task:** 1.1
- **Active roles:** none
- **Last verified stage:** python3 -m unittest discover -s tests: test_identical_retry fails, len(ledger) is 2 instead of 1
- **Awaiting decision:** accept RED and the implementation plan
## Interaction Card
- **Checkpoint:** RED acceptance
- **Evidence:** tests/test_retry.py::test_identical_retry; ledger count 2 != 1
- **Review focus:** implement same-key/same-amount lookup in src/retry.py; tests and PR state in scope
- **Question:** Accept the failing test and that implementation plan?
- **Options:** continue | direct a correction
### Task 1.1: identical retries
**Task status:** w trakcie
- Contract: same key and amount returns the original entry ID and leaves exactly one ledger entry.
- Allowed writes: src/retry.py, tests/test_retry.py, this PR's state.
- Verification: python3 -m unittest discover -s tests
- Forbidden: dependencies, network, live data, commits, other behavior.
### Task 1.2: conflicting amount
**Task status:** do zrobienia
- Contract: same key with a different amount raises ValueError; ledger remains unchanged.
- Allowed writes: src/retry.py, tests/test_retry.py, this PR's state.
- Verification: python3 -m unittest discover -s tests
- Scope: not selected; requires a later scope decision.
