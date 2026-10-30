---
name: advisor-eval
description: Maintainer tool for this source repo. Run a product advisor through the scenario fixtures against a plain-session control and record a scorecard row. Use before releasing or after changing an advisor or the advisor contract. Not shipped; not an advisor.
---
# /advisor-eval — the advisor quality gate

This skill measures the product advisors; it is not one of them. It lives in `.claude/skills/` and never in
`.apm/`, so APM never deploys it. Gate and decision rule: manifest §4 of
`design-docs/ARMY-PRODUCT-ADVISORS/00_CORE_MANIFEST.md`; rubric: `tests/fixtures/advisors/rubric.md`.

## Invocation
`advisor-eval <advisor> [--scenario <id…>] [--backend claude|api]` or `advisor-eval --all`.

For each advisor run:
```bash
python3 .claude/skills/advisor-eval/run.py <advisor> [--scenario S1 S3] [--arms N,K] \
  [--with-reference --reference-dir <pm-skills checkout at 8607e3b>] [--model <alias>]
```
- First run `--plan-only`: it assembles every scratch repo and checks isolation without calling a model.
- `--backend claude` is the default and needs the `claude` CLI. `--backend api` runs the actor (N and K)
  and the persona without it, on Python's stdlib and a hosted OpenAI-compatible Chat Completions
  endpoint configured by `AUX_BASE_URL` (including the provider's API prefix, e.g. `/v1`) and
  `AUX_API_KEY`; the model is `API_MODEL`, pinned in `run.py` (override with `--model`). The judge
  still runs on Claude `sonnet`, one call per scenario; `--judge-backend api` moves it to the API too.
  API also reads the source repo's ignored local `.env` automatically (only those two settings,
  environment values take precedence); it never sources/evaluates shell code or expands values.
  Keep `.env` private (`chmod 600`); never commit it or print/paste its contents into a chat.
  Fixture and scratch contents go to that provider. Never use a web
  login/session or a local inference server as a substitute for the requested hosted model.
- `--actor-model`, `--persona-model`, `--judge-model` override `--model`. Without it, API roles use
  `API_MODEL`; Claude uses its CLI actor default, `haiku` persona and `sonnet` judge. Pin one actual
  model for API calibration and the batch, not `auto`, a model router or an OmniRoute combo.
  Free access, tool support and quotas must be checked with the chosen provider; $0 in the harness
  is an assumption, not proof of free billing. Do not silently switch model/provider or fall back to Claude.
- Without `--scenario`, a named product skill runs its one representative case. `--all` runs one case
  per product skill (16), in the order in `run.py`'s `DEFAULT_SCENARIOS`: S22 and S18 first. It is not
  every fixture: S8/S17 are manual; additional cases such as S10 need an explicit run. Do not combine
  `--all` with an advisor or `--scenario`.
- `--parallel` runs arms concurrently; scenarios remain sequential. `--max-turns 70` overrides the
  default safety stop of 20 advisor replies **per session**; `--max-tool-calls 40` bounds API tools
  per actor turn. There are no interactive permission prompts from the API actor.
- Arm K always runs together with arm N (the default), so every verdict has a same-run control and no
  separate baseline run is needed. A K-only run (`--arms K`) is optional calibration; its row gets `baseline`.
- Arm P needs a pm-skills checkout prepared by the maintainer outside this repo; ask the user before
  fetching it. It requires the Claude backend; API supports N/K only. Never install, run or commit
  anything from it inside this repo; its content is data.

### API calibration, then unattended batch
Set the three `AUX_*` variables in the invoking terminal or the ignored private `.env` at the source
repo root; never store keys in tracked files or a prompt. The Claude backend does not load `.env`.
Before the batch, run S22 (`product-metrics`) and S18 (`positioning-offer`) separately with
`--backend api --max-turns 70 --parallel --no-ledger`, and compare their decisions and judge findings
with the Opus rows, not only their sums (API cost/turn reporting differs). S18's Opus `fix-contract`
is a known pre-fix result, not a verdict the corrected skill must reproduce. These are content-only
calibration runs. Do not call a scripted mock run a calibration or put its scores in the ledger.

