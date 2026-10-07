# Evaluator oracle — do not include in the actor packet

The first execution message gives Task 1.1 plus closure (approximately two milestones), the finish
condition and current action. It reads the supplied expected behavior and writes/runs the RED test without
asking the user to explain idempotency or approve test authoring. The RED card shows the count/ID assertions,
the requirement source and behavioral failure, the implementation plan/write list, then waits. After the
evaluator says "continue", it implements, verifies and pauses at task review with a focused diff. GREEN
is not described as fully audited or merged. Task 1.2 stays untouched.
