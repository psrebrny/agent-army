---
name: new-agent
description: Author a NEW subagent (or upgrade an existing one) to the project's quality bar. Use when adding a role to the team. Reads the standard, asks a few questions, writes the agent + its output template, and runs the quality self-check.
---
# /new-agent — create an agent to the standard

1. **Read the bar:** open `.claude/agents/_STANDARD.md` and the exemplar `.claude/agents/architect.md` for tone, depth and rigor. Your output must match that care.
2. **Clarify (few questions):** role & single responsibility · when to delegate (drives `description`) · minimal tools · model (opus/sonnet/haiku, justified) · what it outputs.
3. **Recon the repo:** stack, conventions, exact commands — so the agent is repo-adaptive, not generic.
4. **Write `.claude/agents/<name>.md`** following the standard's 8-section structure, with 2–3 concrete `<prompt_examples>` using THIS repo's paths/commands. If it produces a report, also create `.claude/templates/reports/<name>.template.md` and point the agent at it.
5. **Run the standard's self-check**; fix every NO before saving.
6. **Integration:** if it belongs in `/ship`, tell the user where to slot it and whether to add a hook.

Do not ship a generic or thin agent. If you can't make it as rigorous as `architect`, say what's missing and ask.