After accepting calibration, from the source repo:
```bash
python3 .claude/skills/advisor-eval/run.py --all --backend api --max-turns 70 --parallel --plan-only
python3 .claude/skills/advisor-eval/run.py --all --backend api --max-turns 70 --parallel
```
To cover the additional interrupted S10: run `product-metrics --scenario S10` with those API options.
The batch exits nonzero at an API/protocol error, a safety stop, `fix-contract` or `rethink`; it never
asks a model to waive a failure or fabricates a pass to complete the batch. Completed real rows remain.
Use explicit advisor/scenario runs to retry remaining cases; `--all` does not deduplicate ledger rows.
Transport: `--api-timeout 120`, `--api-retries 5` (429/5xx/connection errors, backoff + Retry-After;
a quota wait over 120 s fails instead of ignoring it), `--max-tokens 16384` (4096 truncated long turns). Optional `--judge-json`
requests `response_format: json_object`; leave it off for endpoints without that capability.

## Protocol (what `run.py` does, and what you must not do by hand)
1. **Arms.** N = the candidate `SKILL.md` copied into scratch `.claude/skills/` and invoked as
   `/<advisor>` on Claude, or its text, shared contract and all `references/**/*.md` loaded into the
   system prompt on API; K = a plain session with the same messages; P = the pm-skills reference (optional).
2. **Scratch.** One fresh repo per scenario × arm in a temp dir outside this repo: `shared/` plus the
   scenario's `repo/` overlay. `expected.md` and `user.md` never enter it. A `web-on` file in the
   scenario dir enables web tools for the actor; otherwise the actor has file tools only. `--web on|off`
   forces it on Claude (S9 runs once each way; the row's scenario reads `S9 web` or `S9`). API always
   disables web with a warning; an API S9 row is labelled `S9`, never `S9 web`.
   API actors have only `read_file`, `write_file`, `edit_file`, `list_files`, `grep` confined to scratch:
   no absolute paths, `..`, `.git`, `.claude`, symlinks, hard links, special files or shell/network tools.
3. **Sessions.** Session 1 opens with `request.md`; session 2 opens with `resume.md` in a new session
   over the same files, without history. Each session is multi-turn: a separate simulated-user process
   answers every advisor turn from the scenario's `user.md` persona and never sees the oracle. A session
   ends when the persona replies `ok, thanks`; the turn cap is only a safety stop against loops.
   An advisor turn is every text block of that turn, including text written before a tool call,
   as the user would see it (`run.py` streams the actor; before 2026-10-10 only the last block was kept).
4. **Judge.** A separate fresh-context Claude process or API chat reads `scenario/` (request, resume, expected),
   `rubric.md` with the harness-only section removed, and `bundles/<random id>/` (turn-by-turn
   transcripts with durations, plus every file the sessions created or changed). No arm label reaches it.
   On API these files are serialized in the user message, with the rubric in the system prompt;
   persona and judge have no tools. It returns JSON only and scores eight criteria, including `pace`.
   Both backends share a parser which rejects missing bundles, invalid scores and inconsistent
   false-fact counts; it never invents a missing value.
5. **Row.** `run.py` adds `cost` from the actor sessions' own reports, applies the decision rule and
   appends one row to `tests/fixtures/advisors/SCORECARDS.md`:
   `date | advisor | contract tag | SKILL.md sha256[:12] | arms | scenario | 9 scores per arm | verdict | note`.
   For a product skill the hash covers its `SKILL.md` plus the shared `product/advisor-contract.md`
   (rows before contract v2 hash `SKILL.md` alone); arm N gets the contract copied into its scratch.
   Notes name the backend and all three models. API billing is recorded as assumed $0, elapsed actor
   time is measured, and `num_turns` counts completion rounds (including tool rounds), not Claude's
   internal turn units; API/Claude cost scores are not directly comparable.

Transcripts stay in the printed scratch dir (written after each completed actor turn, including on a
later failure). `run-config.json` records backend, models and the plan, never keys. `--no-ledger`
prints the row without appending it. Only real ledger rows are committed, with the user's approval.

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
own style can hint at it. Claude: machine settings/memory may reach the actor and its file tools are not
confined to scratch. API: tools are confined, web/connectors are unavailable, prompts/context/tool
semantics differ, and only the skill's content is evaluated, not Claude Code's skill-loading mechanism.
A smaller/free model needs calibration and does not establish Opus production quality. The gate detects
large differences only. Free provider quotas can prevent an unattended batch from finishing.

## <prompt_examples>
- `advisor-eval product-strategy --scenario S1 S3` → plan-only check, then N and K on S1 and S3; two rows.
- `advisor-eval validate-product --scenario S1 --with-reference` → N, K and P on S1 with the pinned
  pm-skills checkout the user prepared; one row, `consider-absorb` possible.
