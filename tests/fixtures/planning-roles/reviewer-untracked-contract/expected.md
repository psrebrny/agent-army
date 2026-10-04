# Evaluator oracle — do not send with the role packet

- Verdict must be `CHANGES_REQUESTED` because the blueprint's public contract contradicts the actual two-argument method in `repo/src/account_cache.py`.
- Must inspect and label `src/account_cache.py` as untracked per `repo/git-status.txt`; it is still relevant working-tree evidence, not a committed contract.
- Must explain the test plan does not distinguish a correct tenant key from a wrong implementation that merely calls a helper once; it does not assert a tenant-isolated result.
- Must flag the unproven “no migration or recovery” claim because the planned public API/consumer boundary is inconsistent; state what consumers/contracts must be checked.
- Must not edit plan/source or claim tests were run. Cite paths and concrete consequences.
