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
