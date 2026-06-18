#!/usr/bin/env bash
# Git pre-commit: ostatnia bariera przed commitem (skan sekretów + lint/testy).
# Instalowany do .git/hooks/pre-commit przez install.sh.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 0

if git diff --cached --name-only | grep -Eq '(^|/)(\.env($|\.)|.*\.pem$|.*\.key$|id_rsa)'; then
  echo "pre-commit: próba commita pliku z sekretami — odrzucono." >&2
  exit 1
fi

if [ -x "$ROOT/.claude/hooks/verify.sh" ]; then
  CLAUDE_PROJECT_DIR="$ROOT" "$ROOT/.claude/hooks/verify.sh" \
    || { echo "pre-commit: lint/testy nie przechodzą — commit wstrzymany." >&2; exit 1; }
fi
exit 0
