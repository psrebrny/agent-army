> **⚠️ SYSTEM INSTRUCTION FOR CODING AGENT:**
> 1. Read & absorb `00_CORE_MANIFEST.md` before any task.
> 2. **<auto_critic> EXECUTION LOCK:** after each task, run its Verification Command, fix errors, and DO NOT proceed until GREEN.

## PR #[ID]: [Layer Name]
**Objective:** [overall goal of this PR]

---

### Task [ID].1: [Task Name]

**Action:**
[Logic, architecture decisions and behavior — natural language, no source code.]
- **API/Component Contract:** [new/modified inputs, outputs, DTOs, public methods]
- [Constraint]

**Target File(s):**
- `[path]`

**Verification Command:** `[exact command]`

**Testing Strategy & Cases (Testing Trophy):**
- **E2E / INTEGRATION** (`[explicit test file path]`):
  - ✓ [Happy path — behavior assertion]
  - ✓ [Error state — e.g. force 500 / timeout]
- **COMPONENT** (`[path]`):   <!-- only if relevant / no backend -->
  - ✓ [state / validation]
- **UNIT** (`[path]`):        <!-- only if not redundant with E2E -->
  - ✓ [complex mapper / pure logic]

**TDD Execution & Auto-Critic:**
1. Write the tests above.
2. Run `[command]` → **MUST FAIL (RED)**.
3. Implement in the Target Files.
4. Run `[command]` → **MUST PASS (GREEN)**. If it fails, STOP and fix immediately.

**Aligns with:** [rule from Architecture Proposal]

---

> **✅ PR Manual Acceptance:**
> - [ ] **Functional:** [which flow to test manually]
