# ADR-001: Build only what Anthropic's plugins do not cover

- Date: 2026-10-30
- Status: Accepted
- Type: product
- Supersedes: none
- Source: maintainer session (comparison with Anthropic's plugins)

## Context

Anthropic ships `knowledge-work-plugins` with `engineering` (10 skills) and `product-management` (8 skills),
reviewed at commit `2574e29`. They are one-shot templates for a PM or engineer inside a team, with connected
tools (Jira, Linear, Slack, analytics) and enough data. Several overlap with ours:

| Anthropic | Ours |
|---|---|
| `write-spec` | `/product-spec` |
| `metrics-review` | `/product-metrics` |
| `competitive-brief` | `/market-research` |
| `synthesize-research` | `/validate-product` |
| `product-brainstorming` | `/product-strategy`, `/product-red-team` (theirs fits before ours) |
| `code-review`, `testing-strategy`, `debug`, `architecture`, `deploy-checklist` | baseline agents, `/ship`, `/solution-architecture`, `/launch-readiness` |

What they lack and Agent Army has:

1. A 14-stage journey where each advisor reads the previous records; nothing in theirs persists between sessions.
2. Evidence discipline: facts vs assumptions, predictions with kill thresholds written before results.
3. No outward actions: advisors never send, publish or spend.
4. Repo-tailored engineering: `bootstrap` agents, strict TDD in `/ship`, enforced hooks.
5. Many tools: Claude Code, Codex, Copilot, Cursor, Gemini, OpenCode; theirs are Claude only.

## Decision

1. Invest only in what sets Agent Army apart: the advisor contract and evidence register, hand-offs between
   stages, first customers and revenue vs plan, `/ship` and `bootstrap`.
2. Do not grow generic templates (PRD layout, competitor matrix, metric glossaries, roadmap formats).
3. Do not add team-work skills: `stakeholder-update`, `roadmap-update`, `sprint-planning`, `standup`.
   Priorities go through ADRs, plans through `/delivery-plan`.
4. Where both packs are installed, call our skills by name. If the account allows disabling single plugin
   skills, disable `write-spec`, `metrics-review`, `competitive-brief` and `synthesize-research` in repos
   that use Agent Army.

## Basis

Comparison of both plugin packs at `2574e29` with this package on 2026-10-30. "Ours is better" on the
overlapping skills is judgment, not measurement (see ADR-002).

## Alternatives considered

- **Replace our overlapping skills with Anthropic's.** Rejected: they break the shared records and the
  evidence rules that tie the journey together.
- **Add Anthropic's team skills to the package.** Rejected: the audience is a solo founder, not a team.

## Consequences

- A smaller surface to maintain; generic parts may age relative to Anthropic's.
- Overlapping triggers can route a request to the wrong pack when both are installed.

## Revisit when

1. Quarterly review of Anthropic's plugins, next on 2027-01-30. Remove any skill of ours that theirs now
   covers as well, keeping the contract.
2. On real work that needs an overlapping skill, run ours and theirs once on the same request and compare.
   If theirs is as good, simplify or remove ours.
3. Once a product has paying customers (stage 13): add one incident-runbook rule to `/launch-readiness`
   (who checks what, rollback, what to tell customers, a short postmortem), not a new skill.

## Implementation

not started
