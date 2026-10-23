---
name: new-agent
description: Author a NEW subagent (or upgrade an existing one) to the project's quality bar. Use when adding a role to the team. Reads the standard, asks a few questions, writes the agent (with its output skeleton embedded), and runs the quality self-check.
---
# /new-agent — create an agent to the standard

1. **Read the bar:** open `../bootstrap/baseline/core/agents/_STANDARD.md` and [repository-context.md](../bootstrap/references/repository-context.md) (relative to this file; the skills may be installed globally). Run `python3 ../bootstrap/army.py locate` with the task's `--cwd` and optional `--army-root`. Write local profile paths under its `army_root`, not necessarily its Git `repo_root`. Use the reported architect `contract_path` as the exemplar; `.agent-army/agents` is the only role directory for every tool.
2. **Clarify (few questions):** role & single responsibility · when to delegate (drives `description`) · minimal tools · model (opus/sonnet/haiku, justified) · what it outputs.
3. **Recon the repo:** stack, conventions, exact commands — so the agent is repo-adaptive, not generic.
4. **Write the new agent source** as `.agent-army/agents/agent-army-<name>.agent` under `army_root` only for a genuinely new local role. To upgrade an existing role, edit its reported specialized `contract_path` in place, preserving a legacy `.agent.md` suffix; never create a duplicate `.agent` beside it. Follow the standard's 8-section structure, with 2–3 concrete `<prompt_examples>` using THIS repo's paths/commands. If it produces a report, embed the report skeleton directly in its `## Output` section (fenced, with placeholders) — no separate template file. Nothing is rendered: skills dispatch it straight from that file (`army.py role <name>`, with the same selection), in every tool. Never write a native copy (`.claude/agents`, `.codex/agents`, …).
5. **Run the standard's self-check**; fix every NO before saving.
6. **Integration:** if it belongs in `/ship`, tell the user where to slot it and whether to add a hook.

Do not ship a generic or thin agent. If you can't make it as rigorous as `architect`, say what's missing and ask.
