# Advisor scorecards

Append-only ledger written by `advisor-eval` (`.claude/skills/advisor-eval/SKILL.md`). One row per
advisor × scenario run. Scores and the decision rule are defined in `rubric.md` (harness section).
Transcripts stay in scratch; only scores, hashes and one-line notes are committed here.

Scores per arm: `ff/fad/fal/step/res/dec/na/cost/pace Σ ffN` (false facts, F/A/D separability,
falsifiability, smallest next step, resume, decision change, not assessed, cost, pace; each 0–2).
Rows without arm N carry the verdict `baseline`.

| date | advisor | contract tag | SKILL.md sha256[:12] | arms | scenario | scores per arm | verdict | note |
|---|---|---|---|---|---|---|---|---|
