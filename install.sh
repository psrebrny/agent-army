#!/usr/bin/env bash
# Claude Agent Army — installer (universal). Drops the agent team + barriers into any repo.
# Usage:  ./install.sh [--tool <claude|cursor|copilot|codex|opencode|gemini|auto|other>] [path-to-repo]
#   --tool  which tool you'll use (default: claude). For non-Claude: Claude hooks are inert,
#           the hard barrier becomes git pre-commit + CI; the entry point is AGENTS.md.
#   path defaults to the current directory.
set -euo pipefail

usage() {
  sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
}

TOOL="claude"
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tool) TOOL="${2:-}"; shift 2 ;;
    --tool=*) TOOL="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1"; usage; exit 1 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else echo "Extra argument: $1"; exit 1; fi ;;
  esac
done
TARGET="${TARGET:-$(pwd)}"

case "$TOOL" in
  claude|cursor|copilot|codex|opencode|gemini|auto|other) : ;;
  *) echo "    • Unknown --tool: '$TOOL' (allowed: claude, cursor, copilot, codex, opencode, gemini, auto, other). Treating as 'other'."; TOOL="other" ;;
esac
# Activate the Claude Code path (hooks + CLAUDE.md as native memory)?
IS_CLAUDE=0; [ "$TOOL" = "claude" ] && IS_CLAUDE=1
COPY_CLAUDE_MD=0; { [ "$TOOL" = "claude" ] || [ "$TOOL" = "auto" ]; } && COPY_CLAUDE_MD=1

SRC="$(cd "$(dirname "$0")" && pwd)/template"

echo "==> Installing Agent Army into: $TARGET   (tool=$TOOL)"
[ -d "$SRC" ] || { echo "Error: no template/ directory next to install.sh"; exit 1; }

# Portable core: agents, templates, skills, barrier scripts (verify/detect shared by git+CI).
mkdir -p "$TARGET/.claude"
cp -R "$SRC/.claude/." "$TARGET/.claude/"
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
if [ "$IS_CLAUDE" = "1" ]; then
  echo "    • Claude Code hooks active (.claude/settings.json)"
elif [ "$TOOL" = "auto" ]; then
  echo "    • tool=auto → bootstrap will confirm the tool; Claude hooks active only if it's Claude Code"
else
  echo "    • tool=$TOOL → Claude Code hooks inert (.claude/settings.json idle); hard barrier = git pre-commit + CI"
fi

# CI workflow (optional, does not overwrite an existing one)
if [ -d "$SRC/.github" ] && [ ! -e "$TARGET/.github/workflows/quality.yml" ]; then
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
  cp "$SRC/.claude/hooks/git-pre-commit.sh" "$TARGET/.git/hooks/pre-commit"
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
