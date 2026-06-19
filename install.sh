#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Claude Agent Army — installer (universal)

Usage: ./install.sh [--tool <tool>] [--no-ci] [path-to-repo]

Options:
  --tool <tool>   Which AI tool you use in this repo (default: claude).
  --no-ci         Skip adding Agent Army's CI workflow.
  -h, --help      Show this help.
  path            Target repo directory (default: current directory).

Available tools:
  claude      Claude Code (claude.ai/code) — full hook mode; lifecycle barriers + slash commands
  cursor      Cursor IDE — hooks inert; barrier = git pre-commit + CI; entry point = AGENTS.md
  copilot     GitHub Copilot (VS Code / JetBrains) — same as cursor
  codex       OpenAI Codex CLI — same as cursor
  opencode    OpenCode CLI — same as cursor
  gemini      Gemini CLI — same as cursor
  auto        Unknown / mixed — Claude hooks active; bootstrap will confirm the actual tool
  other       Any other tool — hooks inert; barrier = git pre-commit + CI

For non-Claude tools: Claude Code hooks are inert; the hard barrier is git pre-commit + CI;
the universal entry point is AGENTS.md (every tool reads it).
EOF
}

print_tools() {
  cat <<'EOF'
Available --tool values:
  claude      Claude Code (full hook mode)
  cursor      Cursor IDE
  copilot     GitHub Copilot
  codex       OpenAI Codex CLI
  opencode    OpenCode CLI
  gemini      Gemini CLI
  auto        Unknown/mixed (bootstrap confirms later)
  other       Any other tool

Defaulting to: claude
Run with --help for details.
EOF
}

TOOL=""
TARGET=""
NO_CI=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tool) TOOL="${2:-}"; shift 2 ;;
    --tool=*) TOOL="${1#*=}"; shift ;;
    --no-ci) NO_CI=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1"; usage; exit 1 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else echo "Extra argument: $1"; exit 1; fi ;;
  esac
done
TARGET="${TARGET:-$(pwd)}"

if [ -z "$TOOL" ]; then
  print_tools
  echo ""
  TOOL="claude"
fi

case "$TOOL" in
  claude|cursor|copilot|codex|opencode|gemini|auto|other) : ;;
  *) echo "    • Unknown --tool: '$TOOL'. Run ./install.sh --help to see available tools. Treating as 'other'."; TOOL="other" ;;
esac
# Activate the Claude Code path (hooks + CLAUDE.md as native memory)?
IS_CLAUDE=0; [ "$TOOL" = "claude" ] && IS_CLAUDE=1
COPY_CLAUDE_MD=0; { [ "$TOOL" = "claude" ] || [ "$TOOL" = "auto" ]; } && COPY_CLAUDE_MD=1

SRC="$(cd "$(dirname "$0")" && pwd)/template"

echo "==> Installing Agent Army into: $TARGET   (tool=$TOOL)"
[ -d "$SRC" ] || { echo "Error: no template/ directory next to install.sh"; exit 1; }

# Portable core: agents, templates, skills, barrier scripts (verify/detect shared by git+CI).
mkdir -p "$TARGET/.claude"
cp -R "$SRC/agents/." "$TARGET/.claude/"
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
if [ "$IS_CLAUDE" = "1" ]; then
  echo "    • Claude Code hooks active (.claude/settings.json)"
elif [ "$TOOL" = "auto" ]; then
  echo "    • tool=auto → bootstrap will confirm the tool; Claude hooks active only if it's Claude Code"
else
  echo "    • tool=$TOOL → Claude Code hooks inert (.claude/settings.json idle); hard barrier = git pre-commit + CI"
fi

# CI workflow (optional). Skip when: --no-ci, ours already present, or the repo brings its own CI.
CONF="$TARGET/.claude/army.conf"
existing_ci=""
[ -d "$TARGET/.github/workflows" ] && existing_ci="$(find "$TARGET/.github/workflows" -name '*.yml' -o -name '*.yaml' 2>/dev/null | head -1)"
if [ "$NO_CI" = "1" ]; then
  echo "    • --no-ci → skipping Agent Army CI (CI_MODE=off)"
  [ -f "$CONF" ] && sed -i.bak 's/^CI_MODE=.*/CI_MODE=off/' "$CONF" && rm -f "$CONF.bak"
