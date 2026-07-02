> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.


## PR #3: Shared agent core (single, tool-agnostic source)
     **Objective:** Make the agent CONTENT live once, tool-agnostic, so the assembler is the only thing that shapes it per tool. (Depends on PR#2 so the assembler can retarget onto `core/`.)

---

### Task 3.1: Extract `baseline/agents/*` → `core/agents/*` (paths removed, content whole)

**Action:**
Move the agent definitions to `core/agents/` and strip everything tool-specific so the file is pure content (role, principles, scope, workflow, **inline output-skeleton**, prompt-examples):
- Remove tool-path references from prose; where a path is unavoidable, use the descriptor-driven tokens the assembler resolves (`<AGENTS_DIR>`/`<SKILLS_DIR>`/`<TOOL_DIR>`) — the assembler substitutes them when emitting whole files.
- Keep `_STANDARD.md` in core too, but mark it so the assembler places it OUTSIDE the tool's agent-load dir (it is authoring reference, not a loadable agent).
- Point the assembler (PR#2) at `core/agents/` instead of `baseline/agents/`.
- **Contract:** the emitted files must be BYTE-COMPLETE agents (no `core/` include/pointer) — verify by diffing an assembled Claude agent against today's `baseline/agents/<name>.md` (should match modulo resolved paths).

**Target File(s):**
- `.apm/skills/bootstrap/baseline/core/agents/*.md` (moved)
- `.apm/skills/bootstrap/baseline/core/agents/_STANDARD.md`
- `.apm/skills/bootstrap/baseline/assemble.sh` (retarget source path)
- `scripts/check.sh` (baseline path update if needed)

**Verification Command:** `bash assemble.sh claude --dry-run && bash scripts/check.sh`

**Testing Strategy & Cases (Testing Trophy):**
- **INTEGRATION**: ✓ assembling `claude` from `core/` produces agents byte-equivalent (modulo resolved paths) to the pre-refactor `baseline/agents/`; ✓ `_STANDARD.md` lands outside the agent-load dir.
- **UNIT**: ✓ no `core/agents/*` file contains a hardcoded `.claude/`; ✓ each still passes the inline-skeleton check.

**TDD Execution & Auto-Critic:**
1. Snapshot today's assembled Claude output as the golden reference.
2. Move to `core/`; run assemble → diff vs golden → **RED** until parity.
3. Fix until **GREEN** (byte parity modulo paths).

**Aligns with:** "Agent CONTENT exists once" + "whole agents in output" (manifest §2/§3).

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** there is exactly ONE copy of each agent's content (in `core/`); assembled Claude output is indistinguishable from today's baseline.
