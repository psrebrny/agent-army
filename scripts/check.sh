#!/usr/bin/env bash
# check.sh — "unit tests" for the Agent Army package. Deterministic, zero-LLM.
# Validate ONE piece or everything:
#   scripts/check.sh                 # all agents + all skills + package
#   scripts/check.sh architect       # just the architect agent
#   scripts/check.sh tester reviewer # several agents (substring match on name)
#   scripts/check.sh --skills        # just the skills
#   scripts/check.sh --pack          # also run `apm pack`/dry-run if apm is installed
#   scripts/check.sh --target-dir <tooldir>   # validate GENERATED agents (e.g. a target
#                                              # repo's .claude after /bootstrap), not the baseline
#
# Exit non-zero if any FAIL. Warnings (⚠) don't fail the run.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/.apm/skills/bootstrap/baseline"
SKILLS_DIR="$ROOT/.apm/skills"

# --target-dir <dir> retargets the agent + template checks at a GENERATED tool dir
# (e.g. <repo>/.claude). Default: validate the source baseline. Parsed early so the
# rest of the script just reads BASE/AGENTS_DIR.
TARGET_DIR=""
_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --target-dir) TARGET_DIR="${2:?--target-dir needs a path}"; shift 2 ;;
    *) _args+=("$1"); shift ;;
  esac
done
set -- ${_args[@]+"${_args[@]}"}
if [ -n "$TARGET_DIR" ]; then
  BASE="$(cd "$TARGET_DIR" && pwd)"   # templates resolve against the target tool dir
fi
AGENTS_DIR="$BASE/agents"
TEMPLATES_DIR="$BASE/templates"

PASS=0; FAIL=0; WARN=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '  \033[31m✗ %s\033[0m\n' "$1"; FAIL=$((FAIL+1)); }
warn(){ printf '  \033[33m⚠ %s\033[0m\n' "$1"; WARN=$((WARN+1)); }

# --- frontmatter helpers (python3 for real YAML; bash fallback) -------------
frontmatter() { # prints the YAML between the first two --- lines
  awk 'NR==1&&$0!="---"{exit} NR==1{next} $0=="---"{exit} {print}' "$1"
}
yaml_key() { # yaml_key <file> <key>  -> value or empty
  frontmatter "$1" | awk -v k="$2" -F': *' '$1==k{sub(/^[^:]*: */,""); print; exit}'
}

check_agent() {
  local f="$1" name base
  base="$(basename "$f" .md)"
  printf '\n\033[1m• agent: %s\033[0m\n' "$base"

  # 1. frontmatter parses + has name/description/model
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$f" <<'PY' >/dev/null 2>&1 && ok "frontmatter is valid YAML" || bad "frontmatter is NOT valid YAML"
import sys,yaml
t=open(sys.argv[1]).read().split('---',2)
yaml.safe_load(t[1])
PY
  fi
  name="$(yaml_key "$f" name)"
  [ -n "$name" ] && ok "has name: $name" || bad "missing 'name:' in frontmatter"
  [ "$name" = "$base" ] || warn "name ('$name') != filename ('$base')"
  [ -n "$(yaml_key "$f" description)" ] && ok "has description" || bad "missing 'description:'"
  [ -n "$(yaml_key "$f" model)" ] && ok "has model tier" || warn "no 'model:' field"

  # 2. cross-tool safety: a bare string 'tools:' breaks OpenCode
  if frontmatter "$f" | grep -q '^tools: *[A-Za-z]'; then
    warn "has a string 'tools:' field — breaks OpenCode (baseline should omit it; bootstrap re-adds per tool)"
  else ok "no string 'tools:' field (cross-tool safe)"; fi

  # 3. required _STANDARD.md sections (lenient: concept, not exact heading)
  grep -qiE '## .*(Role|Purpose|Objective)' "$f" && ok "Role/Purpose/Objective" || bad "missing Role/Purpose/Objective section"
  grep -qiE 'Principles|Core Principles|Rules' "$f" && ok "Principles/Rules" || bad "missing Principles/Rules"
  grep -qiE '## .*Workflow'              "$f" && ok "Workflow"            || warn "no Workflow section"
  grep -qiE '## .*Output'                "$f" && ok "Output→template"     || bad "missing Output section"
  grep -qiE 'Edge cases'                 "$f" && ok "Edge cases"          || warn "no Edge cases section"

  # 4. >=2 prompt examples
  if grep -q '<prompt_examples>' "$f"; then
    local n; n="$(grep -cE '(\*\*EX |^EX [0-9])' "$f")"
    [ "$n" -ge 2 ] && ok "$n prompt examples (>=2)" || bad "only $n prompt example(s) (need >=2)"
  else bad "no <prompt_examples> block"; fi

  # 5. Output template reference resolves to a real file
  local tmpl
  tmpl="$(grep -oE '[A-Za-z0-9_./-]*templates/[A-Za-z0-9_./-]+\.template\.md' "$f" | head -1)"
  if [ -n "$tmpl" ]; then
    local leaf="templates/${tmpl#*templates/}"
    if [ -f "$BASE/$leaf" ]; then ok "template link resolves ($leaf)"
    else bad "template link BROKEN: $tmpl (no $BASE/$leaf)"; fi
  else warn "no template link found in Output"; fi
}

check_skill() {
  local d="$1" f="$d/SKILL.md" base; base="$(basename "$d")"
  printf '\n\033[1m• skill: %s\033[0m\n' "$base"
  [ -f "$f" ] && ok "SKILL.md present" || { bad "no SKILL.md"; return; }
  [ -n "$(yaml_key "$f" name)" ] && ok "has name" || bad "missing 'name:'"
  [ -n "$(yaml_key "$f" description)" ] && ok "has description" || bad "missing 'description:'"
}

# --- argument routing -------------------------------------------------------
do_agents=1; do_skills=1; do_pack=0; filters=()
for a in "$@"; do
  case "$a" in
    --skills) do_agents=0 ;;
    --agents) do_skills=0 ;;
    --pack)   do_pack=1 ;;
    -*)       echo "unknown flag: $a"; exit 2 ;;
    *)        filters+=("$a"); do_skills=0 ;;   # a name → focus agents (piece by piece)
  esac
done

match() { # match <name>  against filters (empty filters = all)
  [ ${#filters[@]} -eq 0 ] && return 0
  for x in "${filters[@]}"; do [[ "$1" == *"$x"* ]] && return 0; done
  return 1
}

if [ "$do_agents" = 1 ]; then
  for f in "$AGENTS_DIR"/*.md; do
    [ "$(basename "$f")" = "_STANDARD.md" ] && continue
    match "$(basename "$f" .md)" && check_agent "$f"
  done
fi
if [ "$do_skills" = 1 ] && [ -z "$TARGET_DIR" ]; then
  for d in "$SKILLS_DIR"/*/; do check_skill "${d%/}"; done
fi
if [ "$do_pack" = 1 ]; then
  printf '\n\033[1m• package (apm)\033[0m\n'
  if command -v apm >/dev/null 2>&1; then
    (cd "$ROOT" && apm pack >/dev/null 2>&1) && ok "apm pack succeeded" || bad "apm pack failed (run 'apm pack' to see why)"
  else warn "apm not installed — skipping pack/dry-run"; fi
fi

printf '\n\033[1m%d passed, %d failed, %d warnings\033[0m\n' "$PASS" "$FAIL" "$WARN"
[ "$FAIL" -eq 0 ]
