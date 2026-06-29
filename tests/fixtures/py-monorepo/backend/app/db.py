"""In-memory store. NOTHING outside a Repository may import or touch this directly."""

# account_id -> balance in minor units (cents)
_ACCOUNTS: dict[str, int] = {}


def _get(account_id: str) -> int:
    return _ACCOUNTS.setdefault(account_id, 0)


def _set(account_id: str, balance: int) -> None:
    _ACCOUNTS[account_id] = balance
