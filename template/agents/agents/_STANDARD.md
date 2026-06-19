# Agent Authoring Standard — the quality bar

Every agent in `.claude/agents/` — shipped, repo-specialized by `/bootstrap`, or created by
`/new-agent` — MUST meet this bar. Hold each generated agent to the same care and depth as the
hand-crafted `architect.md` (use it as the reference exemplar).

## Required structure (every agent file)
1. **Frontmatter** — `name`; `description` that says **WHEN to delegate** ("Use when…"); `tools` = the **minimal** set (read-only unless it must write); `model` — the concrete model name for this repo/tool, assigned during `/bootstrap` by tier: **strong** (hard reasoning/planning/audit), **mid** (review/test/structured analysis), **light** (docs/high-volume/cheap edits). Choice must be justifiable; don't default to the strongest if mid is sufficient.
2. **Role & Purpose** — one tight paragraph; a single clear responsibility.
3. **Principles** — the non-negotiables. Use **BAD/GOOD** contrasts where a behavior is easy to get wrong.
4. **Scope / What it checks or produces** — concrete and domain-specific, never generic.
5. **Workflow** — ordered steps the agent follows.
6. **Output** — point to the authoritative template in `.claude/templates/…`; never improvise structure.
7. **Edge cases** — overload, missing context, ambiguity, "nothing found".
8. **`<prompt_examples>`** — 2–3 CONCRETE examples with real-looking file paths and explicit assertions. They must be **VARIED**, not three slants on one scenario: span different cases the agent actually meets (e.g. different Testing-Trophy levels, UI vs backend vs pure-logic, happy path vs error/edge). When specialized to a repo, use that repo's real paths, commands and framework syntax.

## Quality rules (apply to all)
- Single responsibility; minimal tools; least privilege.
- **Behavior over implementation**; name **explicit file paths**, never abstract tags.
- Severity/priority discipline where it ranks things — no inflation, no false-positive spam.
- **Never weaken guarantees** to "pass" (tests, gates, reviews, audits).
- Repo-adaptive: mirror existing conventions; reuse over reinvention.
- Concrete beats generic: every rule must change behavior — cut filler.

## Self-check before saving an agent (ALL must be YES)
- [ ] Frontmatter complete; `description` states WHEN to use it; tools minimal; model justified.
- [ ] Contains Role, Principles, Scope, Workflow, Output(→template), Edge cases.
- [ ] ≥2 concrete `<prompt_examples>` with real paths/assertions, and they are VARIED (different scenario types, not duplicates).
- [ ] Domain-specific (names this repo's stack/commands when specialized).
- [ ] No generic filler; each rule changes behavior.
- [ ] Guarantees are not weakenable; least privilege respected.
