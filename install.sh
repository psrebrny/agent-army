#!/usr/bin/env bash
# Claude Agent Army — instalator (uniwersalny). Wrzuca drużynę agentów + bariery do dowolnego repo.
# Użycie:  ./install.sh [--tool <claude|cursor|copilot|codex|opencode|gemini|auto|other>] [ścieżka-do-repo]
#   --tool  którego narzędzia użyjesz (domyślnie: claude). Dla nie-Claude: hooki Claude są nieaktywne,
#           twardą barierą zostają git pre-commit + CI; punktem wejścia jest AGENTS.md.
#   ścieżka domyślnie = bieżący katalog.
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
    -*) echo "Nieznana opcja: $1"; usage; exit 1 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else echo "Nadmiarowy argument: $1"; exit 1; fi ;;
  esac
done
TARGET="${TARGET:-$(pwd)}"

case "$TOOL" in
  claude|cursor|copilot|codex|opencode|gemini|auto|other) : ;;
  *) echo "    • Nieznany --tool: '$TOOL' (dozwolone: claude, cursor, copilot, codex, opencode, gemini, auto, other). Traktuję jak 'other'."; TOOL="other" ;;
esac
# Czy aktywować ścieżkę Claude Code (hooki + CLAUDE.md jako pamięć natywna)?
IS_CLAUDE=0; [ "$TOOL" = "claude" ] && IS_CLAUDE=1
COPY_CLAUDE_MD=0; { [ "$TOOL" = "claude" ] || [ "$TOOL" = "auto" ]; } && COPY_CLAUDE_MD=1

SRC="$(cd "$(dirname "$0")" && pwd)/template"

echo "==> Instaluję Agent Army do: $TARGET   (tool=$TOOL)"
[ -d "$SRC" ] || { echo "Błąd: brak katalogu template/ obok install.sh"; exit 1; }

# Przenośny rdzeń: agenci, szablony, skille, skrypty barier (verify/detect współdzielone przez git+CI).
mkdir -p "$TARGET/.claude"
cp -R "$SRC/.claude/." "$TARGET/.claude/"
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
if [ "$IS_CLAUDE" = "1" ]; then
  echo "    • Hooki Claude Code aktywne (.claude/settings.json)"
elif [ "$TOOL" = "auto" ]; then
  echo "    • tool=auto → bootstrap potwierdzi narzędzie; hooki Claude aktywne tylko jeśli to Claude Code"
else
  echo "    • tool=$TOOL → hooki Claude Code nieaktywne (.claude/settings.json bezczynny); twarda bariera = git pre-commit + CI"
fi

# CI workflow (opcjonalny, nie nadpisuje istniejącego)
if [ -d "$SRC/.github" ] && [ ! -e "$TARGET/.github/workflows/quality.yml" ]; then
  mkdir -p "$TARGET/.github/workflows"
  cp "$SRC/.github/workflows/quality.yml" "$TARGET/.github/workflows/quality.yml"
  echo "    • Dodano .github/workflows/quality.yml (CI reużywa verify.sh)"
fi

# AGENTS.md — UNIWERSALNY punkt wejścia (czyta go każdy z toolów; wstrzykujemy nazwę narzędzia).
if [ -f "$SRC/AGENTS.md" ]; then
  if [ -f "$TARGET/AGENTS.md" ]; then
    echo "    • AGENTS.md już istnieje — kickoff zapisuję jako AGENTS.army.md (scal ręcznie)"
    DEST_AGENTS="$TARGET/AGENTS.army.md"
  else
    DEST_AGENTS="$TARGET/AGENTS.md"
  fi
  sed "s/__ARMY_TOOL__/$TOOL/g" "$SRC/AGENTS.md" > "$DEST_AGENTS"
  echo "    • Zapisano $(basename "$DEST_AGENTS") (cross-tool punkt wejścia → .claude/skills/bootstrap)"
else
  echo "    • UWAGA: brak template/AGENTS.md — pomijam kickoff (dodaj go do paczki)"
fi

# CLAUDE.md — bogatsza pamięć natywna; tylko dla claude/auto (na innych toolach to martwy plik).
if [ "$COPY_CLAUDE_MD" = "1" ]; then
  if [ -f "$TARGET/CLAUDE.md" ]; then
    echo "    • CLAUDE.md już istnieje — szablon zapisuję jako CLAUDE.army.md (scal ręcznie)"
    cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.army.md"
  else
    cp "$SRC/CLAUDE.md" "$TARGET/CLAUDE.md"
  fi
else
  echo "    • tool=$TOOL → pomijam CLAUDE.md (pamięć trzyma przenośny AGENTS.md)"
fi

# Git pre-commit (twarda bariera na poziomie gita — niezależna od narzędzia)
if [ -d "$TARGET/.git" ]; then
  cp "$SRC/.claude/hooks/git-pre-commit.sh" "$TARGET/.git/hooks/pre-commit"
  chmod +x "$TARGET/.git/hooks/pre-commit"
  echo "    • Zainstalowano git pre-commit (skan sekretów + lint/testy)"
else
  echo "    • (brak .git — pomijam pre-commit; uruchom ponownie po 'git init')"
fi

# .gitignore
GI="$TARGET/.gitignore"; touch "$GI"
grep -qxF '.claude/settings.local.json' "$GI" 2>/dev/null || echo '.claude/settings.local.json' >> "$GI"

echo "==> Gotowe (tool=$TOOL)."
echo "    Następne kroki:"
echo "      cd \"$TARGET\""
if [ "$IS_CLAUDE" = "1" ]; then
  echo "      claude                       # start sesji"
  echo "      /bootstrap                   # NAJPIERW: czyta repo, pyta o luki, dopasowuje agentów do projektu"
  echo "      /agents                      # zobacz drużynę (6 agentów)"
  echo "      /ship \"opis zadania\"          # pełny pipeline (discovery -> blueprint -> TDD -> review)"
else
  echo "      # Otwórz repo w swoim narzędziu ($TOOL). Brak slash-komend → uruchom bootstrap z AGENTS.md:"
  echo "      #   wklej prompt z sekcji 'Kickoff prompt' w AGENTS.md, albo powiedz agentowi:"
  echo "      #   \"Follow .claude/skills/bootstrap/SKILL.md against this repo.\""
  echo "      # Potem dla każdego zadania: .claude/skills/ship/SKILL.md"
fi
echo "    Twarda bariera niezależna od narzędzia: git pre-commit + CI (.github/workflows/quality.yml)."
echo "    Wymagania: bash, python3 (bariery; bez niego fallback). Claude Code v2.x tylko dla trybu z hookami."
