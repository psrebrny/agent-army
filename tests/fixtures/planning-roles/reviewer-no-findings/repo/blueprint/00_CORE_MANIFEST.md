# PROF-18: Optional archived profiles

- **Plan revision:** 2
- **Goal:** Add an optional archived-profile filter; callers that omit it keep today's active-only result.

## Contract surfaces
- `list_profiles(owner_id, include_archived=False)` is the public service contract.
- The HTTP query parameter is optional and defaults to false.
- Existing response shape is unchanged.
