# `tools/*.yml` — per-tool packaging descriptors

Each file is pure data (no logic, no prose "if the tool is X") describing where one coding
tool wants its materialized team to live: `dirs` (`agents`/`skills`/`hooks`/`config_root` —
`null` means "not confirmed, don't guess"; optional `agent_file_suffix`, default `.md`, for
tools that require a non-standard agent filename like Copilot's `.agent.md`), `frontmatter`
(`accepts_tools_field`, `model_field` notes), `capabilities` (`subagents`, `hook_mechanism`:
`claude-settings`|`git-only`, `auto_loads_skills`, `commands_dir`, `skill_invocation`:
`native-command`|`invoke-by-path`), and `hooks_live` (exactly which `baseline/hooks/*.sh`
actually fire for this tool — inert ones are omitted, never copied). `assemble.sh <tool>`
reads `tools/<tool>.yml` (or `_default.yml` if the name isn't found) and is the ONLY thing
that interprets this data — adding a new tool means adding one descriptor file here, not
editing prose in `SKILL.md` or `assemble.sh`.
`claude.yml`/`opencode.yml`/`cursor.yml`/`gemini.yml`/`copilot.yml` are `status: first-class`
(dirs verified against each tool's real, current docs — dated in each file's header comment,
since these products move fast and a stale "confirmed" is worse than an honest "unverified").
`codex.yml` is `status: stub` despite Codex having real subagents, because its format is TOML,
not Markdown — our assembler can't emit it yet (see codex.yml). `windsurf.yml` is `status: stub`
because Windsurf/Cascade genuinely has no per-agent file mechanism, only a plain AGENTS.md.
`_default.yml` is the fallback for any unrecognized tool name. **Re-verify before trusting an
old "first-class"/"stub" label** — several of these were flipped once already after a fresh docs
check contradicted an earlier, unverified guess; these products change fast enough that a
label from months ago may already be stale.
