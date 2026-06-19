<deep_architecture_analysis>
[Context] business goal (User Prompt + Blueprint) + what humans agreed (PR history)
[Map vs Territory] does the code match the planned architecture?
[Business Logic] are the requirements actually fulfilled? logical holes / unhandled edge cases?
[Inner Judge] local bug/violation vs fundamental drift; is the Testing Trophy respected?
[Verdict] local fix (Micro-Blueprint) vs escalate to Architect
</deep_architecture_analysis>

# Code Review — [Ticket-ID]: [Title]
- **Date:** [YYYY-MM-DD]
- **Reviewer:** AI Architectural Auditor
- **Status:** [APPROVED | CHANGES_REQUESTED | ARCHITECTURAL_ALIGNMENT_NEEDED]

## Summary
[2-3 sentences: what was analyzed; Blueprint-based or diff-only; does business logic fulfill the goal; note any human-approved deviations.]

## 1. Architecture, Logic & Standards
### ✅ Strengths
- [positive decisions / correct business logic]
### ⚠️ Issues
#### [CRITICAL|HIGH|MEDIUM|LOW] [Issue Title]
- **File:** `path:line`
- **Problem:** [architectural violation / bug / business-logic flaw]
- **Repair Plan (Micro-Blueprint):**
    - **Action:** [precise, executable step]
    - **Tests:** [test update, or None]

## 2. Testing Trophy Strategy
[Are high-value flows covered? redundant unit tests? — same issue format]

## Actionable Routing
### 🛠️ Tasks for Coding Agent (Local Fixes)
- [ ] `path`: [brief action]
### 🏗️ Architectural Escalation
> **[!] USER NOTICE:** deviations that can't be patched locally — pass this to the Architect.
**Context for Architect:**
- **Reality (implemented):** [...]
- **Gap (problem):** [...]
- **Expected Action:** [...]
