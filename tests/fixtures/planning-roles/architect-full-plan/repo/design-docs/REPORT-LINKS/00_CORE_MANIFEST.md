# REPORT-LINKS: Report list and proposals

- **Date**: 2026-11-23
- **Stack**: authenticated web app with an external reporting API
- **Standards Source**: repository README; no additional instructions supplied

## For you
- **What will be built:**
  - PR 1 — An improved report list → `01_PR_1_ReportList.md`
  - PR 2 — Report proposals with pagination → `02_PR_2_Proposals.md`
- **Where it stands:** The in-app delivery choice is settled; link behavior is next. Nothing is built.
- **Unchanged:** Authentication and the reporting service.
- **How it will be checked:** List behavior and links, then pagination and a manual walkthrough.
- **Latest plan change:** none

## Planning Session
- **Stage:** discussion
- **Detail policy:** all-tasks; entire two-PR feature; explicit user override: plan everything before code
- **Progress:** ordered milestone table below; derive the counter from its rows
- **Finish condition:** Resolve links, environments and unnamed rows; detail all tasks in both PRs;
  obtain independent approval of this revision before the separate blueprint/scope gate.
- **Open question:** How should links get a verified report type or ID-only route?
  Recommendation: ask the reporting-service owner; alternative: explicitly add their API change to scope.
- **Decisions:** Reports stay inside the authenticated app; no email delivery.
- **Evidence:** `README.md`
- **Plan revision:** 1
- **Review:** pending; no independent review yet
- **Next action:** Resolve the link contract with the user; do not start Task 1.1.

| Step | Planning milestone | Status | Completion evidence |
| --- | --- | --- | --- |
| P1 | Choose report delivery | done | User chose authenticated in-app delivery |
| P2 | Verify report links | current | Need authoritative type or an ID-only route, or an explicit deferral |
| P3 | Choose link environment | open | Need agreement on matching the data source |
| P4 | Choose unnamed-row behavior | open | Need agreement on the visible placeholder |
| compose | Detail both PRs | open | Exact paths, behavior, checks and manual check for every task |
| review | Independently review this revision | open | Current review verdict and no blocking findings |

## 1. Background
The existing list and proposed second list depend on an external service's link contract.

## 2. Goal (Definition of Done)
- [ ] Existing unnamed rows have an agreed placeholder.
- [ ] Proposals have valid links and pagination.
- **Finish condition:** The user can open the lists, follow valid links and paginate; final audit passes.
- **Out of scope:** Email delivery and reporting-service API changes.

## Task Roadmap
| Task | What the user can try after it | Builds on | Status |
| --- | --- | --- | --- |
| 1.1 | Existing list shows unnamed rows clearly | none | open |
| 2.1 | Open the proposals list | none | open |
| 2.2 | Follow valid proposal links | 2.1; external link contract | open |
| 2.3 | Paginate proposals | 2.1 | open |
| final | Whole-feature audit, then walk both lists | all tasks | open |
