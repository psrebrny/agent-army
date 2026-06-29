# Ledger

Tiny money-transfer demo. A **monorepo** with two deployables:

- `backend/` — Python service (FastAPI-style), exposes account + transfer operations.
- `frontend/` — React/TypeScript SPA that talks to the backend.

This repo is a **fixture for the Agent Army smoke test** — it carries deliberately
"planted" architectural laws so an automated check can verify that `/bootstrap`
extracted them. See `tests/fixtures/README.md` in the source repo for the planted facts.

## Run

```bash
# backend
cd backend && pytest

# frontend
cd frontend && npm test     # vitest
```
