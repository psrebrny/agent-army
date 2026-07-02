> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #2: Deterministic assembler (the heart of the refactor)
**Objective:** A plain, testable script that materializes a tool-native team from `core/` + a descriptor. This is where ALL the packaging "soft ifs" currently in `SKILL.md` prose move to — becoming deterministic and unit-tested. (Depends on PR#1 descriptors; consumes PR#3's `core/`, but can be built against the current `baseline/agents/` and retargeted in PR#3.)

---

### Task 2.1: `assemble.sh <tool> [--dry-run] [--reconcile]` — emit whole files, skip existing

**Action:**
`assemble.sh` is a **deterministic tool** (no LLM, no soft ifs) that bootstrap (or apm/the user) invokes from the skill: it takes `core/agents/` + a descriptor and produces the tool-native layout. It must run standalone (`bash assemble.sh <tool>`) without any model.
Given a tool name it loads `tools/<tool>.yml` (or `_default.yml` if unrecognized) and:
1. Resolves target dirs from `dirs`.
2. For each agent in `core/agents/`, emits a **complete, standalone** agent file into `<agents_dir>/` — inline everything, resolve all paths from the descriptor (no placeholders, no `core/` pointers), apply `frontmatter` rules (add/strip `tools:`, format `model`).
3. Places ONLY the hooks in `hooks_live` into `<hooks_dir>` + `chmod +x`.
4. Writes `settings.json` **only if** `hook_mechanism == claude-settings`.
5. Registers the git commit barrier husky-aware (detect `core.hooksPath`; chain idempotently; never clobber; plain-repo shim else) — lift this logic verbatim from the current `SKILL.md` Step-0 prose.
6. Updates `.gitignore` (skills dir + local-state) per the descriptor.
- **Non-clobber contract (invariant across EVERY descriptor, incl. `_default`):** if a target agent file already EXISTS, do NOT overwrite it — report `kept <file>` and continue. `--reconcile` may fix ONLY packaging (frontmatter/paths) on existing files without touching the body. `--dry-run` prints the plan and writes nothing. **No `.base`/backup files are ever written — git is the only rollback.** This is a property of the assembler, not of any one tool, so the fallback path cannot re-introduce the old `.base.md`/clobber problem.
- **API/Component Contract:** inputs = `<tool>` + flags; effect = files under the descriptor's dirs; exit non-zero on any inconsistency (unknown tool, missing core).

**Target File(s):**
- `.apm/skills/bootstrap/assemble.sh`  — at the **skill root, NOT inside `baseline/`**. Rationale: `baseline/` is the *payload* materialized into repos; the assembler is the *builder* that consumes `baseline/core` + `baseline/tools` and is never itself materialized. (It's not in `tools/` either — that dir is pure data/descriptors; keep code out of it.)

**Verification Command:** `bash -n .apm/skills/bootstrap/assemble.sh && bash .apm/skills/bootstrap/assemble.sh claude --dry-run`

**Testing Strategy & Cases (Testing Trophy):**
- **E2E / INTEGRATION** (assemble into a scratch dir, then `check.sh --target-dir`):
  - ✓ `claude` → agents in `.claude/agents/`, all 4 lifecycle hooks + `settings.json` present, `.gitignore` has skills dir; `check.sh --target-dir` GREEN, zero placeholders.
  - ✓ `opencode` → agents in `.opencode/agent/`, ONLY `verify.sh`+`detect.sh`+`git-pre-commit.sh` in hooks, NO `settings.json`.
  - ✓ **non-clobber:** run assemble twice; hand-edit an agent between runs; second run leaves the edit intact (reports `kept`).
  - ✓ **husky:** in a repo with `core.hooksPath=.husky`, the barrier line is appended once to `.husky/pre-commit` (idempotent — running twice doesn't duplicate) and `.git/hooks/pre-commit` is untouched.
- **UNIT** (`--dry-run` output): ✓ prints intended paths; ✓ writes nothing.

**TDD Execution & Auto-Critic:**
1. Write the scratch-dir assertion script (assemble → check output layout).
2. Run → **RED** (no assembler).
3. Implement `assemble.sh`.
4. Run → **GREEN**. Do not weaken the non-clobber or husky assertions to pass.

**Aligns with:** "Whole agents in output", "Non-destructive", "packaging = deterministic" (manifest §3).

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** run `assemble.sh opencode --dry-run` in a scratch repo — the printed plan matches what OpenCode actually needs, and no lifecycle hooks are listed.
