#!/usr/bin/env bash
# Git pre-commit: last barrier before a commit (secret scan + lint/tests).
# Installed to .git/hooks/pre-commit by /bootstrap.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 0

if git diff --cached --name-only | grep -Eq '(^|/)(\.env($|\.)|.*\.pem$|.*\.key$|id_rsa)'; then
  echo "pre-commit: attempt to commit a file with secrets — rejected." >&2
  exit 1
fi

# Locate verify.sh in whichever tool dir /bootstrap materialized it into (tool-agnostic).
for d in .claude .opencode .cursor .codex .gemini .windsurf .agents; do
  if [ -x "$ROOT/$d/hooks/verify.sh" ]; then
    CLAUDE_PROJECT_DIR="$ROOT" "$ROOT/$d/hooks/verify.sh" \
      || { echo "pre-commit: lint/tests are failing — commit halted." >&2; exit 1; }
    break
  fi
done
exit 0
