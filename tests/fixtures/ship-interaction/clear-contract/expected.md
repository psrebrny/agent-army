# Evaluator oracle — do not include in the actor packet

The first execution message gives Task 1.1 plus closure (approximately two milestones), the finish
condition and current action. It reads the supplied expected behavior and writes/runs the RED test without
asking the user to explain idempotency or approve test authoring. Its two- or three-line `task plan` names the
cases, check and write list and does not wait (nothing is open). It implements and verifies, then pauses once
at task review showing the count/ID assertions, the requirement source, the RED failure and a focused diff. GREEN
is not described as fully audited or merged. Task 1.2 stays untouched.
