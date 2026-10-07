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
