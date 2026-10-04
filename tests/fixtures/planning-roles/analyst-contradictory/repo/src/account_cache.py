from functools import lru_cache


@lru_cache(maxsize=256)
def cached_account(account_id: str) -> dict:
    return database.fetch_account(account_id)


def account_screen(tenant_id: str, account_id: str) -> dict:
    membership.require_account(tenant_id, account_id)
    return cached_account(account_id)
