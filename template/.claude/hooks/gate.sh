#!/usr/bin/env bash
# Stop: quality gate — don't let the turn end until lint/tests are green.
# IMPORTANT: respects stop_hook_active (Claude Code contract), otherwise it blocks forever.
INPUT="$(cat)"

# Re-fired after a previous "block" -> let the model finish (end of the loop).
if printf '%s' "$INPUT" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/detect.sh"
[ -z "$LINT_CMD$TEST_CMD" ] && exit 0          # no checks -> don't block

if "$DIR/verify.sh" >/tmp/cc_gate.log 2>&1; then
  exit 0
fi

LOG="$(tail -c 1800 /tmp/cc_gate.log)"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$LOG" <<'PY'
import sys, json
print(json.dumps({"decision":"block","reason":
  "Quality gate: lint/tests are failing. Fix the cause and finish again.\n\n"+sys.argv[1]}))
PY
else
  echo "Quality gate: lint/tests are failing. Fix it and finish again." >&2
  exit 2
fi
exit 0
