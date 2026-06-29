"""Test style: plain pytest, arrange/act/assert, a fake repo as the seam.

This is the idiom the tester agent must mirror: inject a fake AccountRepository,
never reach into app.db from a test.
"""

import pytest

from app.repository import AccountRepository
from app.service import InsufficientFunds, TransferService


class FakeAccounts(AccountRepository):
    def __init__(self, balances: dict[str, int]) -> None:
        self._b = dict(balances)

    def balance(self, account_id: str) -> int:
        return self._b.get(account_id, 0)

    def credit(self, account_id: str, amount: int) -> None:
        self._b[account_id] = self.balance(account_id) + amount

    def debit(self, account_id: str, amount: int) -> None:
        self._b[account_id] = self.balance(account_id) - amount


def test_transfer_moves_funds() -> None:
    accounts = FakeAccounts({"a": 100, "b": 0})
    TransferService(accounts).transfer("a", "b", 30)
    assert accounts.balance("a") == 70
    assert accounts.balance("b") == 30


def test_transfer_rejects_overdraft() -> None:
    accounts = FakeAccounts({"a": 10})
    with pytest.raises(InsufficientFunds):
        TransferService(accounts).transfer("a", "b", 50)
