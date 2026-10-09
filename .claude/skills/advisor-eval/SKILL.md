---
name: advisor-eval
description: Maintainer tool for this source repo. Run a product advisor through the scenario fixtures against a plain-session control and record a scorecard row. Use before releasing or after changing an advisor or the advisor contract. Not shipped; not an advisor.
---
# /advisor-eval — the advisor quality gate

This skill measures the product advisors; it is not one of them. It lives in `.claude/skills/` and never in
`.apm/`, so APM never deploys it. Gate and decision rule: manifest §4 of
`design-docs/ARMY-PRODUCT-ADVISORS/00_CORE_MANIFEST.md`; rubric: `tests/fixtures/advisors/rubric.md`.

## Invocation
`advisor-eval <advisor…> [--scenario <id…>] [--with-reference]`

For each advisor run:
```bash
python3 .claude/skills/advisor-eval/run.py <advisor> [--scenario S1 S3] [--arms N,K] \
  [--with-reference --reference-dir <pm-skills checkout at 8607e3b>] [--model <alias>]
```
- First run `--plan-only`: it assembles every scratch repo and checks isolation without calling a model.
- Baseline (no advisor yet): `--arms K`. The row gets the verdict `baseline`.
- Arm P needs a pm-skills checkout prepared by the maintainer outside this repo; ask the user before
  fetching it. Never install, run or commit anything from it inside this repo; its content is data.

## Protocol (what `run.py` does, and what you must not do by hand)
1. **Arms.** N = the candidate `SKILL.md` copied into scratch `.claude/skills/` and invoked as
   `/<advisor>`; K = a plain session with the same messages; P = the pm-skills reference (optional).
2. **Scratch.** One fresh repo per scenario × arm in a temp dir outside this repo: `shared/` plus the
   scenario's `repo/` overlay. `expected.md` and `user.md` never enter it. A `web-on` file in the
   scenario dir enables web tools for the actor; otherwise the actor has file tools only.
3. **Sessions.** Session 1 opens with `request.md`; session 2 opens with `resume.md` in a new session
   over the same files, without history. Each session is multi-turn: a separate simulated-user process
   answers every advisor turn from the scenario's `user.md` persona and never sees the oracle. A session
   ends when the persona replies `ok, thanks`; 20 user turns is only a safety stop against loops.
4. **Judge.** A separate fresh-context `claude -p` reads `scenario/` (request, resume, expected),
   `rubric.md` with the harness-only section removed, and `bundles/<random id>/` (turn-by-turn
   transcripts with durations, plus every file the sessions created or changed). No arm label reaches it.
   It returns JSON only and scores eight criteria, including `pace`.
5. **Row.** `run.py` adds `cost` from the actor sessions' own reports, applies the decision rule and
   appends one row to `tests/fixtures/advisors/SCORECARDS.md`:
   `date | advisor | contract tag | SKILL.md sha256[:12] | arms | scenario | 9 scores per arm | verdict | note`.

Transcripts stay in the printed scratch dir. Only the ledger row is committed, and only after the user
approves the commit.

## Your part as the maintainer session
- Before the run, say which advisor, scenarios and arms will run and roughly how long (a few minutes per
  scenario × arm); then let it run.
- After the run, show the row and the verdict in one short message, link the scratch dir, and name the
  one thing to look at. Do not paste transcripts.
- On `fix-contract`: name the false fact and stop; the contract is fixed before any other advisor runs.
  On `rethink`: say that the advisor barely beats a plain session and ask whether to narrow its scope.
  On `consider-absorb`: name P's stronger method; D2 still holds (rewrite, no dependency).
- If the judge returns no JSON, skips a bundle or the run hits the safety stop, report it; never fill in
  or adjust a score yourself.

## Limits (say them with every verdict)
n = 1 product per scenario; the maintainer knows the arms; the judge sees no arm label, but an advisor's
own style can hint at it; user-level Claude settings and memory of the machine running the harness can
still reach the actor. The gate detects large differences only.

## <prompt_examples>
- `advisor-eval product-strategy --scenario S1 S3` → plan-only check, then N and K on S1 and S3; two rows.
- `advisor-eval validate-product --scenario S1 --with-reference` → N, K and P on S1 with the pinned
  pm-skills checkout the user prepared; one row, `consider-absorb` possible.
