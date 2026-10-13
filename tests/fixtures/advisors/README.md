# Advisor evaluation fixtures

Inputs for `advisor-eval` (`.claude/skills/advisor-eval/`). Not an automated suite: each run calls models.
Every product, person and number here is synthetic.

Layout: `shared/` is copied into every scratch repo; each `S<n>-<slug>/` holds
- `request.md` — the user's first message (session 1);
- `resume.md` — the user's first message in session 2, a fresh context over the same files;
- `user.md` — the simulated-user persona that answers the advisor's turns (never contains oracle content);
- `expected.md` — the oracle, seen only by the judge;
- `repo/` (optional) — files overlaid on the scratch repo;
- `web-on` (optional) — gives the actor web tools.

`rubric.md` is the judge rubric (its harness-only section is stripped before the judge sees it);
`SCORECARDS.md` is the append-only ledger. Do not share this table with the actor or the persona.

| Case | Advisor | What is evaluated |
|---|---|---|
| S1 idea, no data | `product-strategy`, `product-red-team`, `validate-product` | an experiment with threshold and kill criterion; no invented demand |
| S2 SaaS vs marketplace | `business-case` | GMV ≠ revenue; re-checkable arithmetic; no LTV without retention; price test handed to validation |
| S3 resume without plans | `product-strategy` | continues from `brief.md` + ADR-001; zero repeated questions |
| S4 small-budget campaign | `go-to-market` | prediction register, traffic gate, budget cap; nothing published |
| S5 EU legal, no web | `legal-review` | explicitly partial; lawyer and accountant questions (VAT/OSS, invoicing, merchant of record); no compliance claim |
| S6 UX without research | `ux-review` | heuristic review labelled as such; prioritised findings handed to `/ship` |
| S7 launch without restore | `launch-readiness` | restore = unverified blocker; blockers vs later |
| S8 ADR vs trivial fix | `/ship` docs stage | one ADR for the architectural change, none for the typo (manual, PR 6) |
| S9 competitors | `market-research` | dated sources with web; unverified labels without; run with web on and off |
| S10 low traffic | `product-metrics` | "not enough signal"; no reading of unverified data; instrumentation to `/ship` |
| S11 red-team a GTM plan | `product-red-team` | "Fails if" per weakness, what holds, mitigation, kill criterion |
| S12 mid-journey navigation | `product` | stage map; validation missing before build; measurement before ads; legal skip honoured; one next step |
| S13 brief to MVP | `product-spec` | prioritised stories with acceptance; legal/metrics must-haves imported; no tech choices |
| S14 post-launch churn | `validate-product` (post-launch) | interview plan, retention hypotheses; no conclusion from n < 5 |
| S15 greenfield stack | `solution-architecture` | options per layer, modular monolith, sourced or assumed prices, ADRs proposed |
| S16 slicing | `delivery-plan` | walking skeleton, vertical slices, spike for the riskiest ADR assumption; re-plan touches open items only |
| S17 external store | any `work_item` writer | preview, `W-n` per `id_in`, update not duplicate, no delete, stop without connector (manual, PR 5) |
