def test_account_screen_returns_account_for_tenant():
    membership.allow("tenant-a", "acct-7")
    database.set_account("tenant-a", "acct-7", display_name="North")

    assert account_screen("tenant-a", "acct-7")["display_name"] == "North"
