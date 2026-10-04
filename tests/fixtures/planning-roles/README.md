# Planning-role evaluation fixtures

These cases test evidence handling and review judgment independently of the two role prompts. For a blind run, give the role only `request.md` and the sibling `repo/` files it is allowed to inspect. Keep each `expected.md` with the evaluator; never include it in the role packet. Compare observable claims and decisions, not wording.

The cases cover contradictory evidence, an unavailable source, a relevant untracked file, a valid plan with no justified findings, and interactive planning/resume. They are manual LLM-evaluation inputs; `scripts/check.sh` validates role-file structure but does not claim to execute these scenarios.

`architect-current-baseline/request.md` is the fixed task packet to use with the existing `architect.md` before changing its interview behavior. The current architect source remains unchanged. No model-generated baseline output has been captured in this workspace, so the baseline comparison is still an explicit PR 1.3 follow-up rather than a claimed result.
