# Test guide

Run the deterministic package checks:

```bash
scripts/check.sh
scripts/smoke.sh
```

`check.sh` validates agent quality, skill metadata, descriptor syntax, the
v0.2 generator, and the absence of shell-sourced/evaluated runtime config.

`smoke.sh` creates scratch Git repositories and verifies:

- all target profiles create seven local APM agent sources, with Gemini and
  Windsurf degraded adapters where required;
- existing pre-commit and CI controls remain external and untouched;
- unmanaged hooks cannot be replaced silently;
- protected-file shell redirects and staged secret values fail;
- a failing `{cwd, argv}` command fails verification;
- APM renders the expected native output for Claude, Codex, Cursor, Copilot
  and OpenCode, plus the Gemini/Windsurf adapters.

The smoke suite is offline apart from the locally installed `apm` executable;
it does not call an LLM or install a remote package.
