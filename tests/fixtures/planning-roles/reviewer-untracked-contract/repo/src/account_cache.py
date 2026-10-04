class AccountCache:
    def get(self, tenant_id: str, account_id: str) -> dict:
        return self.store[(tenant_id, account_id)]
