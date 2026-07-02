> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #1: Per-tool descriptors (the data layer)
**Objective:** Define an explicit, data-driven descriptor per tool so ALL cross-tool knowledge lives in one verifiable place — not in prose. Nothing consumes them yet (PR#2 does); this PR is the schema + the first descriptors.

---

### Task 1.1: Descriptor schema + `claude` and `opencode` descriptors

**Action:**
Introduce `tools/<tool>.yml` under the bootstrap baseline. Each descriptor declares packaging facts as data:
- `dirs`: `agents`, `skills`, `hooks`, `config_root` (e.g. Claude → `.claude/agents`, `.claude/skills`, `.claude/hooks`, `.claude`; OpenCode → `.opencode/agent`, `.agents/skills`, `.opencode/hooks`, `.opencode`).
- `frontmatter`: `accepts_tools_field` (bool), `model_field` format/notes.
- `capabilities`: `subagents` (bool), `hook_mechanism` (`claude-settings` | `git-only`), `auto_loads_skills` (bool), `commands_dir` (nullable), `skill_invocation` (`native-command` | `invoke-by-path`).
- `hooks_live`: the hook scripts that actually fire (Claude → guard/format/gate/verify; others → [] lifecycle, git+CI only).
Add stub descriptors for `cursor`, `codex`, `gemini`, `windsurf`, `copilot` (copilot: `subagents: false`). Add a **`_default.yml` fallback** for any unrecognized tool — but it must NOT *guess* a tool's native dirs (guessing re-introduces the soft-if drift we're removing). It defines an **honest degraded mode**: emit only the tool-independent guarantees — `AGENTS.md` (every tool reads it) + the git pre-commit & CI barriers + agents/skills in the neutral `.agents/` dir — with `hook_mechanism: git-only`, `subagents: false`, `skill_invocation: invoke-by-path`. When `<tool>` matches no descriptor the assembler uses `_default`, WARNs "tool not first-class — add `tools/<tool>.yml` for native placement", and does NOT invent native agent/command dirs (never fails). Write a one-paragraph `tools/README.md` documenting the schema.
- **API/Component Contract:** the YAML keys above are the contract PR#2's assembler reads. Keep names stable.
- Descriptors are pure data — no logic, no prose ifs.

**Target File(s):**
- `.apm/skills/bootstrap/baseline/tools/claude.yml`
- `.apm/skills/bootstrap/baseline/tools/opencode.yml`
- `.apm/skills/bootstrap/baseline/tools/{cursor,codex,gemini,windsurf,copilot}.yml`
- `.apm/skills/bootstrap/baseline/tools/_default.yml`  (fallback for unrecognized tools — honest degraded mode: AGENTS.md + git/CI + neutral `.agents/`, no guessed native dirs)
- `.apm/skills/bootstrap/baseline/tools/README.md`

**Verification Command:** `python3 -c "import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob('.apm/skills/bootstrap/baseline/tools/*.yml')]" && echo OK`

**Testing Strategy & Cases (Testing Trophy):**
- **INTEGRATION** (schema parse): ✓ every `tools/*.yml` parses as valid YAML; ✓ each has the required top-level keys (`dirs`, `frontmatter`, `capabilities`, `hooks_live`).
- **UNIT** (values): ✓ `claude` → `hook_mechanism: claude-settings`, `hooks_live` non-empty; ✓ `opencode` → `hook_mechanism: git-only`, `skills` = `.agents/skills`; ✓ `copilot` → `subagents: false`; ✓ `_default` → `hook_mechanism: git-only`, `subagents: false` (safe conservative fallback).

**TDD Execution & Auto-Critic:**
1. Add a schema-assertion snippet (in `check.sh` or a tiny `tools`-lint) that lists required keys.
2. Run it → **MUST FAIL (RED)** (no descriptors yet).
3. Write the descriptors.
4. Re-run → **MUST PASS (GREEN)**. If it fails, STOP and fix.

**Aligns with:** "One source of per-tool knowledge" + "Capability flags, not pretense" (manifest §3).

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** open `claude.yml` and `opencode.yml` — a human can see, at a glance, every dir/capability/hook difference between the two tools in one place.
