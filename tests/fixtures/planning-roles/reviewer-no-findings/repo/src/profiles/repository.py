def list_profiles(owner_id: str, archived: bool = False) -> list[dict]:
    return database.query_profiles(owner_id=owner_id, archived=archived)
