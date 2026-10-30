# Brief: Agent Army

## Product

Agent Army is an open-source package of agents and skills for AI coding tools. Details: `.apm/README.md`.

- **Tools:** Claude Code, Codex, Copilot, Cursor, Gemini, OpenCode.
- **Engineering:** `bootstrap` generates repo-tailored agents; `/ship` delivers tasks with strict TDD.
- **Product:** sixteen advisors take one founder from an idea to the first revenue through 14 stages, with every
  claim traced to evidence.

## Audience & initial segment

1. **Initial segment:** the maintainer's own projects (A-1).
2. **Next:** solo founders who build a product with AI coding tools (A-2).

## Problem

Not yet stated from real conversations; see Unknowns.

## Alternatives & advantage

Alternatives (details and sources: `market-research.md`):

- **Engineering:** superpowers, spec-kit, gstack, OpenSpec, BMAD; generic skills, TDD by instruction (MR-1 to MR-5,
  MR-19).
- **Idea to money:** pm-skills with PM Brain, Minimalist Entrepreneur, spec-kit idea assessment (MR-9 to MR-12).
- **Anthropic:** `knowledge-work-plugins` engineering, product-management and marketing templates for teams (F-1,
  MR-18).

Intended advantage. TDD and many supported tools are table stakes (MR-1), not advantages. Two claims remain:

1. **Repo-tailored Army:** `bootstrap` generates agents for the repo, with hooks that block (A-5, A-7).
2. **One evidence register from idea to revenue:** facts vs assumptions, predictions with kill lines (A-4).

What we leave to others: ADR-001 (D-1).

## Revenue model

None now. Whether to monetise at all is open (Unknowns).

## Out of scope

- Monetisation, until the revisit trigger in Unknowns.
- Team-work skills (stakeholder updates, roadmaps, sprint planning, standups): ADR-001.
- Model-based advisor evaluation: ADR-002.

## Customer language

None recorded yet.

## Register

| ID | Type | Statement | Source | Evidence level | Status | Date |
|---|---|---|---|---|---|---|
| F-1 | F | Anthropic ships `knowledge-work-plugins` with `engineering` (10 skills) and `product-management` (8 skills): one-shot team templates with connectors, no persistent records | github.com/anthropics/knowledge-work-plugins @ `2574e29` | AI opinion / third-party data | holds | 2026-10-30 |
| A-1 | A | The maintainer's own projects are a usable first test bed. Test: run the product journey on one real project for 2 weeks; at least 3 advisor results change a decision | maintainer | — | open | 2026-10-30 |
| A-2 | A | Solo founders building with AI coding tools want a guided, evidence-based path from idea to revenue. Test: 3 of 5 founders who try it reach stage 3 within 2 weeks | maintainer | — | open | 2026-10-30 |
| A-3 | A | On overlapping tasks our advisors give better decisions than Anthropic's generic skills. Test: ADR-001 revisit 2, side by side on real work | maintainer | — | open | 2026-10-30 |
| A-4 | A | The shared evidence register gives better product decisions than stage-by-stage skills. Test: on one real decision, run our advisors and pm-skills on the same input; ours changes or stops the decision with a recorded fact, theirs does not | market-research | — | open | 2026-10-30 |
| A-5 | A | Repo-tailored agents with blocking hooks need fewer fix rounds than generic skills. Test: on one real repo, 3 tasks with `/ship` and 3 comparable tasks with superpowers; `/ship` needs fewer review fix rounds on at least 2 of 3 | market-research | — | open | 2026-10-30 |
| A-6 | A | People install agent packages from Claude Code and Codex plugin marketplaces rather than APM. Test: offer a marketplace install and compare installs over a month | market-research | — | open | 2026-10-30 |
| A-7 | A | No other package generates repo-tailored agents with enforced gates. Test: a manual search of the Anthropic and Codex plugin directories and GitHub topics finds no such tool | market-research | — | open | 2026-10-30 |
| D-1 | D | Build only what Anthropic's plugins do not cover: [ADR-001](../adr/001-focus-on-differentiators.md) | maintainer | — | accepted | 2026-10-30 |
| D-2 | D | No model-based advisor evaluation: [ADR-002](../adr/002-no-model-based-advisor-evaluation.md) | maintainer | — | accepted | 2026-10-30 |

## Change proposals

| proposed by | change | basis IDs |
|---|---|---|
| market-research | Alternatives: add superpowers, spec-kit, gstack, OpenSpec, BMAD (engineering); pm-skills with PM Brain, Minimalist Entrepreneur, spec-kit idea assessment (product) — accepted 2026-10-30 | MR-1 to MR-12 |
| market-research | Advantage: drop "TDD" and "many tools" as differentiators; keep two claims as `A` rows with tests: the shared evidence register across stages, and repo-tailored agents with enforced gates — accepted 2026-10-30 | MR-1, MR-9, MR-11, MR-19 |
| market-research | New `A`: people install agent packages from Claude Code and Codex plugin marketplaces rather than APM; test: offer a marketplace install and compare installs over a month — accepted 2026-10-30 | MR-16 |
| market-research | New `A`: no other package generates repo-tailored agents with enforced gates; test: a manual search of the Anthropic and Codex plugin directories and GitHub topics finds no such tool — accepted 2026-10-30 | MR-19 to MR-21 |
| product-red-team | Unknowns: add "maintenance capacity: can one maintainer keep 21 skills across 6 tools current?" — proposed | R-5 |

## Unknowns

- Whether to monetise. Not testable now: no outside users yet. Revisit when 10 people outside the maintainer
  use it on a real project.
- Who besides the maintainer has used or seen Agent Army, and what they did.

## Conversation state

- Settled: open source; the maintainer's own projects come first; no revenue model for now; the tests and
  thresholds of A-1 to A-3 (accepted 2026-10-30, not to be changed after results).
- Open: the problem in the words of real users; the segment beyond the maintainer; who besides the maintainer
  has used or seen it (asked twice, not answered yet).
- Settled: the four `market-research` Change proposals (accepted 2026-10-30); tests of A-4 to A-7 as written.
- Next step: `/product-red-team` attacks both advantages (A-4, A-5) and the setup cost of `bootstrap`; then start
  the A-1 test on a real project.
