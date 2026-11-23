# Planning-role evaluation fixtures

These cases test evidence handling and review judgment independently of the two role prompts. For a blind run, give the role only `request.md` and the sibling `repo/` files it is allowed to inspect. Keep each `expected.md` with the evaluator; never include it in the role packet. Compare observable claims and decisions, not wording.

The cases cover contradictory evidence, an unavailable source, a relevant untracked file, a valid plan with no justified findings, and interactive planning/resume including an approximate milestone counter, explicit finish condition, and transparent re-estimation after scope changes. They are manual LLM-evaluation inputs; `scripts/check.sh` validates role-file structure but does not claim to execute these scenarios.

`architect-full-plan` covers cold resume after the first decision with an explicit whole-feature detail
override across two PRs, an external link blocker, composition, independent review and the separate execution
gate. Its expected file supplies follow-up answers; do not include those answers in the actor's packet.
`architect-resume` deliberately retains a legacy checkpoint to exercise non-destructive migration.

`architect-current-baseline/request.md` is a fixed task packet for a paired baseline comparison of interview behavior. No model-generated baseline output has been captured in this workspace, so the baseline comparison remains an explicit PR follow-up rather than a claimed result.
