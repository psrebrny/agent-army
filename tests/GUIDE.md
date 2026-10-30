# Test guide

Run the deterministic package checks:

```bash
scripts/check.sh
scripts/smoke.sh
```

`check.sh` validates agent quality, skill metadata, descriptor syntax, the
v0.3.1 generator, incremental migration safety, and the absence of shell-sourced/evaluated runtime config.

`smoke.sh` creates scratch Git repositories and verifies:

- all target profiles create seven local APM agent sources, with Gemini and
  Windsurf degraded adapters where required;
- canonical role contracts stay in `.agent-army/agents/*.agent`; OpenCode has no
  `.apm/agents` staging or `.opencode/agents` output and executes roles in the main thread;
  other native adapters may use temporary `.apm/agents/*.agent.md` staging;
- existing pre-commit and CI controls remain external and untouched;
- unmanaged hooks cannot be replaced silently;
- protected-file shell redirects and staged secret values fail;
- every generated agent retains the shared Handoff contract, while the architect and reviewer retain delegation and clean-packet rules;
- generated blueprints expose only `autonomous`/`interactive` interaction modes, persist an Interaction Card, and contain no raw checkpoint selector;
- every adapter declares conservative `model_control`; confirmed native model fields can route static role models, while unsupported fields, missing exact IDs and effort selectors degrade to inheritance rather than guessed settings;
- native/degraded APM rendering preserves the delegation contract, Execution State/Execution Profile and Handoff text;
- a failing `{cwd, argv}` command fails verification;
- the skills keep one installed copy: `.claude/skills` on Claude (no `.agents/skills`), `.agents/skills`
  elsewhere; a stale Claude `.agents/skills` copy from bootstrap 0.3.1/0.4.0 is removed only where every
  file is identical to a package release, while a changed file, symlink or hard link keeps its skill dir
  and is reported as a conflict;
- legacy v0.2 profiles preview and apply an idempotent incremental migration without overwriting
  specialized agents, local overlays or user-edited managed blocks;
- APM renders the expected native output for Claude, Codex, Cursor and Copilot,
  plus the Gemini/Windsurf adapters; OpenCode keeps only the canonical role contracts;
- `army.py` package-local discovery (`.apm/skills/bootstrap/tests/test_army.py`, also runnable alone):
  nearest/explicit team selection, no parent/sibling merging, legacy `.agent.md` contracts,
  path/symlink/checkout escapes, and no upgrade flag for a profile written by a newer package.

The smoke suite is offline apart from the locally installed `apm` executable;
it does not call an LLM or install a remote package.

## Interactive delivery

`check.sh` compares the executor and architect Interaction Card fields/options and checks that the
Task Roadmap is the only progress ledger, the `For you` sections, the Rule 9 correction tiers and the one-task
authorization structure. `smoke.sh` checks these survive canonical
profile generation for every target and native/degraded rendering where supported. These are structural
and packaging checks, not proof of conversational behavior.

Use [the interactive ship fixtures](fixtures/ship-interaction/README.md) for manual conversation evaluations.

## Contract hygiene

`check.sh` also enforces `AGENTS.md` "Changing a contract": one package version in every file that names
it; a version above main's whenever `.apm/skills` changed; no retired wording (removed checkpoints, "both
audits", removed fields) in any shipped Markdown except `ship/references/legacy.md`; every skill
`references/` and `scripts/` file named by its `SKILL.md` and every named one present; and the skill scripts
compile, with `ship/scripts/removals.py` running. `check.sh` runs under macOS's bash 3.2: Python blocks go
through `py_capture`, never a heredoc inside `"$(...)"`.
They cover clear/ambiguous requirements, delegated choices, stalled discussion, RED resume, changed scope,
one-task delegation, policy variants, closure/repair and autonomous regression. Give the actor only its
request and assembled scratch repo; keep the expected behavior and follow-up turns with the evaluator.
Record actual transcripts, state changes and verification evidence before claiming a scenario passed.
No model-evaluation runs are checked in with these fixtures.

## Advisor evaluation

The sixteen product skills are prose, so `check.sh` can only prove their structure (frontmatter,
the pointer to the shared `product/advisor-contract.md`, a stage, an objective, at most 12 rules, links, description length). Their behavior is
measured by `advisor-eval`, a maintainer tool in `.claude/skills/advisor-eval/` that is never shipped.
Each real run calls models (Claude has incurred multi-dollar costs; API billing depends on the provider), so it is not part of
`check.sh` or `smoke.sh`.

- **Fixtures:** [`fixtures/advisors/`](fixtures/advisors/README.md) holds synthetic scenarios S1–S22
  (which advisor each one evaluates is in that README). Each has `request.md` (session 1),
  `resume.md` (session 2 in a fresh context over the same files), `user.md` (the simulated-user
  persona), `expected.md` (the oracle, seen only by the judge), an optional `repo/` overlay and an
  optional `web-on` flag. S8 (`/ship` docs stage) and S17 (external store) are run by hand.
