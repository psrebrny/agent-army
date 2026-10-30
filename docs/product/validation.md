# Validation: Agent Army

## E-1: Timed install from the README (red team R-1)

| Field | Value |
|---|---|
| hypothesis | At least 2 of 3 people get a working Army in a repository of their own within 15 minutes, using only the README, without help |
| method | Timed install, watched or self-reported. Start: README open, nothing installed. End: "working Army" (below). Note every place they stop, and every question they would have asked |
| participants | 3 people with a repo of their own; at least 1 is not the maintainer. The maintainer's run uses a fresh repo and must not use knowledge beyond the README |
| thresholds | success: 2 of 3 finish within 15 minutes without help → R-1 holds, go to R-2. Kill: 2 of 3 do not finish → stop feature work and simplify the install first |
| status | prepared |
| result | — |
| decision | — |

**Working Army** means all three:

1. The package is installed for their tool (`apm install …`, README "Install once, bootstrap per repository").
2. `/bootstrap` finished and `.agent-army/config.json` exists in their repo.
3. One skill call reads the profile: `/ship` on a one-line task, or `/product`.

**What to record per person** (no names: P-1, P-2, P-3), in `docs/product/data/<date>-install-test.csv`:

```csv
person,maintainer,tool,had_apm_before,minutes_to_install,minutes_to_bootstrap_done,minutes_total,needed_help,stuck_at,note
P-1,yes,claude,yes,,,,no,,
```

- `stuck_at`: the README step or bootstrap question where they paused for more than a minute.
- `needed_help`: `yes` if anyone answered a question for them; that run counts as not finished.

What this can and cannot show: with n = 3 it catches a broken or confusing install, not how many people would
install. The maintainer's run is weaker evidence than an outsider's (R-3).

## Conversation state

- Settled: E-1 tests R-1 first (2026-10-30); thresholds above, fixed before any result.
- Open: who the 1–2 outside participants are.
- Next step: the maintainer runs E-1 on a fresh repo and pastes the CSV row.
