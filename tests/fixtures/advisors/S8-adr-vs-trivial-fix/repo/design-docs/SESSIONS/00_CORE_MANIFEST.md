# SESSIONS: Persist sessions in Postgres

## Planning Session
- **Decision log:**
  - D1 Store sessions in the existing Postgres database instead of process memory, because every deploy
    logged all users out. Redis was rejected: one more service for a solo maintainer.
  - D2 Expire sessions after 30 days of inactivity.
