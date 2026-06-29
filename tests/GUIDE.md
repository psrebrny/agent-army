# Testing the Army (maintainer guide)

> **Source-repo only — NOT shipped.** `apm.yml` has `includes: auto`, which packages only
> what lives under `.apm/`. Everything here (`tests/`, `scripts/`) is maintainer tooling and
> never reaches a target repo via `apm install`. Keep it that way: test assets stay out of `.apm/`.

Two layers of test, cheapest first:

| Layer | Command | Cost | Catches |
|---|---|---|---|
| **Unit** (structure) | `scripts/check.sh` | instant, zero-LLM | malformed frontmatter, missing `_STANDARD.md` sections, <2 prompt examples, broken template links, cross-tool-unsafe `tools:` |
| **e2e** (behaviour) | `scripts/smoke.sh` | minutes + tokens | does `/bootstrap` actually produce a *good, repo-tailored* team |

---

## 1 · Unit checks — `scripts/check.sh`

Deterministic validation of the **baseline source** (the files `/bootstrap` ships and tailors).
Run it constantly; it's free.

```bash
scripts/check.sh                  # everything: all agents + skills
scripts/check.sh architect        # one agent
scripts/check.sh tester reviewer  # a few (substring match)
scripts/check.sh --skills         # just the skills
scripts/check.sh --pack           # also `apm pack`, if apm is installed
```

It can also validate **generated** output (used by the e2e harness):

```bash
scripts/check.sh --target-dir <repo>/.claude   # checks <repo>/.claude/agents + templates
```

Exit non-zero on any ✗. Warnings (⚠) don't fail the run.

---

## 2 · e2e smoke test — `scripts/smoke.sh`

The real test. Treats the `bootstrap` skill as the app under test and drives it headlessly with
`claude -p`, exactly like a Playwright/Cypress run:

1. copy a fixture (`tests/fixtures/<name>`) to a throwaway temp dir + `git init`
2. install the army hermetically (source `.apm/skills` → `<work>/.claude/skills`) — **no network, no apm, no GitHub**
3. run the `bootstrap` skill headless in `BOOTSTRAP_MODE=auto` (no gate pauses, no questions)
4. **GATE A** — deterministic, zero-LLM: `check.sh` on the generated agents + grep the fixture's
   *planted facts* (see `tests/fixtures/README.md`)
5. **GATE B** — optional (`--judge`): an LLM scores each agent on internalization / evidence /
   variety against `tests/judge/rubric.md`

### Run it

```bash
scripts/smoke.sh                 # fixture py-monorepo, GATE A only (no LLM judge)
scripts/smoke.sh --judge         # also run the LLM judge (GATE B)
scripts/smoke.sh --keep          # keep the temp work dir for inspection
scripts/smoke.sh --fixture py-monorepo
```

The work dir is auto-removed on success; kept on failure (or with `--keep`) and its path printed.
The full bootstrap transcript is saved to `<work>/.smoke-bootstrap.log`.

### Develop assertions without re-running bootstrap

The `claude -p` step is the slow/expensive part. Run it once, keep the dir, then iterate on the
grep assertions against that frozen output:

```bash
scripts/smoke.sh --keep                          # -> prints WORK=<dir>
scripts/smoke.sh --work <dir> --no-bootstrap      # re-run only GATES A/B on that output
```

`--setup-only` builds the work dir + installs the skills and prints `WORK=<dir>` without running
bootstrap — handy for poking at the install layout.

### Env knobs

| Var | Default | Meaning |
|---|---|---|
| `SMOKE_TIMEOUT` | `1800` | seconds for the bootstrap run (needs `timeout`; on macOS `brew install coreutils` or it runs untimed) |
| `SMOKE_MODEL` | claude default | model for the bootstrap run, e.g. `opus` |
| `SMOKE_JUDGE_MODEL` | claude default | model for the judge — set a cheap one, e.g. `haiku`, to keep GATE B cheap |

---

## 3 · Adding a fixture

A fixture is a small repo with **planted facts** — laws, real commands, a nested standards file —
that a correct `/bootstrap` MUST extract. The point is that the assertions know the right answer
in advance.

1. `tests/fixtures/<name>/` — real (tiny) code with discoverable laws. Make the laws *provable*
   from the code, not just stated in prose. Include at least one **nested `AGENTS.md`** in a
   subdir (the historical regression: bootstrap missing a nested standards file).
2. Document the planted facts in `tests/fixtures/README.md` as a table — that table is the
   assertion contract.
3. Add a `if [ "$FIXTURE" = "<name>" ]` assertion block in `scripts/smoke.sh` (GATE A) that greps
   each planted fact in the generated `.claude/agents/*` / `army.conf` / `AGENTS.md`.

The judge (GATE B) is fixture-agnostic — it reads `tests/fixtures/README.md` as the "planted
facts" context — so it needs no per-fixture code.

---

## 4 · Notes & gotchas

- **Hermetic by design.** smoke.sh copies `.apm/skills` straight into `.claude/skills`; it does
  not call `apm install` or hit the network. To also exercise the real apm path, install manually:
  `apm install psrebrny/agent-army --target claude` in a scratch repo, then `/bootstrap`.
- **Why the headless run won't hang on its own gate.** `gate.sh` (Stop hook) honors
  `stop_hook_active`, so it blocks at most once. And a `.claude/settings.json` written *during*
  the run isn't hot-reloaded into that same session — so the freshly-wired gate doesn't fire on
  the run that created it. Bootstrap's own Step-5 verify may report red (the fixture's `pytest` /
  `vitest` aren't installed); that's expected and does not fail the smoke test — GATE A asserts on
  the *files produced*, not on the fixture's tests going green.
- **Permissions.** smoke.sh runs `claude -p --permission-mode bypassPermissions` so the headless
  agent can write files and run commands unattended. Only run it on fixtures you trust (these).
- **CI.** Layer 1 (`check.sh`) belongs in every CI run. Layer 2 (`smoke.sh`) needs `claude` auth +
  budget — gate it behind a manual/scheduled workflow, not every push.
```