elif [ -e "$TARGET/.github/workflows/quality.yml" ]; then
  echo "    • .github/workflows/quality.yml already present — leaving it as is"
elif [ -n "$existing_ci" ]; then
  echo "    • Repo already has CI ($(basename "$existing_ci")…) — NOT adding ours (CI_MODE=off). Override in .claude/army.conf."
  [ -f "$CONF" ] && sed -i.bak 's/^CI_MODE=.*/CI_MODE=off/' "$CONF" && rm -f "$CONF.bak"
elif [ -d "$SRC/.github" ]; then
  mkdir -p "$TARGET/.github/workflows"
  cp "$SRC/.github/workflows/quality.yml" "$TARGET/.github/workflows/quality.yml"
  echo "    • Added .github/workflows/quality.yml (CI reuses verify.sh)"
fi

# AGENTS.md — UNIVERSAL entry point (every tool reads it; we inject the tool name).
if [ -f "$SRC/AGENTS.md" ]; then
  if [ -f "$TARGET/AGENTS.md" ]; then
    echo "    • AGENTS.md already exists — saving the kickoff as AGENTS.army.md (merge manually)"
    DEST_AGENTS="$TARGET/AGENTS.army.md"
  else
    DEST_AGENTS="$TARGET/AGENTS.md"
  fi
  sed "s/__ARMY_TOOL__/$TOOL/g" "$SRC/AGENTS.md" > "$DEST_AGENTS"
  echo "    • Wrote $(basename "$DEST_AGENTS") (cross-tool entry point → .claude/skills/bootstrap)"
else
  echo "    • WARNING: no template/AGENTS.md — skipping kickoff (add it to the package)"
fi

# CLAUDE.md — richer native memory; only for claude/auto (a dead file on other tools).
if [ "$COPY_CLAUDE_MD" = "1" ]; then
  if [ -f "$TARGET/CLAUDE.md" ]; then
    echo "    • CLAUDE.md already exists — saving the template as CLAUDE.army.md (merge manually)"
    cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.army.md"
  else
    cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.md"
  fi
else
  echo "    • tool=$TOOL → skipping CLAUDE.md (memory lives in the portable AGENTS.md)"
fi

# Git pre-commit (hard barrier at the git level — tool-independent)
if [ -d "$TARGET/.git" ]; then
  cp "$SRC/agents/hooks/git-pre-commit.sh" "$TARGET/.git/hooks/pre-commit"
  chmod +x "$TARGET/.git/hooks/pre-commit"
  echo "    • Installed git pre-commit (secret scan + lint/tests)"
else
  echo "    • (no .git — skipping pre-commit; re-run after 'git init')"
fi

# .gitignore
GI="$TARGET/.gitignore"; touch "$GI"
grep -qxF '.claude/settings.local.json' "$GI" 2>/dev/null || echo '.claude/settings.local.json' >> "$GI"

echo "==> Done (tool=$TOOL)."
echo "    Next steps:"
echo "      cd \"$TARGET\""
if [ "$IS_CLAUDE" = "1" ]; then
  echo "      claude                       # start a session"
  echo "      /bootstrap                   # FIRST: reads the repo, asks about gaps, tailors agents to the project"
  echo "      /agents                      # see the team (6 core agents + optional coder)"
  echo "      /ship \"task description\"      # full pipeline (discovery -> blueprint -> TDD -> review)"
else
  echo "      # Open the repo in your tool ($TOOL). No slash commands → run bootstrap from AGENTS.md:"
  echo "      #   paste the prompt from the 'Kickoff prompt' section in AGENTS.md, or tell the agent:"
  echo "      #   \"Follow .claude/skills/bootstrap/SKILL.md against this repo.\""
  echo "      # Then for every task: .claude/skills/ship/SKILL.md"
fi
echo "    Tool-independent hard barrier: git pre-commit + CI (.github/workflows/quality.yml)."
echo "    Requirements: bash, python3 (barriers; a fallback runs without it). Claude Code v2.x only for hook mode."
