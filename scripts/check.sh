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
V2_TARGET=0
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
  if [ -f "$BASE/.agent-army/config.json" ]; then
    V2_TARGET=1
    AGENTS_DIR="$BASE/.apm/agents"
  fi
else
  AGENTS_DIR="$BASE/core/agents"       # source of truth: baseline/core/agents (assemble.sh materializes it per tool)
fi

# --target-dir → read tools/<tool>.yml (basename of the target dir, e.g. .opencode -> opencode;
# _default.yml if unrecognized) so per-tool assertions (agents dir, hooks_live, settings.json,
# tools: field rule) are driven by the SAME data assemble.sh uses — never re-guessed here.
DESC_AGENTS_SUB=""; DESC_AGENT_SUFFIX=".md"; DESC_HOOKS_SUB=""; DESC_ACCEPTS_TOOLS=""; DESC_SUBAGENTS=""; DESC_HOOK_MECH=""; DESC_HOOKS_LIVE=""
if [ -n "$TARGET_DIR" ] && [ "$V2_TARGET" = 0 ] && command -v python3 >/dev/null 2>&1; then
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

  # 1. frontmatter parses + has name/description; model is optional and target-routed when present
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
  [ -n "$(yaml_key "$f" model)" ] && ok "has target-routed or user-selected 'model:' field" || ok "model inherits tool/session configuration"

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

  # 6. every report/artifact has the common handoff contract. It gives the
  # orchestrator a stable, compact surface even though the body of each role's
  # report remains role-specific.
  if grep -q '^## Handoff' "$f"; then
    local handoff_missing="" field
    for field in STATUS VERIFIED ASSUMPTIONS OUT_OF_SCOPE OPEN_QUESTIONS; do
      grep -q "\*\*$field:\*\*" "$f" || handoff_missing="$handoff_missing $field"
    done
    [ -z "$handoff_missing" ] && ok "Handoff has all required fields" || bad "Handoff missing:$handoff_missing"
  else
    bad "missing Handoff section"
  fi

  # 7. workflow guarantees have one owning agent each. Validate
  # them in source and materialized profiles so specialization cannot turn
  # them back into optional prose.
  if [ "$name" = "architect" ]; then
    if grep -q 'Delegation Contract' "$f" \
      && grep -q 'approved read/write paths' "$f" \
      && grep -q 'STOP and return `awaiting_approval`' "$f" \
      && grep -q '## Execution State' "$f" \
      && grep -q '\*\*Execution Profile:\*\*' "$f" \
      && grep -q '\*\*Run Configuration:\*\*' "$f" \
      && grep -q 'ready_for_human_review' "$f"; then
      ok "Delegation Contract is explicit"
    else
      bad "architect missing explicit contract/execution-state rules"
    fi
  fi
  if [ "$name" = "code-reviewer" ]; then
    if grep -q 'FRESH-EYES ISOLATION' "$f" \
      && grep -q 'Do not open or accept implementation/tester reports' "$f" \
      && grep -q 'Diff-Only Review' "$f"; then
      ok "reviewer clean-packet isolation is explicit"
    else
      bad "reviewer missing clean-packet isolation"
    fi
  fi

  # 8. (materialized output only) no unresolved path placeholders leaked through /bootstrap
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
req = {"dirs", "frontmatter", "capabilities", "model_control", "hooks_live"}
try:
    d = yaml.safe_load(open(sys.argv[1]))
except Exception as e:
    print(f"PARSE_ERROR {e}")
    sys.exit(0)
missing = req - set((d or {}).keys())
if missing:
    print(f"MISSING {' '.join(sorted(missing))}")
    sys.exit(0)
mc = d.get("model_control") or {}
need_mc = {"main_session", "subagent_model", "subagent_effort"}
missing_mc = need_mc - set(mc)
if missing_mc:
    print(f"MODEL_CONTROL_MISSING {' '.join(sorted(missing_mc))}")
    sys.exit(0)
