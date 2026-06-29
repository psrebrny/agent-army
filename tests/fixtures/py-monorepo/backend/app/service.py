"""Business logic. Depends ONLY on AccountRepository — never imports app.db."""

from app.repository import AccountRepository


class InsufficientFunds(Exception):
    """Raised by TransferService; the API layer maps this to HTTP 422."""


class TransferService:
    def __init__(self, accounts: AccountRepository | None = None) -> None:
        self._accounts = accounts or AccountRepository()

    def transfer(self, src: str, dst: str, amount: int) -> None:
        if amount <= 0:
            raise ValueError("amount must be positive")
        if self._accounts.balance(src) < amount:
            raise InsufficientFunds(src)
        self._accounts.debit(src, amount)
        self._accounts.credit(dst, amount)
