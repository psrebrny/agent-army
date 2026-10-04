# BILLING-CSV: Weekly failed-invoice report

- **Date**: 2026-10-04
- **Stack**: Python service, detected from repository files
- **Standards Source**: `AGENTS.md`

## Planning Session
- **Mode:** interactive-complete
- **Stage:** discussion
- **Current topic:** report timing
- **Pending decision:** Should Monday's report appear automatically on the report page, or should a user request it when needed? Recommendation: automated availability, because the user asked for a weekly report; the trade-off is a scheduled generation path.
- **Remaining topics:** report timing; retention period
- **Decision log:** Finance chooses an authenticated in-app CSV download; do not email invoice data.
- **Evidence:** `src/reports/export_service.py`, `src/reports/routes.py`, `README.md`
- **Plan revision:** 2
- **Review:** pending; no blueprint review yet
- **Last confirmed action:** saved the in-app delivery decision
- **Next action:** resolve whether the report should appear automatically each Monday or be generated on demand
