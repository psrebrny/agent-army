## PR #1: Audit log

## For you
- **Status:** in review, nothing built yet
- **What you will see at the end:**
  - Audit log tab with its title (1.1)
  - Table of entries with Name and Created (1.2)
  - An error banner with Retry
  - Page sizes 10/25/50 (1.3)
- **How it will look in code:**
  ```text
  src/audit/ (1.1)
  /audit route → AuditLogPage (1.1) → useAuditLog (1.2) → auditApi → GET /api/audit
    └─ AuditLog{Content,Table} (1.2)
  Key decisions: the page owns pagination state
  ```

### Task 1.1: Tab and page
- **Task status:** open
- **Contract:** `/audit` route renders `AuditLogPage` with heading "Audit log".

### Task 1.2: Table
- **Task status:** open
- **Contract:** mirror Event definitions: `AuditLog{Content,Table}` show columns Name and Created; on error show
  a snackbar.
  - **Mirrors:** `src/events/definitions/`
- **How it will look in code:** `AuditLogContent → AuditLogTable`

### Task 1.3: Page sizes
- **Task status:** open
- **Contract:** page sizes 10/25/50 held in `AuditLogPage` state.
