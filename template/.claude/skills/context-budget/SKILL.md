---
name: context-budget
description: Token & context discipline for the Agent Army — how to spend the cheapest adequate model, plan before acting, script instead of prompting, externalize state to files, and keep sessions short. Load this when a task is large, repetitive, data-heavy, or when deciding which agent/model to use.
---
# context-budget — spend the least context that still does the job

The Army's quality bar is non-negotiable; its *cost* is not fixed. Most waste comes from
using a strong model for cheap work, discovering the next step through chat round-trips instead
of planning, pasting big payloads into the conversation, and letting one session grow forever.
These rules cut usage without weakening any guarantee. They are defaults, not excuses to skip a
gate.

## 1 · Right model for the job
- `opus` — hard reasoning only: `architect` (planning/blueprints), `code-reviewer` and
  `security-auditor` (depth pays off here — reserve the strong model for review/security).
- `sonnet` — `tester`, `perf-auditor`: structured work against a clear contract.
- `haiku` — `docs-writer` and any high-volume, low-judgment editing.
- New agents (`/new-agent`): start at the **cheapest tier that passes**, justify upgrades in the
  frontmatter — never default to `opus`.

## 2 · Plan first, interact less
A blueprint in `design-docs/` is a token optimization, not just process: the agent follows a
written path instead of rediscovering each step through back-and-forth. Settle goal / stack /
test strategy / acceptance criteria **before** writing files. "Assume and go" → record
ASSUMPTIONS and continue rather than burning a round-trip per question.

## 3 · Script instead of LLM
Never ask a model to map/filter/sort/transform a large file in chat. Paste a few sample lines,
have it **write a script** (bash/python), run it locally for ~0 tokens. The hook layer already
embodies this — `guard/format/verify/gate/detect.sh` are deterministic bash, zero LLM calls. When
a check is mechanical, push it into a hook or a script, not into a prompt.

## 4 · Pass pointers, read scoped
- Hand subagents **file paths and the blueprint section**, not pasted file bodies. They have their
  own context window and can read what they need.
- Read the slice you need (`offset`/`limit`, the touched function), not whole files "for safety".
- Keep the stable prefix (`AGENTS.md`, `CLAUDE.md`, agent defs) **stable** so it stays cached;
  put volatile detail in skills/rules that load on demand — don't inline it into the always-loaded
  files. This is why `AGENTS.md` stays a pointer index, not an encyclopedia.

## 5 · Match the pipeline to the task
`/ship` is the full chain (architect → tester → reviewer → security → docs). For a **trivial**
change (typo, one field, a constant) that cold-starts five subagents for no quality gain. Default
small tasks to the **inline Red→Green** path in the main session; reserve the full fan-out for
non-trivial work. Run the read-only audits (review/security/perf) in **parallel** — they don't
depend on each other. Effort and model tier should track task difficulty, not habit.

## 6 · Avoid infinite sessions — externalize, don't accumulate
Long sessions get more expensive every turn (you re-pay input tokens) and the model drifts. The
Army is built to make short sessions safe **because state lives in files, not in chat**:
- The blueprint (`design-docs/[Task-ID]/`), reviews (`reviews/`) and reports (`reports/`) are the
  memory — a fresh session reloads them in seconds.
- "1 PR = 1 file" is a resume boundary: do **one task/PR per session**, then start clean.
- Subagents isolate context — they do heavy work in their own window and return a short result, so
  the orchestrator's context stays lean. Prefer "delegate → get summary" over doing everything in
  the main thread.
- Don't keep a single `/ship` running across an entire epic. When a task is done, close it; the
  next session rehydrates from `design-docs/`.

## 7 · Language & locality
- Agent-facing text (agents, skills, `AGENTS.md`, `CLAUDE.md`, prompts) in **English** — Polish
  morphology costs ~1.5× the tokens per word. Keep Polish only where a human needs it.
- When an open-weight local model is adequate (light edits, knowledge-gathering, simple
  automation), prefer it over a frontier model for routine, cost-sensitive runs.

## Self-check (before a costly run)
- [ ] Cheapest model tier that still meets the bar?
- [ ] Plan/contract settled, so the agent isn't discovering steps in chat?
- [ ] Bulk data handled by a script, not pasted into the prompt?
- [ ] Subagents get pointers + scoped reads, not pasted payloads?
- [ ] Trivial task on the inline path, not the full five-agent fan-out?
- [ ] State in `design-docs/` so this session can stay short?
