> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #4: Slim `SKILL.md` — bootstrap keeps only the judgment work
**Objective:** Remove the per-tool packaging prose from `bootstrap/SKILL.md` (it now lives in the assembler) and leave ONLY what needs an LLM: recon + specialization + AGENTS.md content + policy + calling the assembler + verify. (Depends on PR#2/#3.)

---

### Task 4.1: Rewrite Step 0 to call the assembler; keep recon/specialize/verify

**Action:**
Restructure `bootstrap/SKILL.md`:
- **Step 0 becomes:** detect the tool (or ask once) → `bash <skill>/assemble.sh <tool>` → report what landed. DELETE the prose that the assembler now owns: per-tool hook selection, path/placeholder substitution, husky wiring, `.gitignore` edits, settings.json gating.
- **Keep (the judgment half):
- ** Step 1 recon (deep), 
- Step 2 policy interview, 
- **Step 3 = specialize the assembled agents in place** (inject real commands/laws/idioms/model tiers) — state explicitly this is bootstrap's primary job — author AGENTS.md content, write `army.conf`; 
- Step 4 consistency/evidence gates; 
- Step 5 verify (run lint/tests once + `grep` for leftover placeholders + optionally `assemble.sh --reconcile`).
- Make explicit: **order is assemble → specialize → verify**, and re-runs re-specialize in place (assembler skips existing).
- **Contract:** after this PR, no packaging branching ("if Claude … else …") remains in `SKILL.md`; the only tool-conditional left is which descriptor name is passed to the assembler.

**Target File(s):**
- `.apm/skills/bootstrap/SKILL.md`

**Verification Command:** `! grep -nE 'if the tool is NOT Claude|sed -i|guard/format/gate|core.hooksPath' .apm/skills/bootstrap/SKILL.md && echo "packaging prose gone"`

**Testing Strategy & Cases (Testing Trophy):**
- **INTEGRATION** (grep gates): ✓ no `sed`/placeholder/husky/hook-selection prose remains in `SKILL.md`; ✓ `SKILL.md` references `assemble.sh` in Step 0; ✓ Step 3 explicitly names "specialize to the repo" as the primary job.
- **UNIT**: ✓ `SKILL.md` still contains recon + policy interview + verify steps (not accidentally deleted).

**TDD Execution & Auto-Critic:**
1. Write the grep-based gates (both the "must be absent" and "must be present" sets).
2. Run → **RED** (packaging prose still present).
3. Rewrite `SKILL.md`.
4. Run → **GREEN**. Do not delete the judgment steps to pass a gate.

**Aligns with:** "bootstrap does ONLY judgment work" (manifest §2) — kills the soft-ifs at the source.

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** a reader of `SKILL.md` sees a short judgment-only routine; all "where files go per tool" lives in the assembler + descriptors.
