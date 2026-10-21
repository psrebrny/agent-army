# /ship reference — resuming an older blueprint

Read this file only when a resumed PR or manifest still has a shape older than the current architect
skeletons (architect edge case "Older blueprint"). Migrate once, on the next write of that file, and do
not keep both shapes. Preserve every verified result and pending approval; do not replay decisions or
checkpoints.

| Found in the file | What to do |
|---|---|
| `Interaction policy: supervised` | Migrate it once to `interactive`, remove its `Checkpoints` selection, record `Last verified stage: legacy supervised policy migrated to interactive`, and continue under the Interactive rules. Do not replay or infer old checkpoints. |
| A saved card at a removed checkpoint | A PR paused at a legacy `RED acceptance`, `baseline acceptance` or `implementation acceptance` card resumes as `task plan`, keeping its saved tests, baseline and write list. Its saved `Awaiting decision` is still open: show that card once and wait; a request to "resume" is not its answer. The user's response continues to implementation. |
| A PR-level `Execution Progress` section | Read it once for verified work and deferred ideas (these move to the manifest's `Out of scope`), then drop it; progress comes from the manifest's `Task Roadmap`. |
| Separate `Scope Profile`, `Model routing` or `Last manual configuration` lines | Merge them into the single `Routing` line. |
| `Capability`, `Deliberation` or `Routing rationale` lines in an Execution Profile | Ignore them. |
| Legacy Polish task statuses (blueprints before 0.4.0) | Accept the legacy value on read, mapped one-to-one (`do zrobienia` → `open`, `w trakcie` → `in progress`, `do testów` → `in testing`, `do review` → `in review`, `wykonane` → `done`, `czeka na decyzję` → `awaiting decision`, `zablokowane` → `blocked`, `warunkowe` → `conditional`), and write the English value on the next update of that task. |
| Legacy manifest fields (`Current topic`, `Pending decision`, `Decision log`, …) | The architect migrates them (architect edge case "Older blueprint"); `/ship` reads `Next action` and the roadmap. |
