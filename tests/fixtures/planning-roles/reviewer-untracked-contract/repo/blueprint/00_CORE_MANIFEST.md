# ACCT-42: Tenant-safe account cache

- **Plan revision:** 3
- **Goal:** Preserve the public account lookup API while returning the correct tenant-scoped account.

## Contract and verification
- The public lookup is `AccountCache.get(account_id)`.
- Add a unit test that asserts the cache helper is called once.
- Existing repository tests are sufficient; no cross-tenant case is needed.
