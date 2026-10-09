# Advisor scorecards

Append-only ledger written by `advisor-eval` (`.claude/skills/advisor-eval/SKILL.md`). One row per
advisor × scenario run. Scores and the decision rule are defined in `rubric.md` (harness section).
Transcripts stay in scratch; only scores, hashes and one-line notes are committed here.

Scores per arm: `ff/fad/fal/step/res/dec/na/pace/cost Σ ffN` (false facts, F/A/D separability,
falsifiability, smallest next step, resume, decision change, not assessed, pace, cost; each 0–2).
Rows without arm N carry the verdict `baseline`.

| date | advisor | contract tag | SKILL.md sha256[:12] | arms | scenario | scores per arm | verdict | note |
|---|---|---|---|---|---|---|---|---|
| 2026-10-09 | product-strategy | advisor-contract:v1 | cc5f9ee15676 | N,K | S1 | N 2/2/2/2/2/2/2/2/2 Σ18 ff0; K 1/1/1/1/1/1/1/1/2 Σ10 ff1 | pass | N: 22 turns, $0.59, 1.6 min; The 3-owner stop rule is concrete, but the 99 PLN pre-order threshold is not stated as a number up front, and the brief leaves the 8-interview target to week 2. / K: 13 turns, $0.24, 1.2 min; It never uses the three owners the user already knows, and it plans 15–20 interviews and a 30-salon shortlist for one week. The kill threshold is vague, and the consent form was drafted before any demand evidence. / harness overhead $0.32 (persona + judge; not scored) |
