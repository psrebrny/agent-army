# Red team: Agent Army

## brief.md (2026-10-30)

Target: `brief.md` after the market research (MR-1 to MR-21). The load-bearing claims are the two advantages
(A-4, A-5), that someone outside the maintainer wants this (A-2) and that people can find and install it (A-6).

### Ranked weaknesses

| ID | Fails if … | impact | likelihood | cheapness | class | test or mitigation | kill criterion | status |
|---|---|---|---|---|---|---|---|---|
| R-1 | a newcomer cannot get a working Army in their own repo within 15 minutes from the README, without help. Steelman: a one-time setup buys agents tailored to the repo (A-5) | high: every other test needs installed users | medium: APM plus `bootstrap` plus tool choice is several steps (MR-16: rivals install with one command) | high: one timed install | within 30 days | 3 people install it on a repo of their own while timed, at least 1 of them not the maintainer | stop feature work and simplify the install if 2 of 3 do not finish within 15 minutes | open |
| R-2 | nobody finds it: install through APM only, no marketplace listing, no author audience. Steelman: a good open-source repo spreads on GitHub | high: no users, no evidence for A-2 to A-5 | high: the largest rivals sit in official marketplaces and grow through newsletters, books or video (MR-16, MR-17) | medium: a marketplace manifest is a `fix` work item | within 30 days | test A-6: publish a Claude Code and Codex marketplace install, post once where solo founders gather | if fewer than 10 installs in 30 days, distribution is the bottleneck: no new skills until it is solved | open |
| R-3 | the maker's own use is the only evidence, so "it works" is the maker grading their own tool; no evaluation since ADR-002. Steelman: the maintainer's use is real behavior on real work | high: every advantage claim rests on it | high: no outside user recorded (Unknowns) | high: one outside user | within 30 days | run A-1, and get at least one outside user through stages 1–3 before claiming A-4 or A-5 | no advantage claim in README or posts until one outside user's result is recorded as an `F` | open |
| R-4 | founders want speed, and facts vs assumptions, kill lines and send cards feel like bureaucracy. Steelman: discipline stops them from building what nobody wants | high: the product side's reason to exist | medium: comparisons already call Spec Kit and BMAD heavy (MR-14) | medium: needs 5 founders (A-2) | track | test A-2; watch where people stop, not what they say | if fewer than 3 of 5 reach stage 3, add a light mode before any new advisor | open |
| R-5 | one maintainer cannot keep 21 skills across 6 tools current while the tools change every month; superpowers has a company and a community behind it (MR-1). Steelman: `check.sh`, `smoke.sh` and ADR-001 keep the surface small | medium: slower releases, broken installs | medium | high: track time | track | log hours spent on tool compatibility per month | if compatibility takes more than half of maintenance time for 2 months, drop the least used tools | open |

The rest, in one line: Anthropic or OpenAI could make `/init` generate tailored agents natively (strategy; watch in
the quarterly review of ADR-001); the token cost of our flow vs superpowers is unknown (MR-15).

### What holds

- **The combination looks unique so far:** no tool found that generates repo-tailored agents with blocking hooks
  (MR-19 to MR-21), and none ties one evidence register from idea to revenue (MR-9 to MR-12). Both are still `A`
  (A-7, A-4).
- **The no-send, no-invented-proof rule** is a clear line against Anthropic's marketing templates (MR-18).
- **Scope is narrow on purpose** (ADR-001), which limits R-5.

### Not assessed

- Ethics: advisors never send, publish or spend, so the risk is low; not reviewed further.
- Viability: no revenue model by decision (brief, Out of scope).
- Real user behavior and token cost: no data yet.

### Hand-offs

- `/validate-product`: tests for R-1 (timed installs), A-2 and A-5.
- `/delivery-plan`: a `fix` work item for a Claude Code and Codex marketplace install (R-2), once A-6 is accepted
  as worth testing.
- Brief Change proposal: add "maintenance capacity across 6 tools" to Unknowns (R-5).

### Conversation state

- Settled: target `brief.md`; R-1 to R-5 ranked (2026-10-30).
- Open: which test to start first.
- Settled: R-1 first; test prepared as E-1 in `validation.md` (2026-10-30).
- Next: R-2 after E-1's result.
