---
description: One-time setup of agent team for THIS repo. Materializes baseline agents/hooks, then specializes them to the codebase. Run once after installing agent-army.
---
Follow the instructions in `.agents/skills/bootstrap/SKILL.md`, except when this command's own tool directory also holds `skills/bootstrap/SKILL.md` (for Claude, `.claude/skills/bootstrap/SKILL.md`): follow that copy, because the shared one may be the older version a previous bootstrap left. If neither file exists, report an incomplete Agent Army installation and ask the user to run `apm install` or `apm update`; never guess a tool-specific skill directory.
