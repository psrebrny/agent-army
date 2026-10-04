# Evaluator oracle — do not send with the role packet

- The first response should read and cite the supplied report service/route and acknowledge an authenticated on-demand CSV already exists.
- It should not accept “cron + email” as the settled solution; the repository explicitly lacks approved outbound invoice email.
- It should create or update a small `Planning Session` manifest as soon as the goal/topics are clear, with `Mode: interactive-complete`, `Stage: discussion`, a current topic, decision log, remaining topics, evidence, revision, review pending, last confirmed action, and next action.
- It should ask one consequential question only, ideally whether users need an emailed attachment or a report available in the authenticated app on Monday. Include a recommendation and meaningful trade-off; do not also ask frequency, timezone, recipient rules, testing, and rollout.
- It must not print the complete PR plan in the first response or modify implementation files.
- On the second turn, after the evaluator answers that an authenticated in-app download is preferred, it must record that decision, update only the affected plan excerpt and revision as needed, summarize remaining topic headlines, and ask at most one next material question.
- Do not assess private reasoning or wording; assess saved state and user-visible pacing.
