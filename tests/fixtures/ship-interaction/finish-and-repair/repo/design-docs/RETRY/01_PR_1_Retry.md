# PR 1: retries
## Execution State
- **PR status:** ready_for_human_review
- **Interaction policy:** interactive
- **Execution scope:** Task 1.1 only
- **Current task:** 1.1
- **Active roles:** none
- **Last verified stage:** Synthetic prior-session fixture: both tests passed; code review APPROVED for selected Task 1.1; security no open findings; docs no change; full verification passed. No commit.
- **Awaiting decision:** final review
## Interaction Card
- **Checkpoint:** final review
- **Question:** Review the completed selected scope.
- **Evidence:** recorded prior-session verification and audit results; Task 1.2 not in scope.
### Task 1.1: identical retries
**Task status:** wykonane
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
