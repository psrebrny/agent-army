---
name: adapt-army
description: Turn user feedback into a safe, durable improvement to this repo's Agent Army. Use when the user corrects an agent, identifies a repeatable weakness, asks for a better workflow, or needs a missing specialist. Not for one-off task changes.
---
# /adapt-army — feedback router and team-level evolution

## 0 · Fix the present, then learn the lesson

When feedback identifies a defect in the active task, first repair it inside the already approved scope.
If the task is under `/ship`, use the required RED → implementation → GREEN/review loop; do not turn a
lesson proposal into a shortcut around verification. A durable Army change is a separate change set and
normally waits for the next safe task/PR boundary. Apply it immediately only when it is necessary to
continue correctly.

## 1 · Qualify the signal

Normalize the feedback without copying private text, secrets or a full transcript. Decide:

- **Task-local** — applies only here. Correct the task; do not propose an Army change.
- **Ambiguous** — ask one question: “Should this become a rule for future work in this repo?”
- **Durable** — classify and propose below. Explicit “from now on”, repeated evidence, a broken handoff,
  or a missing recurring capability is sufficient evidence; do not require a magic phrase.

Do not repeatedly raise a declined proposal unless new, material evidence changes its scope or risk.

## 2 · Inspect, then route to the smallest correct owner

Before proposing a change, read the live relevant `.agents/skills/<skill>/SKILL.md` files, applicable root
and nested `AGENTS.md` files, and local `.apm/agents` sources. Do not use `.opencode/skills` or
`apm_modules` as instruction sources. Choose the narrowest owner and explain why it wins over alternatives:

| Signal | Owner |
|---|---|
| Repo-wide law, naming, architecture or policy | `AGENTS.md` plus every owning agent |
| One role's judgment, checklist or report | that existing `.apm/agents/agent-army-<role>.agent.md` |
| Handoff, scope, execution state or multi-role sequencing | the narrowest owning role, or a new skill only when it is a separate user-invoked workflow |
| Machine-enforceable rule | existing formatter/linter/test/config control; never a second conflicting control |
| Recurring, independent specialist with its own contract/tools/output | `/new-agent` |
| Recurring, user-invoked workflow with its own entry point | `/new-skill` |

Creating a new agent is justified only when no existing role can own the responsibility without losing
single-purpose scope. Creating a new skill is justified only when the user needs a distinct reusable
workflow, not merely a longer existing prompt. Core skills under `.agents/skills/` are APM-managed: never
edit them in a target repository.

## 3 · Persist the proposal locally and ask

Use `.agent-army/state.json` as ignored operational memory. Keep a small `improvements` collection keyed
by a stable fingerprint of the normalized observation, classification and chosen targets. It must contain
no raw user message, secret, blueprint path or `design-docs` reference:

```json
{
  "version": 1,
  "improvements": {
    "imp-<fingerprint>": {
      "status": "proposed | declined | approved | applied | superseded",
      "summary": "normalized, non-sensitive lesson",
      "classification": "existing_agent",
      "targets": ["AGENTS.md", ".apm/agents/agent-army-tester.agent.md"]
    }
  }
}
```

Write an **Army Improvement Proposal** in the user's language before every durable mutation:

```md
## Army Improvement Proposal
- Observation: [normalized, non-sensitive lesson]
- Current-task correction: [done / next safe boundary]
- Recommendation: [owner and exact paths]
- Why this, not alternatives: [brief reason]
- Planned write scope: [paths only]
- Verification: [checks/render]
- Question: [one approval question]
- Options: [apply | adjust | current fix only/decline | show details]
```

Approval covers only the displayed paths. A new finding, scope expansion or weakened guarantee needs a new
proposal. Never silently mutate the Army. Mark the local state `declined`, `approved` and `applied` as the
decision progresses.

## 4 · Apply after approval

1. Update `AGENTS.md` first when a repo law changes, then every routed agent so planning and review agree.
2. Put a role-specific responsibility in the owning local `.apm/agents` source. Use `/new-skill` only for
   a separate local, user-invoked workflow. Do not edit a package-managed core skill in a target repository.
3. Hand an independent role to `/new-agent`; hand a new user workflow to `/new-skill`.
4. Preserve external/disabled controls. Extend only the formatter, linter or test control the repository
   already owns; never create a competing config merely to enforce an agent preference.
5. Render through `apm install --frozen --target <target>` when agents or local skills changed, then run
   the relevant verification. Do not commit without explicit approval.

## <prompt_examples>
**EX 1 — task correction plus durable workflow lesson.** USER: “You started coding before I accepted the
test interpretation. Fix this task, and this must not happen again.” → Repair the task through TDD, then
read the live `ship` skill and route the durable local rule to `AGENTS.md` and, if necessary, the owning
local role source. Do not edit `.agents/skills/ship`.

**EX 2 — existing agent, not a new one.** USER: “Reviewer should reject endpoints that expose internal
database IDs.” → Route to `code-reviewer` and `AGENTS.md`; explain that this is a checklist addition, not
a new API-review agent.

**EX 3 — genuinely new capability.** USER: “Every release needs an explicit dependency-license report
before approval.” → Propose a distinct `/license-readiness` skill if no existing role owns that reusable,
user-invoked workflow; after approval route creation through `/new-skill`.

**EX 4 — correctly leave Army untouched.** USER: “For this PR, do not update the README.” → Record the
task-local direction and do not create an improvement proposal.
