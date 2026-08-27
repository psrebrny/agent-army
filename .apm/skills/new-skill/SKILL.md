---
name: new-skill
description: Author a new repo-local Agent Army skill when a reusable user-invoked workflow needs its own entry point. Use after /adapt-army has ruled out an existing skill or agent.
---
# /new-skill — create a focused local workflow

Create a new skill only for a recurring, user-invoked workflow with its own useful entry point. A
role-specific checklist or orchestration adjustment belongs in the narrowest existing agent or repo rule.
Do not create a skill merely because one task was awkward.

## 1 · Confirm the capability boundary

Before writing, state the single workflow this skill owns, its trigger, inputs, outputs, read/write
scope, stop conditions and relationship to existing `/ship`, `/bootstrap`, `/adapt-army` and agents.
Show the proposed name and get explicit approval. Names are lowercase kebab-case and must not collide
with an APM-managed core skill or an existing local skill.

## 2 · Author the local source

The source is `.apm/skills/<name>/SKILL.md`, never `.agents/skills/` or a target-native rendered
directory. Keep the frontmatter discriminating (`name`, `description` with “Use when…”), then include
only the purpose, workflow, safety/scope boundaries, output contract and realistic prompt examples the
workflow actually needs. Put substantial conditional detail in a referenced file only when it saves
every invocation from loading irrelevant instructions.

If the target exposes command wrappers, add `.apm/commands/<name>.md` pointing to
`.agents/skills/<name>/SKILL.md`. Create scripts or assets only when a deterministic helper or output
asset materially improves repeatability. A new skill must not weaken tests, security barriers, approval
gates or another skill's ownership.

## 3 · Render and verify

Ensure the project has an APM manifest. Render through APM:

```bash
apm install --frozen --target <target>
```

Confirm the rendered skill exists in `.agents/skills/<name>/SKILL.md`, the wrapper points to that path,
and the active target can discover or invoke it. Run the repository's relevant structural checks when
available. Report the source path, rendered path, invocation, ownership boundary and any intentionally
absent automation.

## Output

```md
## New Skill Result
- Name / invocation: [name and how the user invokes it]
- Responsibility: [one workflow]
- Source / rendered path: [.apm source -> rendered path]
- Inputs / outputs: [contract]
- Safety boundaries: [what it cannot do]
- Verification: [APM render and checks]
## Handoff
- STATUS: [done | partial | awaiting_approval | needs_input | blocked]
- VERIFIED: [commands/results]
- ASSUMPTIONS: [explicit]
- OUT_OF_SCOPE: [explicit]
- OPEN_QUESTIONS: [none or list]
```

## <prompt_examples>
**EX 1 — create a real workflow.** USER: “Every release needs the same dependency-risk summary before
the PR. Create a `/release-readiness` workflow, not another reviewer.” → Confirm it has a distinct
user-invoked input/output, create `.apm/skills/release-readiness/SKILL.md`, add the wrapper, render and
report its invocation.

**EX 2 — correctly avoid a new skill.** USER: “Reviewers should always call out public API compatibility.”
→ This is a `code-reviewer` rule, not a new workflow. Route it to `/adapt-army` and an existing-agent
change instead of creating `/api-review`.
