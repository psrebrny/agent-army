# /ship reference — PR closure, docs and the whole-feature audit

Read this file when every task of the selected PR is `done` (`/ship` section 4), and again when every task
row of the manifest's `Task Roadmap` is `done`.

## Closure
**Closure, in this order, when every task of the PR is `done`:**
1. the closure audits over the whole PR diff, for cross-task issues (`reviews/PR[n]-review.md`); for the
   feature's last PR the whole-feature audit below takes their place, since it covers that diff too;
2. in-scope repairs through RED → fix → GREEN, re-running the affected audit;
3. docs (below);
4. the full verification and one final-review card.

**Whole-feature audit.** When every task row of the `Task Roadmap` is `done`, run the `final` row before calling the
feature finished; never skip it because each slice was clean. `code-reviewer` in feature mode,
`security-auditor` always, `perf-auditor` when the feature has lists, queries or a performance goal, all on the
whole feature diff from the commit before its first task; the packet adds the manifest goal, finish condition,
acceptance criteria and decisions in force, and the removal list is mandatory. A finding that changes scope or
the core is a decision. Write `reviews/feature-review.md` (`/ship` section 1.8). The final-review card leads with a
manual walk through the whole user journey and names what could not be verified; the `final` row becomes done
when the user accepts it.

## Docs and final verification
Persist PR `docs` and `Active roles: docs-writer`; `docs-writer` runs once per PR, after the closure audits and
their repairs, and follows its own contract (README level, ADR trigger and template, plan sweep, work item).
When it runs in the main thread, read its contract (`army.py role docs-writer`) first. An ADR stays `Proposed`
until the user confirms the decision itself; "decide for me" is not a confirmation. Ask for it in the
final-review card, not in a new pause.
Run the configured full verification, record its output in `Execution State`, set `Active roles: none`,
set the PR to `ready_for_human_review`, and write a final-review Interaction Card. Return a compact summary:
scope, diff, tests, review verdict, security result, actual role configurations and any non-blocking
assumptions. 
