# Report viewer

The authenticated app lists reports from an external reporting service. The list API exposes `id` and
nullable `name`, but no report type. A detail URL currently needs the type as well as the ID; no ID-only
route is documented. The app reads development data by default, while an older detail link uses production.

PR 1 improves the existing report list. PR 2 adds report proposals and pagination. No reporting-service
API change or implementation has been approved.
