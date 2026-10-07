# RETRY: safe in-memory retries
## Goal
Identical retries return the original entry and append nothing. A different amount with the same key
raises ValueError and leaves the ledger unchanged. Two different keys produce two entries.
## Planning Session
- Stage: ready
- Plan revision: 1
- Review: APPROVED for revision 1 (synthetic prior-session fixture)
- Confirmed decisions: approved blueprint and Task 1.1 only; interactive mode
- Next action: execute Task 1.1
