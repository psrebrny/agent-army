# PR 1 — tenant-safe key

## Task 1.1
- Keep the one-argument `AccountCache.get(account_id)` contract.
- Change cache-key composition to include tenant identity.
- Verify with a unit test that the helper is called once.
- No migration or recovery step is required.
