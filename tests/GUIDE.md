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
- legacy v0.2 profiles preview and apply an idempotent incremental migration without overwriting
  specialized agents, local overlays or user-edited managed blocks;
- APM renders the expected native output for Claude, Codex, Cursor and Copilot,
  plus the Gemini/Windsurf adapters; OpenCode keeps only the canonical role contracts.

The smoke suite is offline apart from the locally installed `apm` executable;
it does not call an LLM or install a remote package.

## Interactive delivery

`check.sh` compares the executor and architect Interaction Card fields/options and checks the
Execution Progress and one-task authorization structure. `smoke.sh` checks these survive canonical
profile generation for every target and native/degraded rendering where supported. These are structural
and packaging checks, not proof of conversational behavior.

Use [the interactive ship fixtures](fixtures/ship-interaction/README.md) for manual conversation evaluations.
They cover clear/ambiguous requirements, delegated choices, stalled discussion, RED resume, changed scope,
one-task delegation, policy variants, closure/repair and autonomous regression. Give the actor only its
request and assembled scratch repo; keep the expected behavior and follow-up turns with the evaluator.
Record actual transcripts, state changes and verification evidence before claiming a scenario passed.
No model-evaluation runs are checked in with these fixtures.

## Advisor evaluation

The fourteen product skills are prose, so `check.sh` can only prove their structure (frontmatter,
examples, the identical `advisor-contract:v1` block, links, description length). Their behavior is
measured by `advisor-eval`, a maintainer tool in `.claude/skills/advisor-eval/` that is never shipped.
Each run calls models and costs money (roughly $0.5–3 per advisor × scenario), so it is not part of
`check.sh` or `smoke.sh`.

- **Fixtures:** [`fixtures/advisors/`](fixtures/advisors/README.md) holds synthetic scenarios S1–S17
  (which advisor each one evaluates is in that README). Each has `request.md` (session 1),
  `resume.md` (session 2 in a fresh context over the same files), `user.md` (the simulated-user
  persona), `expected.md` (the oracle, seen only by the judge), an optional `repo/` overlay and an
  optional `web-on` flag. S8 (`/ship` docs stage) and S17 (external store) are run by hand.
- **Run:** `python3 .claude/skills/advisor-eval/run.py <advisor> --scenario <id> --plan-only` first
  (assembles each scratch repo outside this repo and checks isolation without a model), then the same
  command without `--plan-only`. Claude Code can call it as `/advisor-eval`; the protocol is in its
  `SKILL.md`. It needs the `claude` CLI.
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
  committed; a row is committed only with the maintainer's approval.
- **Staleness warning:** `check.sh` warns `advisor changed since last eval` when a product skill's
  `SKILL.md` hash or contract tag differs from its latest row, and lists skills with no row yet. Any
  change to a product skill or to the contract means re-running `advisor-eval` for the affected
  advisors before a release.
- **Limits:** one synthetic product per scenario, the maintainer knows the arms, and the actor's
  file tools are not sandboxed. The gate detects large differences only; it does not prove an advisor
  is good, and a `pass` is not a guarantee.
