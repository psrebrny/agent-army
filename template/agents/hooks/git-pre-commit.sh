#!/usr/bin/env bash
# Git pre-commit: last barrier before a commit (secret scan + lint/tests).
# Installed to .git/hooks/pre-commit by install.sh.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 0

if git diff --cached --name-only | grep -Eq '(^|/)(\.env($|\.)|.*\.pem$|.*\.key$|id_rsa)'; then
  echo "pre-commit: attempt to commit a file with secrets — rejected." >&2
  exit 1
fi

if [ -x "$ROOT/.claude/hooks/verify.sh" ]; then
  CLAUDE_PROJECT_DIR="$ROOT" "$ROOT/.claude/hooks/verify.sh" \
    || { echo "pre-commit: lint/tests are failing — commit halted." >&2; exit 1; }
fi
exit 0
