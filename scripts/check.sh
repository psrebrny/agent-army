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

# --target-dir <dir> retargets the agent checks at a GENERATED tool dir
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
TOOLS_DIR="$ROOT/.apm/skills/bootstrap/baseline/tools"
TOOL_NAME=""
if [ -n "$TARGET_DIR" ]; then
  BASE="$(cd "$TARGET_DIR" && pwd)"   # agents resolve against the target tool dir
  AGENTS_DIR="$BASE/agents"           # fallback; overridden below once the descriptor is read
else
  AGENTS_DIR="$BASE/core/agents"       # source of truth: baseline/core/agents (assemble.sh materializes it per tool)
fi

# --target-dir → read tools/<tool>.yml (basename of the target dir, e.g. .opencode -> opencode;
# _default.yml if unrecognized) so per-tool assertions (agents dir, hooks_live, settings.json,
# tools: field rule) are driven by the SAME data assemble.sh uses — never re-guessed here.
DESC_AGENTS_SUB=""; DESC_AGENT_SUFFIX=".md"; DESC_HOOKS_SUB=""; DESC_ACCEPTS_TOOLS=""; DESC_SUBAGENTS=""; DESC_HOOK_MECH=""; DESC_HOOKS_LIVE=""
if [ -n "$TARGET_DIR" ] && command -v python3 >/dev/null 2>&1; then
  DIR_BASENAME="$(basename "$BASE")"; DIR_BASENAME="${DIR_BASENAME#.}"
  # Basename-as-tool-name (.opencode -> opencode) holds for most tools, but NOT Copilot
  # (config_root .github, tool name copilot) — so reverse-lookup by dirs.config_root first;
  # basename convention is the fallback for tools that follow it.
  DESC_FILE="$(python3 - "$TOOLS_DIR" "$DIR_BASENAME" <<'PY'
import sys, glob, os, yaml
tools_dir, want = sys.argv[1], sys.argv[2]
for f in sorted(glob.glob(os.path.join(tools_dir, '*.yml'))):
    if os.path.basename(f) == '_default.yml':
        continue
    d = yaml.safe_load(open(f)) or {}
    cr = (d.get('dirs') or {}).get('config_root') or ''
    if os.path.basename(cr).lstrip('.') == want:
        print(f)
        break
PY
)"
  [ -n "$DESC_FILE" ] || DESC_FILE="$TOOLS_DIR/$DIR_BASENAME.yml"
  [ -f "$DESC_FILE" ] || DESC_FILE="$TOOLS_DIR/_default.yml"
  TOOL_NAME="$(basename "$DESC_FILE" .yml)"
  if [ -f "$DESC_FILE" ]; then
    # NOTE: no `eval` here — descriptor values are untrusted-by-construction data (a future
    # feature or a careless PR could put shell metacharacters in a tools/<tool>.yml value).
    # Emit tab-delimited KEY<TAB>VALUE lines and assign via a `case` on the key, so a value can
    # never be interpreted as shell syntax, only ever stored as a plain string.
    while IFS="$(printf '\t')" read -r _k _v; do
      case "$_k" in
        DESC_AGENTS_SUB)    DESC_AGENTS_SUB="$_v" ;;
        DESC_AGENT_SUFFIX)  DESC_AGENT_SUFFIX="$_v" ;;
        DESC_HOOKS_SUB)     DESC_HOOKS_SUB="$_v" ;;
        DESC_ACCEPTS_TOOLS) DESC_ACCEPTS_TOOLS="$_v" ;;
        DESC_SUBAGENTS)     DESC_SUBAGENTS="$_v" ;;
        DESC_HOOK_MECH)     DESC_HOOK_MECH="$_v" ;;
        DESC_HOOKS_LIVE)    DESC_HOOKS_LIVE="$_v" ;;
      esac
    done <<PYOUT
$(python3 - "$DESC_FILE" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
def g(*path):
    v = d
    for k in path:
        v = v.get(k) if isinstance(v, dict) else None
    return v
agents = g('dirs', 'agents') or ''
config_root = g('dirs', 'config_root') or ''
hooks_dir = g('dirs', 'hooks') or ''
def strip_root(p):
    prefix = config_root + '/'
    return p[len(prefix):] if p and config_root and p.startswith(prefix) else p
rows = [
    ("DESC_AGENTS_SUB", strip_root(agents)),
    ("DESC_AGENT_SUFFIX", g('dirs', 'agent_file_suffix') or '.md'),
    ("DESC_HOOKS_SUB", strip_root(hooks_dir)),
    ("DESC_ACCEPTS_TOOLS", 'true' if g('frontmatter', 'accepts_tools_field') else 'false'),
    ("DESC_SUBAGENTS", 'true' if g('capabilities', 'subagents') else 'false'),
    ("DESC_HOOK_MECH", g('capabilities', 'hook_mechanism') or ''),
    ("DESC_HOOKS_LIVE", ','.join(d.get('hooks_live') or [])),
]
for k, v in rows:
    print(f"{k}\t{v}")
PY
)
PYOUT
    [ -n "$DESC_AGENTS_SUB" ] && AGENTS_DIR="$BASE/$DESC_AGENTS_SUB"
  fi
