# PR 1: retries
## Execution State
- **PR status:** planned
- **Interaction policy:** unset — /deliver asks once per PR before first execution
- **Execution scope:** PR 1 (all unfinished tasks)
- **Current task:** none
- **Active roles:** none
- **Last verified stage:** blueprint revision 1 approved (synthetic fixture)
- **Awaiting decision:** none
## Interaction Card
none
### Task 1.1: identical retries
- **Task status:** open
- **Contract:** same key and amount returns the original entry ID and leaves exactly one ledger entry.
- **Files:** tests `tests/test_retry.py` · production `src/retry.py` · forbidden dependencies, network, live data, commits, other behavior
- **Verify:** `python3 -m unittest discover -s tests`
- **Bottleneck:** verification — the behavior is fully specified; the risk is a test that passes for the wrong reason; escalate when the test cannot distinguish one ledger entry from two
### Task 1.2: conflicting amount
- **Task status:** open
- **Contract:** same key with a different amount is rejected; the ledger remains unchanged. How it is rejected is open.
- **Files:** tests `tests/test_retry.py` · production `src/retry.py` · forbidden dependencies, network, live data, commits, other behavior
- **Verify:** `python3 -m unittest discover -s tests`
- **Bottleneck:** design_decision — raising ValueError and returning the original entry with a warning are both plausible for callers; escalate when the caller contract in README.md does not decide between the two
