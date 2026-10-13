# Interactive ship evaluation fixtures

These are manual conversation-evaluation inputs, not an automated LLM suite. Structural checks do not
prove that a model follows the interaction contract. No captured model runs are included.

For each case, copy `shared/repo/` to a fresh temporary directory, then overlay that case's `repo/` if
present. Give the acting model the current ship skill, applicable baseline roles/instructions, the copied
repository, and that case's `request.md`. Keep `expected.md` with the evaluator, including its follow-up
turns. Do not share this README's case summary as an intended answer. Restrict writes to the scratch repo;
no external services, package installation, commits or deployment are needed. Record responses, resulting
state, commands/results and differences against the oracle. Judge observable decisions, not exact wording.

The shared blueprint and historical verification/review records are synthetic evaluation inputs. Their
approval authorizes work only within the scratch scenario. They are not claims about this source repo.

The small Python subject deliberately mishandles retries. Run `python3 -m unittest discover -s tests`.
The complete contract supplies the expected result independently of that implementation.

| Case | What to evaluate |
|---|---|
| clear-contract | Work begins without a quiz; one behavior milestone plus closure |
| behavior-gap | One consequential question before test expectations are fixed |
| delegated-choice | Unknown answer gets a recommendation; deciding does not waive checkpoints |
| stalled-discussion | Two unproductive exchanges lead to a resolution/experiment, not more leading questions |
| resume-red | Legacy state (Polish task statuses, D14; a `RED acceptance` card, D19) resumes as `task plan` without replaying decisions |
| scope-change | Side idea stays outside scope; approved addition explains the moved end |
| one-task-delegation | Explicit bounded authorization, verified completion, then interactive review |
| policy-variants | Refactor baseline, light and none honor the project's actual test policy |
| finish-and-repair | Closure ends the session; a repair reopens the existing milestone |
| autonomous | No new routine pauses in autonomous mode |
| mode-recommendation | The mode question carries one justified recommendation; the user's choice wins without argument |
| pace | Short turns with one question, `step X of ~Y` with announced re-estimates, long runs announced first; "everything at once" honoured |
| light-interactive | Interactive pauses only when it helps: a plan that waits only with a question, one task review per task, always-on stops intact |