fi

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
  local f="$1" name base fname
  fname="$(basename "$f")"
  base="${fname%"$DESC_AGENT_SUFFIX"}"
  [ "$base" = "$fname" ] && base="$(basename "$f" .md)"   # suffix didn't match (e.g. source mode) — fall back to plain .md
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

  # 2. cross-tool safety: a bare string 'tools:' field is only safe when the tool's
  #    descriptor says accepts_tools_field:true. In target-dir mode we KNOW the tool, so a
  #    violation is a hard FAIL, not a warning; in source/baseline mode (tool unknown) it stays
  #    a WARN since the baseline is deliberately tool-agnostic.
  local has_tools_str=0
  frontmatter "$f" | grep -q '^tools: *[A-Za-z]' && has_tools_str=1
  if [ -n "$DESC_HOOK_MECH" ]; then
    if [ "$has_tools_str" = 1 ] && [ "$DESC_ACCEPTS_TOOLS" != "true" ]; then
      bad "has a string 'tools:' field — tools/$TOOL_NAME.yml says accepts_tools_field:false, this breaks $TOOL_NAME"
    else
      ok "frontmatter 'tools:' rule honored (accepts_tools_field:$DESC_ACCEPTS_TOOLS)"
    fi
  elif [ "$has_tools_str" = 1 ]; then
    warn "has a string 'tools:' field — breaks OpenCode (baseline should omit it; bootstrap re-adds per tool)"
  else ok "no string 'tools:' field (cross-tool safe)"; fi

  # 3. required _STANDARD.md sections (lenient: concept, not exact heading)
  grep -qiE '## .*(Role|Purpose|Objective)' "$f" && ok "Role/Purpose/Objective" || bad "missing Role/Purpose/Objective section"
  grep -qiE 'Principles|Core Principles|Rules' "$f" && ok "Principles/Rules" || bad "missing Principles/Rules"
  grep -qiE '## .*Workflow'              "$f" && ok "Workflow"            || warn "no Workflow section"
  grep -qiE '## .*Output'                "$f" && ok "Output section"      || bad "missing Output section"
  grep -qiE 'Edge cases'                 "$f" && ok "Edge cases"          || warn "no Edge cases section"

  # 4. >=2 prompt examples
  if grep -q '<prompt_examples>' "$f"; then
    local n; n="$(grep -cE '(\*\*EX |^EX [0-9])' "$f")"
    [ "$n" -ge 2 ] && ok "$n prompt examples (>=2)" || bad "only $n prompt example(s) (need >=2)"
  else bad "no <prompt_examples> block"; fi

  # 5. Output section embeds a fenced skeleton (no external template files anymore)
  if awk '
      /^## /   { inout = ($0 ~ /[Oo]utput/) ? 1 : 0 }
      inout && /^```/ { found=1 }
      END { exit(found?0:1) }
    ' "$f"; then ok "Output embeds a fenced skeleton"
  else bad "Output section has no embedded skeleton (fenced block)"; fi

  # 6. (materialized output only) no unresolved path placeholders leaked through /bootstrap
  if [ -n "$TARGET_DIR" ]; then
    if grep -qE '<(SKILLS|AGENTS|TOOL)_DIR>' "$f"; then
      bad "unresolved placeholder(s): $(grep -oE '<(SKILLS|AGENTS|TOOL)_DIR>' "$f" | sort -u | tr '\n' ' ')— /bootstrap must substitute these"
    else ok "no unresolved path placeholders"; fi
  fi
}

check_tools_descriptors() {
  printf '\n\033[1m• tools/*.yml descriptors\033[0m\n'
  command -v python3 >/dev/null 2>&1 || { warn "python3 not available — skipping descriptor schema check"; return; }
  local f name
  for f in "$TOOLS_DIR"/*.yml; do
    name="$(basename "$f")"
    RC="$(python3 - "$f" <<'PY'
import sys, yaml
req = {"dirs", "frontmatter", "capabilities", "hooks_live"}
try:
    d = yaml.safe_load(open(sys.argv[1]))
except Exception as e:
    print(f"PARSE_ERROR {e}")
    sys.exit(0)
missing = req - set((d or {}).keys())
print(f"MISSING {' '.join(sorted(missing))}" if missing else "OK")
PY
)"
    case "$RC" in
      OK) ok "$name: valid YAML, all required keys present" ;;
      PARSE_ERROR*) bad "$name: $RC" ;;
      MISSING*) bad "$name: missing required key(s): ${RC#MISSING }" ;;
    esac
  done
}

check_tool_packaging() {
  [ -n "$DESC_HOOK_MECH" ] || return   # only meaningful in target-dir mode with a resolved descriptor
  printf '\n\033[1m• tool packaging: %s\033[0m\n' "$TOOL_NAME"

  local hooks_dir="$BASE"
  [ -n "$DESC_HOOKS_SUB" ] && hooks_dir="$BASE/$DESC_HOOKS_SUB"
  local IFS=','; local live=($DESC_HOOKS_LIVE); unset IFS
  local all_hooks=(guard.sh format.sh gate.sh verify.sh detect.sh git-pre-commit.sh) h l want
  for h in "${all_hooks[@]}"; do
    want=0
    for l in "${live[@]}"; do [ "$l" = "$h" ] && want=1; done
    if [ "$want" = 1 ]; then
      [ -f "$hooks_dir/$h" ] && ok "hook present (expected): $h" || bad "hook MISSING (descriptor expects it): $h"
    else
      [ -f "$hooks_dir/$h" ] && bad "inert hook present (descriptor does NOT list it as live): $h" || ok "inert hook correctly ABSENT: $h"
    fi
  done

  local settings="$BASE/settings.json"
  if [ "$DESC_HOOK_MECH" = "claude-settings" ]; then
    [ -f "$settings" ] && ok "settings.json present (hook_mechanism=claude-settings)" || bad "settings.json MISSING (hook_mechanism=claude-settings)"
  else
    [ -f "$settings" ] && bad "settings.json present but hook_mechanism=$DESC_HOOK_MECH (should be absent — hooks are inert)" || ok "settings.json correctly absent (hook_mechanism=$DESC_HOOK_MECH)"
  fi

  if [ "$DESC_SUBAGENTS" != "true" ]; then
    if [ -d "$AGENTS_DIR" ] && ls "$AGENTS_DIR"/*.md >/dev/null 2>&1; then
      bad "capabilities.subagents=false but agent files exist at $AGENTS_DIR"
    else
      ok "capabilities.subagents=false and no agent files materialized (AGENTS.md + git/CI degrade honored)"
    fi
  fi
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

if [ "$do_agents" = 1 ] && [ -d "$AGENTS_DIR" ] && ls "$AGENTS_DIR"/*.md >/dev/null 2>&1; then
  for f in "$AGENTS_DIR"/*.md; do
    [ "$(basename "$f")" = "_STANDARD.md" ] && continue
    match "$(basename "$f" .md)" && check_agent "$f"
  done
fi
check_tool_packaging
# In materialized output, _STANDARD.md and the repo AGENTS.md also carry placeholders — verify they resolved.
if [ -n "$TARGET_DIR" ]; then
  printf '\n\033[1m• materialized placeholders\033[0m\n'
  for extra in "$BASE/_STANDARD.md" "$BASE/../AGENTS.md"; do
    [ -f "$extra" ] || continue
    if grep -qE '<(SKILLS|AGENTS|TOOL)_DIR>' "$extra"; then
      bad "unresolved placeholder in $(basename "$extra"): $(grep -oE '<(SKILLS|AGENTS|TOOL)_DIR>' "$extra" | sort -u | tr '\n' ' ')"
    else ok "$(basename "$extra"): placeholders resolved"; fi
  done
fi
if [ "$do_skills" = 1 ] && [ -z "$TARGET_DIR" ]; then
  for d in "$SKILLS_DIR"/*/; do check_skill "${d%/}"; done
  check_tools_descriptors
fi
if [ "$do_pack" = 1 ]; then
  printf '\n\033[1m• package (apm)\033[0m\n'
  if command -v apm >/dev/null 2>&1; then
    (cd "$ROOT" && apm pack >/dev/null 2>&1) && ok "apm pack succeeded" || bad "apm pack failed (run 'apm pack' to see why)"
  else warn "apm not installed — skipping pack/dry-run"; fi
fi

printf '\n\033[1m%d passed, %d failed, %d warnings\033[0m\n' "$PASS" "$FAIL" "$WARN"
[ "$FAIL" -eq 0 ]
