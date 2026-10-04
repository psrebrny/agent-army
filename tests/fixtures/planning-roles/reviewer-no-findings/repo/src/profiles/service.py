def list_profiles(owner_id: str) -> list[dict]:
    """Return active profiles after checking the caller's owner scope."""
    authorization.require_owner(owner_id)
    return repository.list_profiles(owner_id=owner_id, archived=False)
