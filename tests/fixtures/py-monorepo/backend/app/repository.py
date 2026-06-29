"""The ONLY layer allowed to touch app.db. Services depend on this, never on db directly.

LAW (repo-wide): all persistence goes through a Repository. A service that imports
`app.db` or mutates the store directly is a bug — route it through AccountRepository.
"""

from app import db


class AccountRepository:
    def balance(self, account_id: str) -> int:
        return db._get(account_id)

    def credit(self, account_id: str, amount: int) -> None:
        db._set(account_id, db._get(account_id) + amount)

    def debit(self, account_id: str, amount: int) -> None:
        db._set(account_id, db._get(account_id) - amount)
