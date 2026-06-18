#!/usr/bin/env bash
# Stop: bramka jakości — nie pozwól zakończyć tury, dopóki lint/testy nie są zielone.
# WAŻNE: respektuje stop_hook_active (kontrakt Claude Code), inaczej blokuje w nieskończoność.
INPUT="$(cat)"

# Ponowne odpalenie po wcześniejszym "block" -> pozwól modelowi zakończyć (koniec pętli).
if printf '%s' "$INPUT" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/detect.sh"
[ -z "$LINT_CMD$TEST_CMD" ] && exit 0          # brak checków -> nie blokuj

if "$DIR/verify.sh" >/tmp/cc_gate.log 2>&1; then
  exit 0
fi

LOG="$(tail -c 1800 /tmp/cc_gate.log)"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$LOG" <<'PY'
import sys, json
print(json.dumps({"decision":"block","reason":
  "Bramka jakości: lint/testy nie przechodzą. Napraw przyczynę i zakończ ponownie.\n\n"+sys.argv[1]}))
PY
else
  echo "Bramka jakosci: lint/testy nie przechodza. Napraw i zakoncz ponownie." >&2
  exit 2
fi
exit 0
