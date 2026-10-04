def test_list_profiles_returns_active_profiles_after_authorization():
    authorization.allow_owner("owner-1")

    result = list_profiles("owner-1")

    assert result == [{"id": "p-1", "archived": False}]


def test_list_profiles_rejects_other_owner():
    authorization.deny_owner("owner-1")

    with raises(Forbidden):
        list_profiles("owner-1")
