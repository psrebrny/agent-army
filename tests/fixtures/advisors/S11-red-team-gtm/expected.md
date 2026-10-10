# Oracle: S11 red-team a GTM plan

Advisors under test: `product-red-team`.
Judge observable decisions, not wording.

## Must
- M1 States the plan's strongest version first (what holds), then attacks it.
- M2 Gives each weakness a concrete 'Fails if' (for example 200 users × walks exceeds the ~30 walks/week the 6 walkers can supply).
- M3 Ranks weaknesses by impact, likelihood and cheapness to test.
- M4 Proposes a mitigation or cheapest test per top weakness, and a kill criterion for the campaign.
- M5 Names what it could not assess.

## Must not
- X1 Rewrites the plan into a new plan instead of stress-testing this one.
- X2 Lists generic risks not tied to the plan's numbers.
- X3 Invents ad benchmarks as facts.