allowed = {"per_spawn", "per_role_static", "inherit", "unsupported"}
invalid = {k: v for k, v in mc.items() if k in need_mc and v not in allowed}
print(f"MODEL_CONTROL_INVALID {invalid}" if invalid else "OK")
PY
)"
    case "$RC" in
      OK) ok "$name: valid YAML, all required keys present" ;;
      PARSE_ERROR*) bad "$name: $RC" ;;
      MISSING*) bad "$name: missing required key(s): ${RC#MISSING }" ;;
      MODEL_CONTROL_MISSING*) bad "$name: missing model_control key(s): ${RC#MODEL_CONTROL_MISSING }" ;;
      MODEL_CONTROL_INVALID*) bad "$name: invalid model_control value(s): ${RC#MODEL_CONTROL_INVALID }" ;;
    esac
  done
}

check_tool_packaging() {
  [ "$V2_TARGET" = 1 ] && return
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

check_v2_profile() {
  [ "$V2_TARGET" = 1 ] || return
  printf '\n\033[1m• v0.3 profile\033[0m\n'
  [ -f "$BASE/.agent-army/config.json" ] && ok "config.json present" || return
  python3 - "$BASE" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
try:
    c = json.loads((root / '.agent-army/config.json').read_text())
    assert c.get('version') == 2
    for layer in ('runtime_hooks', 'git_precommit', 'ci'):
        assert c['enforcement'][layer]['mode'] in {'army','external','disabled','blocked'}
    for job in c.get('quality', {}).values():
        if job is not None:
            assert isinstance(job.get('cwd'), str) and isinstance(job.get('argv'), list)
except Exception as e:
    print(e)
    sys.exit(1)
PY
  [ $? -eq 0 ] && ok "config ownership + structured commands valid" || bad "invalid v0.3 config"
  if grep -q '"mode": "army"' "$BASE/.agent-army/config.json"; then
    [ -f "$BASE/.agent-army/runtime.py" ] && ok "runtime.py present for owned control" || bad "runtime.py missing for owned control"
  else
    [ ! -f "$BASE/.agent-army/runtime.py" ] && ok "no runtime installed when all controls are non-Army" || ok "runtime present without owned control"
  fi
  local role
  for role in architect coder tester code-reviewer security-auditor perf-auditor docs-writer; do
    if grep -q '"target": "windsurf"' "$BASE/.agent-army/config.json"; then
      [ -f "$BASE/.windsurf/skills/agent-army-$role/SKILL.md" ] && ok "fallback role: $role" || bad "fallback role missing: $role"
    elif grep -q '"target": "gemini"' "$BASE/.agent-army/config.json"; then
      [ -f "$BASE/.gemini/agents/agent-army-$role.md" ] && ok "Gemini adapter role: $role" || bad "Gemini adapter role missing: $role"
    else
      ls "$AGENTS_DIR"/agent-army-"$role".agent.md >/dev/null 2>&1 && ok "generated source role: $role" || bad "generated source role missing: $role"
    fi
  done
}

check_v2_source() {
  [ -z "$TARGET_DIR" ] || return
  printf '\n\033[1m• v0.3 generator safety\033[0m\n'
  if python3 - "$ROOT/.apm/skills/bootstrap/bootstrap.py" "$BASE/runtime.py" <<'PY'
import sys
for path in sys.argv[1:]:
    compile(open(path, encoding='utf-8').read(), path, 'exec')
PY
  then ok "bootstrap/runtime Python compiles"; else bad "bootstrap/runtime Python does not compile"; fi
  if rg -n '(^|[^[:alnum:]_])(source|eval)[[:space:]]' "$BASE/hooks" "$BASE/runtime.py" >/dev/null; then
    bad "runtime contains shell source/eval"
  else
    ok "runtime contains no shell source/eval"
  fi
  if rg -n '^\.apm/(agents|hooks)/' "$ROOT/.gitignore" >/dev/null 2>&1; then
    bad "source repo must not ship active local APM agents/hooks"
  else
    ok "source repo ships no active local APM agents/hooks"
  fi
}

check_skill() {
  local d="$1" f="$d/SKILL.md" base; base="$(basename "$d")"
  printf '\n\033[1m• skill: %s\033[0m\n' "$base"
  [ -f "$f" ] && ok "SKILL.md present" || { bad "no SKILL.md"; return; }
  [ -n "$(yaml_key "$f" name)" ] && ok "has name" || bad "missing 'name:'"
  [ -n "$(yaml_key "$f" description)" ] && ok "has description" || bad "missing 'description:'"
  if [ "$base" = "ship" ]; then
    if grep -q 'RESOLVE THE EXECUTION SCOPE' "$f" \
      && grep -q 'no argument → resume the single unfinished task or PR only when exactly one exists' "$f" \
      && grep -q 'MODEL & EFFORT ROUTING' "$f" \
      && grep -q 'MANDATORY BLUEPRINT + ROUTING + SCOPE GATE' "$f" \
      && grep -q 'SCOPE-AWARE ROUTING' "$f" \
      && grep -q 'Per-role static routing' "$f" \
      && grep -q 'Inherit fallback' "$f" \
      && grep -q 'Autonomous' "$f" \
      && grep -q 'Interactive' "$f" \
      && grep -q 'INTERACTION CARD' "$f" \
      && grep -q 'Interaction policy: supervised' "$f" \
      && grep -q 'migrated to interactive' "$f" \
      && grep -q 'RED acceptance' "$f" \
      && grep -q 'task-review Interaction Card' "$f" \
      && grep -q 'contract interpretation, exact RED tests, smallest implementation' "$f" \
      && grep -q 'focused diff summary, GREEN' "$f" \
      && grep -q 'PERSIST EVERY ROLE TRANSITION' "$f" \
      && grep -q 'switch and continue | stay current' "$f" \
      && grep -q 'then re-run both review' "$f" \
      && grep -q 'verdict directly to coder' "$f" \
      && grep -q 'Final review is a pause in both modes' "$f" \
      && grep -q 'ready_for_human_review' "$f" \
      && grep -q 'Never change a' "$f" \
      && grep -q 'UI/CLI/API model' "$f"; then
      ok "ship interaction modes, routing and closure loop are explicit"
    else
      bad "ship missing resolve, routing or closure-loop rule"
    fi
  fi
  if [ "$base" = "adapt-army" ]; then
    if grep -q 'Army Improvement Proposal' "$f" \
      && grep -q 'state.json' "$f" \
      && grep -q 'overrides/skills' "$f" \
      && grep -q '/new-skill' "$f" \
      && grep -q 'Never silently mutate' "$f"; then
      ok "adapt-army feedback routing and approval boundary are explicit"
    else
      bad "adapt-army missing feedback routing or approval rule"
    fi
  fi
  if [ "$base" = "new-skill" ]; then
    if grep -q '\.apm/skills/<name>/SKILL.md' "$f" \
      && grep -q 'apm install --frozen' "$f" \
      && grep -q 'must not weaken' "$f" \
      && grep -q '## New Skill Result' "$f"; then
      ok "new-skill owns a local source, render and safety contract"
    else
      bad "new-skill missing source, render or safety contract"
    fi
  fi
  if [ "$base" = "bootstrap" ]; then
    if grep -q 'Update detection' "$f" \
      && grep -q -- '--mode auto --dry-run' "$f" \
      && grep -q 'incremental migration' "$f" \
      && grep -q 'feedback-router block' "$f"; then
      ok "bootstrap incremental-update contract is explicit"
    else
      bad "bootstrap missing incremental-update contract"
    fi
  fi
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
check_v2_profile
check_v2_source
# In materialized output, _STANDARD.md and the repo AGENTS.md also carry placeholders — verify they resolved.
if [ -n "$TARGET_DIR" ]; then
  printf '\n\033[1m• materialized placeholders\033[0m\n'
  for extra in "$BASE/_STANDARD.md" "$BASE/../AGENTS.md" "$BASE/../CLAUDE.md"; do
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
