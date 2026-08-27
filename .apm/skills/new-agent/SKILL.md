---
name: new-agent
description: Author a NEW subagent (or upgrade an existing one) to the project's quality bar. Use when adding a role to the team. Reads the standard, asks a few questions, writes the agent (with its output skeleton embedded), and runs the quality self-check.
---
# /new-agent — create an agent to the standard

1. **Read the bar:** open `.agents/skills/bootstrap/baseline/core/agents/_STANDARD.md`. Use `.apm/agents/agent-army-architect.agent.md` as the exemplar when it exists; the rendered native output is `.opencode/agents` for OpenCode, so do not author directly in that rendered directory.
2. **Clarify (few questions):** role & single responsibility · when to delegate (drives `description`) · minimal tools · model (opus/sonnet/haiku, justified) · what it outputs.
3. **Recon the repo:** stack, conventions, exact commands — so the agent is repo-adaptive, not generic.
4. **Write the new agent source** as `.apm/agents/agent-army-<name>.agent.md` following the standard's 8-section structure, with 2–3 concrete `<prompt_examples>` using THIS repo's paths/commands. If it produces a report, embed the report skeleton directly in its `## Output` section (fenced, with placeholders) — no separate template file. Then render it with `apm install --frozen --target <target>`.
5. **Run the standard's self-check**; fix every NO before saving.
6. **Integration:** if it belongs in `/ship`, tell the user where to slot it and whether to add a hook.

Do not ship a generic or thin agent. If you can't make it as rigorous as `architect`, say what's missing and ask.
