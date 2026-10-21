# /ship reference — one-task delegation

Read this file when the user hands you the current task ("do this part yourself"), or when a resumed
`Execution State` has a `Temporary delegation` other than `none`.

"Do this part yourself" authorizes autonomous execution only for the current, unambiguous approved task
through verification. If "part" is ambiguous, clarify the task boundary first. Keep `Interaction policy:
interactive`; record `Temporary delegation` in `Execution State` with the task ID, the user's authorization,
approved write scope and return point (`task review`). Include this authorization in a delegated coder's
packet; the coder returns to `/ship` for verification/interactive review rather than owning the dialogue.
It is a bounded exception, not a third mode.

Within that task, preserve the usual RED/baseline evidence and the plan/write list, but settle the task's
in-scope choices yourself with a recorded rationale instead of waiting at `task plan` or `behavior decision`.
At verified completion clear the exception before presenting `task review` and wait. It never grants
permission to start the next task, skip checks, change scope, cross a risk boundary, or bypass blueprint/final
review/commit approval. Ordinary required stops still apply. Cancel the exception on user revocation, explicit
mode switch, or a scope/risk/contract stop; save the stop reason and do not silently reinstate it. A normal
verification failure permits in-scope repair under the existing stop rules, not unbounded retries. On resume,
honor only a saved authorization for the same still-active task; expire it when that task is verified or the
boundary no longer matches.
