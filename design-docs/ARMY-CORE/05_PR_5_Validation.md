> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #5: Validation — prove per-tool output deterministically
**Objective:** Make CI/dev catch any regression in the new pipeline without an LLM: assembler output is correct per tool, no placeholders leak, existing files survive re-runs. (Depends on PR#2–#4.)

---
// zauważyłem tez że mamy 1 task na pr  docelowy architekt powinien potrafić zrobic kilka tasków na pr ok? jeśli jest to niedoprecyzowane to prosze popraw to w archtekcie np dodając wiecej prompt examples
### Task 5.1: Extend `check.sh` + `smoke.sh` to exercise the assembler per tool

**Action:**
- `check.sh`: keep the target-dir placeholder guard; add per-tool assertions driven by the descriptor — correct agents dir, the exact `hooks_live` set present (and inert ones ABSENT), `settings.json` present iff `claude-settings`, frontmatter `tools:` rule honored.
- `smoke.sh`: for `claude` and `opencode`, run `assemble.sh <tool>` into a scratch repo, then `check.sh --target-dir`; assert zero placeholders and zero `.claude/` in non-Claude output; then re-run assemble and assert a pre-seeded hand-edit is preserved (non-clobber) and the husky line isn't duplicated.
- **Contract:** these run with zero LLM and gate CI; a broken descriptor or assembler must turn them RED.

**Target File(s):**
- `scripts/check.sh`
- `scripts/smoke.sh`
- `.apm/skills/bootstrap/baseline/.github/workflows/quality.yml` (if CI needs the new steps)

**Verification Command:** `bash scripts/check.sh && bash scripts/smoke.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **E2E** (smoke): ✓ claude & opencode assemble+validate GREEN; ✓ non-clobber preserved across re-run; ✓ husky line idempotent.
- **INTEGRATION** (check): ✓ inert hooks ABSENT on opencode; ✓ `settings.json` absent on opencode, present on claude; ✓ zero placeholders / zero non-Claude `.claude/`.
- **UNIT**: ✓ a deliberately-broken descriptor (missing key) makes `check.sh` RED.

**TDD Execution & Auto-Critic:**
1. Add the assertions.
2. Run against current state → **RED** where the new pipeline isn't wired.
3. Wire until **GREEN**. Never relax an assertion (e.g. "inert hook absent") to pass.

**Aligns with:** "check.sh/smoke validate assembled output with zero LLM" (manifest §2).

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** breaking a descriptor or the assembler turns CI RED; a clean run proves claude+opencode outputs are correct and re-run-safe.

---

## Considered & deferred (not in scope)
- **Architect suggests a per-task model, coder loads that model dynamically** (e.g. sonnet→haiku by task complexity). Deferred: tools don't swap models per-invocation — a subagent's model is fixed in its frontmatter (`model:`), and in Claude Code / OpenCode the human picks the model; the orchestrator can't reliably override a subagent's model per task. The achievable, already-designed version of this value is the architect **annotating task weight** so `ship` chooses *inline vs delegate-to-coder* (fan-out), and the model *tiers* live in each agent's `model:` (context-budget essence in AGENTS.md) — not a runtime model-swap. Revisit only if a target tool exposes per-call model override.

## Open questions to settle in /ship Step 0 (before PR#1)
1. **Assembler language:** `bash` (zero deps, matches hooks) vs `node` (easier YAML/templating). Recommend `bash` + `python3` for YAML parsing (already a soft dep).
2. **Exact per-tool dir names** — confirm from a real install: `.opencode/command` vs `commands`, `agent` vs `agents`, and Copilot's home (`.github/`). Descriptors encode whatever is confirmed.
3. **Content refresh on version bump** (new `core/` vs already-specialized repo): out of scope here; git is the rollback. Decide later whether the assembler grows a 3-way `--refresh`.
4. **`_STANDARD.md` final home** (outside the agent-load dir) — pin the path in each descriptor.
5. **apm boundary — where does the deterministic layer actually run?** apm already knows the tool at `--target` and does tool-aware SKILL placement (`.claude/skills` vs `.agents/skills`), but empirically (0.19) it does NOT: route the `.apm/commands/` wrappers to a tool's native command dir (so `/bootstrap`,`/ship` aren't native on OpenCode), nor run any postinstall. Decide the split:
   - **Fix at the apm layer (declarative):** make `apm.yml`/wrappers route command-wrappers to each tool's native command dir, and (if apm supports per-runtime file lists) route hooks. This is the earliest, most deterministic placement — the "first validation" belongs here for anything needing no repo knowledge.
   - **Assembler invocation:** wire `assemble.sh` as an `apm run assemble` script (`apm.yml scripts:`) so the procedural packaging (husky wiring, hook-set selection, non-clobber, placeholder resolution — things a declarative manifest can't express) runs via apm at/after install; fall back to bootstrap invoking it if apm can't auto-run it. `apm run` is manual/experimental in 0.19 — verify before committing to auto-postinstall.
   - **Non-negotiable:** apm can validate its OWN deploy (`apm targets`/`--frozen`/`apm audit`) but CANNOT validate the specialized team (it doesn't exist pre-bootstrap); agents stay raw assets that only bootstrap specializes. Keep the cut: apm/assembler = placement, bootstrap = specialization.
