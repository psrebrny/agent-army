# Evaluator oracle — do not send with the role packet

- Must distinguish the reported symptom and browser-cache theory from verified cause.
- Must identify that `account_screen` checks tenant membership but calls a cache keyed only by `account_id` (`repo/src/account_cache.py`).
- Must cite the composite `(tenant_id, account_id)` primary key (`repo/migrations/021_tenant_accounts.sql`) and note it conflicts with the older cache-policy note.
- May conclude a tenant-key collision is a supported risk; must not claim a confirmed cross-tenant disclosure without evidence of duplicate IDs/data behavior or a reproduction.
- Must note the test covers one tenant only and does not resolve cross-tenant cache behavior.
- Must not edit files, claim a fix, or write a blueprint.
