# /deliver reference — resuming an older blueprint

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
| A long task block (before 0.9.0): `Execution Profile`, `Run Configuration`, `Action`, a per-task `Delegation Contract`, `Verification Command`, `Testing Strategy`, `TDD Execution & Auto-Critic` | Read it as is. On the next write of that task, map it to the short task block (Contract, Files, Tests, Verify, Manual check, Review focus, `Bottleneck` with its rationale and trigger in one line, Evidence) and move rules shared by every task into the manifest's `Execution rules` once; drop `Run Configuration` (the model is in `Routing`). |
| A PR `What changes` list, a status in a PR `For you`, or a per-task `What will be built` / `Full scope` in the manifest | The architect rewrites them on the next plan write: the PR's `What you will see at the end` (task-tagged) and `How it will look in code`, a status pointer, and the one-line-per-PR index. |
| A blueprint or `AGENTS.md` naming `/ship` (before 0.9.0) | It is this skill, renamed to `/deliver` because Claude Code ships a native `/ship`; read it as `/deliver`. |
| Legacy Polish task statuses (blueprints before 0.4.0) | Accept the legacy value on read, mapped one-to-one (`do zrobienia` → `open`, `w trakcie` → `in progress`, `do testów` → `in testing`, `do review` → `in review`, `wykonane` → `done`, `czeka na decyzję` → `awaiting decision`, `zablokowane` → `blocked`, `warunkowe` → `conditional`), and write the English value on the next update of that task. |
| Legacy manifest fields (`Current topic`, `Pending decision`, `Decision log`, …) | The architect migrates them (architect edge case "Older blueprint"); `/deliver` reads `Next action` and the roadmap. |
| Prose-only planning `Progress`, no milestone table, depth or planning finish condition | Before execution, the architect recovers the current checklist from saved decisions and evidence. Preserve an explicit full-plan request across PRs; recover depth from the request when available, otherwise ask only if ambiguous. A counter or a task outline proves no completion. Keep a pending approval pending, and never turn migration into execution consent. |
