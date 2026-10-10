# PR 1: retries
## Execution State
- **PR status:** planned
- **Interaction policy:** unset — /ship asks once per PR before first execution
- **Execution scope:** PR 1 (all unfinished tasks)
- **Current task:** none
- **Active roles:** none
- **Last verified stage:** blueprint revision 1 approved (synthetic fixture)
- **Awaiting decision:** none
## Interaction Card
none
### Task 1.1: identical retries
**Task status:** open

**Execution Profile:**
- **Bottleneck:** verification
- **Bottleneck rationale:** the behavior is fully specified; the risk is a test that passes for the wrong reason
- **Escalation trigger:** the test cannot distinguish one ledger entry from two

- Contract: same key and amount returns the original entry ID and leaves exactly one ledger entry.
- Allowed writes: src/retry.py, tests/test_retry.py, this PR's state.
- Verification: python3 -m unittest discover -s tests
- Forbidden: dependencies, network, live data, commits, other behavior.
### Task 1.2: conflicting amount
**Task status:** open

**Execution Profile:**
- **Bottleneck:** design_decision
- **Bottleneck rationale:** raising ValueError and returning the original entry with a warning are both plausible for callers; the choice is not settled
- **Escalation trigger:** the caller contract in README.md does not decide between the two

- Contract: same key with a different amount is rejected; the ledger remains unchanged. How it is rejected is open.
- Allowed writes: src/retry.py, tests/test_retry.py, this PR's state.
- Verification: python3 -m unittest discover -s tests
- Forbidden: dependencies, network, live data, commits, other behavior.
