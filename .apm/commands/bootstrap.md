---
description: One-time setup of agent team for THIS repo. Materializes baseline agents/hooks, then specializes them to the codebase. Run once after installing agent-army.
---
Follow the instructions in `.agents/skills/bootstrap/SKILL.md`. On Claude the skill is native in `.claude/skills/bootstrap/SKILL.md` and this wrapper is not used. If that file is missing, report an incomplete Agent Army installation and ask the user to run `apm install` or `apm update`; never guess a tool-specific skill directory.