- **Run:** `python3 .claude/skills/advisor-eval/run.py <advisor> --scenario <id> --plan-only` first
  (assembles each scratch repo outside this repo and checks isolation without a model), then the same
  command without `--plan-only`. Claude Code can call it as `/advisor-eval`; the protocol is in its
  `SKILL.md`. The default `--backend api` (it spares the Claude limit) runs actor and
  persona over stdlib HTTP with `AUX_BASE_URL` and `AUX_API_KEY` from the environment or the source
  repo's ignored private `.env` (loaded only on API; environment wins), no shell evaluation, and the
  model pinned as `API_MODEL` in `run.py`. The judge stays on Claude `sonnet` (one call per scenario)
  unless `--judge-backend api`. `--backend claude` needs the `claude` CLI and is kept for
  pre-release confirmation and arm P.
  The API base includes `/v1` or the provider's equivalent prefix; the runner appends `/chat/completions`.
  Fixture contents are sent to the configured provider; never put keys in prompts, files or commands
  checked into Git. Keep the optional `.env` at mode `600` and never paste its contents in chat.
  Pin one hosted model with tool support and verify its free quota independently.
  Do not use a local model, web session, `auto` router or a multi-model combo.
- **API calibration and batch:** first run `product-metrics --scenario S22` and `positioning-offer
  --scenario S18` with `--backend api --parallel --max-turns 70 --no-ledger`. Compare the actual
  decisions to the Opus rows (S18 was a pre-fix `fix-contract`); only then run
  `python3 .claude/skills/advisor-eval/run.py --all --backend api --parallel --max-turns 70 --keep-going`
  (first with `--plan-only`). `--all` means one representative per product skill, 16 cases; it starts
  with S22/S18, includes S15/S7 and excludes the manual S8/S17. Run S10 separately via
  `product-metrics --scenario S10`. Triage failures as a skill gap or a model limit, then confirm
  changed advisors on Claude before a release (the routine workflow in the advisor-eval `SKILL.md`). An omitted scenario for a named advisor now selects its
  representative, not every fixture. Arms can run concurrently, scenarios cannot.
  API errors, safety stops, `fix-contract` and `rethink` halt the batch with a nonzero exit;
  incomplete/invalid runs get no ledger row. Existing real rows remain append-only, so retry remaining
  advisors explicitly instead of assuming `--all` will skip completed work.
  Timeouts/retries/token budget and optional judge JSON mode are documented in the maintainer skill.
- **Arms:** N runs the candidate skill, K runs a plain session with the same messages, always in the
  same run, so every verdict has its own control. P (an optional pinned third-party reference) runs
  only from a checkout the maintainer prepares outside this repo.
- **Scoring:** a separate blind judge reads the two sessions and the files they wrote, without arm
  labels, and scores eight criteria 0–2 against `rubric.md` (false facts, F/A/D separability,
  falsifiability, smallest next step, resume, decision change, not assessed, pace); `run.py` adds
  `cost`. Decision rule: any false fact in N → `fix-contract`; N − K ≤ 2 → `rethink`; P ≥ N on ≥ 5 of 9
  → `consider-absorb`; otherwise `pass`.
- **Scorecards:** `run.py` appends one row per advisor × scenario to
  [`fixtures/advisors/SCORECARDS.md`](fixtures/advisors/SCORECARDS.md) (date, advisor, contract tag,
  `SKILL.md` sha256 prefix, arms, scores, verdict, a one-line note per arm). The ledger is append-only.
  **Scorecards only, no transcripts:** transcripts stay in the printed scratch dir and are never
  committed; a row is committed only with the maintainer's approval. Notes record backend, actor,
  persona and judge models. API cost is assumed $0 (not verified billing), time is measured and turns
  count completion rounds including tools. Do not directly compare its cost score with Claude's.
- **Staleness warning:** `check.sh` warns `advisor changed since last eval` when a product skill's
  fingerprint (sha256 of its `SKILL.md` plus the shared `product/advisor-contract.md`) or contract tag
  differs from its latest row, and lists skills with no row yet. Any
  change to a product skill or to the contract means re-running `advisor-eval` for the affected
  advisors before a release.
- **Limits:** one synthetic product per scenario; the maintainer knows the arms. Claude actors'
  tools are not sandboxed. API actors' file tools are confined to scratch (path traversal, protected
  directories and links rejected; bounded calls/output), with no shell, web or connector access.
  API S9 is offline even if the fixture requests web. API measures the injected skill text, not Claude
  skill loading, and free-model calibration does not prove production Opus quality. Provider rate/
  daily quotas may halt the batch. The gate detects large differences only; `pass` is not a guarantee.

### Offline runner regression tests

```bash
python3 -m py_compile .claude/skills/advisor-eval/run.py .claude/skills/advisor-eval/api_backend.py
python3 -m unittest discover -s tests -p test_advisor_eval.py -v
```

`tests/test_advisor_eval.py` checks model routing (including Claude persona/judge), exact safety caps,
shared judge parsing, retries/Retry-After/timeouts, credential-safe errors and scratch traversal/link
rejection, and private `.env` parsing without shell evaluation or leaking values in errors.
A scripted loopback HTTP server exercises real tool calls, fresh-session file resume, a
tool-free persona, blind judge bundles, parallel arms and all 16 representatives with `--no-ledger`.
It needs permission to bind `127.0.0.1`, but no external network, key, paid provider, Claude or local
model. Synthetic test scores never enter the ledger and are not behavioral evaluation evidence.
