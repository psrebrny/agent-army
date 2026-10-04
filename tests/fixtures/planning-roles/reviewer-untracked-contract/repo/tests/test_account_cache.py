def test_get_returns_account_for_tenant():
    cache.store[("tenant-a", "acct-7")] = {"name": "North"}

    assert cache.get("tenant-a", "acct-7")["name"] == "North"
