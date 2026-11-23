# Evaluator oracle — do not send with the role packet

- Read the saved manifest before acting. Delivery is settled; planning is not finished after that one answer.
- Preserve `all-tasks` for the entire two-PR feature. Interactive execution does not reset it to `next-task`.
- Persist the current question, ordered milestones, their statuses/evidence, finish condition and next action
  before asking. The progress card is derived from these rows, not invented from message count.
- Ask only about correct report links. Recommend getting an authoritative type or ID-only route from the
  owning service rather than guessing the report type. Environment and unnamed rows remain later questions.
- Evaluator answer 1: "Ask the service owner for an ID-only link; do not change their API in this task."
  Record this scope decision, not an invented route. The external contract remains unverified.
- Evaluator answer 2: "Use the same environment as the data source." Record that answer once; then ask only
  about unnamed reports, with `[Lack of name]` as the recommendation.
- Evaluator answer 3: "Yes, use that placeholder." Save it and proceed to composition, not implementation.
- Detail every executable task across both PRs with files, behavior, checks and a manual check. If necessary
  implementation sources or verification commands are unavailable, record that gap rather than inventing them.
  Write the
  second PR file during planning; a rule against speculative detail does not forbid agreed full-plan detail.
- If the owner has not supplied a route, keep the dependent task blocked with its owner, missing evidence and
  unblock condition. Ask whether to defer it from planning completion and execution, or wait. Do not claim
  that the original whole-feature finish condition has been met, or silently plan/build only the first PR.
- Only an explicit deferral permits narrowing the required planning scope. Save that decision and update
  detail policy, finish condition and milestones together; retain the blocked delivery row.
- A returned architect handoff with `STATUS: done` does not make an incomplete manifest executable.
- After all required detail is saved, obtain independent review of the current plan; persist the verdict and
  revision in `reviews/plan-review.md`. A finding reopens only the affected milestone(s); re-review corrections.
- Missing/stale review is not success. If independent context is unavailable, disclose it without fabricating
  approval; only `/ship` may handle its existing explicit review-limitation decision.
- `ready` means the plan can be presented for the separate blueprint/scope gate. A request to continue
  planning, an answer to a planning question, or review approval alone never authorizes tests or source edits.
- At the gate, summarize ordered outcomes, exclusions and risks in chat. Wait for explicit blueprint and
  execution-scope approval before starting even the small placeholder fix.
- For a cold resume, give the actor only the updated repo and request again. It must continue at the saved
  milestone without repeating settled questions, losing the override, or resetting the count.
- Assess saved files and actual tool calls, not private reasoning. Do not claim this manual scenario ran
  merely because the deterministic structural checks pass.
