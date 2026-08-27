---
name: adapt-army
description: Turn user feedback into a safe, durable improvement to this repo's Agent Army. Use when the user corrects an agent, identifies a repeatable weakness, asks for a better workflow, or needs a missing specialist. Not for one-off task changes.
---
# /adapt-army — feedback router and team-level evolution

Before following this skill, read `.agent-army/overrides/skills/adapt-army.md` when it exists. It may
refine this repo's routing, but never weakens security, approval gates or hard rules.

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

## 2 · Route to the smallest correct owner

Choose the narrowest owner and explain why it wins over the alternatives:

| Signal | Owner |
|---|---|
| Repo-wide law, naming, architecture or policy | `AGENTS.md` plus every owning agent |
| One role's judgment, checklist or report | that existing `.apm/agents/agent-army-<role>.agent.md` |
| Handoff, scope, execution state or multi-role sequencing | local overlay `.agent-army/overrides/skills/<core-skill>.md` |
| Machine-enforceable rule | existing formatter/linter/test/config control; never a second conflicting control |
| Recurring, independent specialist with its own contract/tools/output | `/new-agent` |
| Recurring, user-invoked workflow with its own entry point | `/new-skill` |

Creating a new agent is justified only when no existing role can own the responsibility without losing
single-purpose scope. Creating a new skill is justified only when the user needs a distinct reusable
workflow, not merely a longer existing prompt. Core skills under `.agents/skills/` are APM-managed: never
edit them in a target repository. In the Agent Army source repo, a confirmed package-wide improvement may
edit the packaged source directly.

## 3 · Persist the proposal locally and ask

Use `.agent-army/state.json` as ignored operational memory. Keep a small `improvements` collection keyed
by a stable fingerprint of the normalized signal, classification and targets:

```json
{
  "version": 1,
  "improvements": {
    "imp-<fingerprint>": {
      "status": "proposed | declined | approved | applied | superseded",
      "summary": "normalized, non-sensitive lesson",
      "classification": "existing_skill",
      "targets": [".agent-army/overrides/skills/ship.md"],
      "evidence": ["design-docs/ABC/01_PR_1.md"],
      "upstream_candidate": false
    }
  }
}
```

Write an **Army Improvement Proposal** in the user's language before every durable mutation:

```md
## Army Improvement Proposal
- Feedback: [normalized lesson and evidence]
- Current-task correction: [done / next safe boundary]
- Recommendation: [owner and exact paths]
- Why this, not alternatives: [brief reason]
- Planned write scope: [paths only]
- Verification: [checks/render]
- Upstream candidate: [yes/no and why]
- Question: [one approval question]
- Options: [apply | adjust | current fix only/decline | show details | prepare upstream proposal]
```

Approval covers only the displayed paths. A new finding, scope expansion or weakened guarantee needs a new
proposal. Never silently mutate the Army. Mark the local state `declined`, `approved` and `applied` as the
decision progresses.

## 4 · Apply after approval

1. Update `AGENTS.md` first when a repo law changes, then every routed agent so planning and review agree.
2. For a core-skill behavior change, create or update its overlay with the durable rule, evidence and a
   statement that it cannot weaken safety. For an actual package defect in this source repo, update the
   packaged skill instead.
3. Hand an independent role to `/new-agent`; hand a new user workflow to `/new-skill`.
4. Preserve external/disabled controls. Extend only the formatter, linter or test control the repository
   already owns; never create a competing config merely to enforce an agent preference.
5. Render through `apm install --frozen --target <target>` when agents or local skills changed, then run
   the relevant verification. Do not commit without explicit approval.

For a package-wide issue discovered in a target repo, set `upstream_candidate: true`; never edit another
checkout or publish. On “prepare upstream proposal”, write a concise, reviewable proposal under
`design-docs/agent-army-improvements/` with reproduction, expected behavior, proposed source paths and
tests.

## <prompt_examples>
**EX 1 — task correction plus durable workflow lesson.** USER: “You started coding before I accepted the
test interpretation. Fix this task, and this must not happen again.” → Repair the task through TDD, then
propose an overlay for `ship` with the evidence and exact write scope. Do not edit `.agents/skills/ship`.

**EX 2 — existing agent, not a new one.** USER: “Reviewer should reject endpoints that expose internal
database IDs.” → Route to `code-reviewer` and `AGENTS.md`; explain that this is a checklist addition, not
a new API-review agent.

**EX 3 — genuinely new capability.** USER: “Every release needs an explicit dependency-license report
before approval.” → Propose a distinct `/license-readiness` skill if no existing role owns that reusable,
user-invoked workflow; after approval route creation through `/new-skill`.

**EX 4 — correctly leave Army untouched.** USER: “For this PR, do not update the README.” → Record the
task-local direction and do not create an improvement proposal.
