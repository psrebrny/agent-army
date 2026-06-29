# Smoke-test fixtures

Each fixture is a deliberately small repo with **planted facts** — architectural laws,
real commands, and a nested standards file — that a correct `/bootstrap` run MUST extract.
`scripts/smoke.sh` copies a fixture to a temp dir, runs the `bootstrap` skill headlessly
against it, then asserts the planted facts surfaced in the generated agents.

## `py-monorepo` — planted facts

The deterministic gate (`smoke.sh`, grep-level) checks these appear in the **generated**
`.claude/agents/*` and `army.conf`/`AGENTS.md`:

| # | Planted fact | Where it lives in the fixture | Expected in output |
|---|---|---|---|
| 1 | **Repository law:** services never touch `app.db`; persistence goes through `AccountRepository` | `backend/app/repository.py`, `service.py` | a law in `architect` + `code-reviewer` |
| 2 | **Nested standards discovered:** `frontend/AGENTS.md` (the known miss) — "design-system primitives only" | `frontend/AGENTS.md` | "primitive" law in `code-reviewer` (proves nested discovery) |
| 3 | **Real backend command** `pytest` | `backend/pyproject.toml` | `tester` + `army.conf TEST_CMD` |
| 4 | **Real frontend command** `vitest` | `frontend/package.json` | wired somewhere (monorepo chaining) |
| 5 | **Test idiom:** fake repository injected as a seam (no `app.db` in tests) | `backend/tests/test_transfer.py` | `tester` examples |
| 6 | **Monorepo:** two stacks (Python + TS), mapped separately | two manifests | both stacks named in `AGENTS.md` |

A regression that re-introduces the "missed nested `AGENTS.md`" bug fails fact #2 for free.

The LLM judge (`smoke.sh --judge`) goes beyond grep: it scores each generated agent on
internalization / evidence / variety per `tests/judge/rubric.md`.
