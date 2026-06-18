#!/usr/bin/env bash
# PreToolUse: twarda bariera. Blokuje edycję sekretów i niebezpieczne komendy.
# Protokół Claude Code: deny = JSON na stdout + exit 2.
input="$(cat)"

if ! command -v python3 >/dev/null 2>&1; then
  # Fallback bez python3: zgrubna, ale FAIL-CLOSED ochrona najgroźniejszych wzorców.
  low="$(printf '%s' "$input" | tr 'A-Z' 'a-z')"
  if printf '%s' "$low" | grep -Eq 'rm[[:space:]]+-rf[[:space:]]+(/|~|\*)|\bmkfs\b|\bdd[[:space:]]+if=|chmod[[:space:]]+-r[[:space:]]+777[[:space:]]+/|\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|push[^"]*--force'; then
    echo "Bariera (fallback): potencjalnie niebezpieczna operacja zablokowana." >&2; exit 2
  fi
  if printf '%s' "$input" | grep -Eq '"(file_path|path)"[[:space:]]*:[[:space:]]*"[^"]*(\.env|\.pem|\.key|id_rsa|/\.git/)'; then
    echo "Bariera (fallback): edycja chronionego pliku zablokowana." >&2; exit 2
  fi
  exit 0
fi

CC_HOOK_INPUT="$input" python3 - <<'PY'
import os, sys, json, re
try:
    d = json.loads(os.environ.get("CC_HOOK_INPUT", ""))
except Exception:
    sys.exit(0)
tool = d.get("tool_name", "")
ti   = d.get("tool_input") or d.get("inputs") or {}
path = ti.get("file_path") or ti.get("path") or ""
cmd  = ti.get("command", "")

def deny(msg):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", "permissionDecision": "deny",
        "additionalContext": msg}}))
    sys.stderr.write(msg + "\n")
    sys.exit(2)

PROTECTED = re.compile(r'(^|/)(\.env(\.|$)|.*\.pem$|.*\.key$|id_rsa|secrets?\.|\.git/)', re.I)
if tool in ("Edit", "Write", "MultiEdit") and path and PROTECTED.search(path):
    deny("Bariera: edycja chronionego pliku zablokowana -> %s" % path)

DANGER = [r'rm\s+-rf\s+(/|~|\*)', r':\(\)\s*\{', r'\bmkfs\b', r'\bdd\s+if=',
          r'>\s*/dev/sd', r'chmod\s+-R\s+777\s+/',
          r'curl[^|]*\|\s*(sudo\s+)?(ba)?sh', r'git\s+push\s+.*--force\b']
if tool == "Bash" and cmd:
    for p in DANGER:
        if re.search(p, cmd):
            deny("Bariera: niebezpieczna komenda zablokowana -> %s" % cmd)
sys.exit(0)
PY
