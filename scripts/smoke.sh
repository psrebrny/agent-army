#!/usr/bin/env bash
# Deterministic v0.5 smoke tests. One tool-neutral profile in .agent-army serves every tool:
# no target, no native agent copies; skills locate the profile with army.py.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEN="$ROOT/.apm/skills/bootstrap/bootstrap.py"
ARMY="$ROOT/.apm/skills/bootstrap/army.py"
PASS=0; FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-army-v3.XXXXXX")"
cleanup(){ [ -n "${KEEP_WORK:-}" ] && echo "kept $WORK" || rm -rf "$WORK"; }
trap cleanup EXIT
init_repo(){
  local dir="$1"
  mkdir -p "$dir"
  (cd "$dir" && git init -q && git config user.email smoke@example.test && git config user.name smoke)
}
bootstrap(){
  local dir="$1"; shift
  (cd "$dir" && python3 "$GEN" --skip-apm "$@")
}
quiet_bootstrap(){ bootstrap "$@" --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null; }
# json <file> <python expression over `d`> — exit 0 when the expression is truthy.
json(){ python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if eval(sys.argv[2]) else 1)' "$1" "$2"; }
locate(){ local dir="$1"; shift; (cd "$dir" && python3 "$ARMY" locate "$@"); }
legacy_profile(){
  python3 -c 'import json, pathlib, sys; p=pathlib.Path(sys.argv[1]); data=json.loads(p.read_text()); data.pop("package", None); p.write_text(json.dumps(data, indent=2) + "\n")' "$1"
}
prepare_planning_role_upgrade(){
  local dir="$1" keep_files="${2:-no}"
  python3 - "$dir" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
path = root / '.agent-army/config.json'
data = json.loads(path.read_text())
data['package']['version'] = '0.4.0'
for role in ('planning-analyst', 'plan-reviewer'):
    data.get('model_routing', {}).get('roles', {}).pop(role, None)
    data.get('package', {}).get('inventory', {}).get('templates', {}).pop(
        f'bootstrap/baseline/core/agents/{role}.md', None
    )
path.write_text(json.dumps(data, indent=2) + '\n')
PY
  if [ "$keep_files" != yes ]; then
    rm -f "$dir/.agent-army/agents/agent-army-planning-analyst.agent" \
      "$dir/.agent-army/agents/agent-army-plan-reviewer.agent"
  fi
}
NATIVE_DIRS=".claude/agents .codex/agents .cursor/agents .github/agents .gemini/agents .opencode/agents .windsurf/skills .apm/agents"
no_native_agents(){
  local dir="$1" d
  for d in $NATIVE_DIRS; do
    find "$dir/$d" -name 'agent-army-*' -print -quit 2>/dev/null | grep -q . && return 1
  done
  return 0
}

printf '\n\033[1mGATE 0 · one profile, no target\033[0m\n'
GEN0="$WORK/generate"; init_repo "$GEN0"
quiet_bootstrap "$GEN0"
count="$(find "$GEN0/.agent-army/agents" -name 'agent-army-*.agent' | wc -l | tr -d ' ')"
[ "$count" = 9 ] && ok "nine canonical role contracts" || bad "expected nine role contracts, got $count"
no_native_agents "$GEN0" && ok "no native agent copy in any tool dir" || bad "a native agent copy was rendered"
grep -l '^model:' "$GEN0"/.agent-army/agents/*.agent >/dev/null 2>&1 && bad "a contract carries a model line" || ok "contracts carry no tool-specific model line"
json "$GEN0/.agent-army/config.json" '"target" not in d and d["version"] == 3 and d["visibility"] == "committed"' \
  && ok "profile schema v3 has no target and records visibility" || bad "profile still bound to a target or missing visibility"
json "$GEN0/.agent-army/config.json" 'd["model_routing"]["tools"] == {"claude": {"light": "haiku", "mid": "sonnet", "strong": "opus"}}' \
  && ok "claude tiers recorded per tool by default" || bad "default per-tool model routing missing"
json "$GEN0/.agent-army/config.json" 'd["model_routing"]["roles"]["planning-analyst"] == "mid" and d["model_routing"]["roles"]["plan-reviewer"] == "strong"' \
  && ok "planning roles have the selected capability tiers" || bad "planning-role capability tiers are wrong"
grep -q '## Task Roadmap' "$GEN0/.agent-army/agents/agent-army-architect.agent" && grep -q '## For you' "$GEN0/.agent-army/agents/agent-army-architect.agent" && grep -q 'Temporary delegation' "$GEN0/.agent-army/agents/agent-army-architect.agent" \
  && ok "resumable interactive contract present" || bad "interactive contract missing"
grep -qx '.agent-army/state.json' "$GEN0/.gitignore" && ! grep -qx '.agent-army/' "$GEN0/.gitignore" \
  && ok "committed visibility ignores only state.json" || bad "committed visibility wrote the wrong ignore entries"
grep -q 'agent-army:feedback-router:start' "$GEN0/AGENTS.md" && grep -q 'army.py locate' "$GEN0/AGENTS.md" \
  && ok "feedback router points skills at the one profile" || bad "feedback router missing or stale"
(cd "$GEN0" && python3 "$GEN" --skip-apm) | grep -q 'profile is current' && ok "rerun is a no-op" || bad "rerun was not a no-op"
(cd "$GEN0" && python3 "$GEN" codex --skip-apm) | grep -q 'profile is current' \
  && ok "another tool uses the same profile without re-bootstrap" || bad "another tool forced a re-bootstrap"

printf '\n\033[1mGATE 0.5 · skills locate the profile (army.py)\033[0m\n'
mkdir -p "$GEN0/src/deep"
OUT="$WORK/locate.json"; locate "$GEN0/src/deep" --tool claude > "$OUT"
json "$OUT" 'd["repo_root"].endswith("/generate") and d["profile"] == "specialized"' \
  && ok "locate from a subdirectory finds the repo root and its profile" || bad "locate missed the repo root or profile"
json "$OUT" 'd["dispatch"] == "subagent-with-prompt" and d["roles"]["tester"]["model"] == "haiku" and d["roles"]["architect"]["model"] == "opus"' \
  && ok "claude: subagent dispatch with per-role models" || bad "claude dispatch or models wrong"
json "$OUT" 'd["roles"]["tester"]["contract_path"].endswith(".agent-army/agents/agent-army-tester.agent")' \
  && ok "roles resolve to the repo's contracts" || bad "role contract path wrong"
locate "$GEN0" --tool codex > "$OUT"
json "$OUT" 'd["dispatch"] == "main-thread" and d["roles"]["tester"]["model"] is None' \
  && ok "codex: main-thread dispatch inherits the session model" || bad "codex dispatch or model wrong"
(cd "$GEN0" && python3 "$ARMY" role tester) | grep -q '<AGENTS_DIR>\|<TOOL_DIR>' && bad "role output kept placeholders" || ok "role output has placeholders resolved"
sed -i.bak '3i\
model: user-owned/custom-model' "$GEN0/.agent-army/agents/agent-army-architect.agent"; rm -f "$GEN0/.agent-army/agents/agent-army-architect.agent.bak"
cp "$GEN0/.agent-army/agents/agent-army-tester.agent" "$GEN0/.agent-army/agents/agent-army-data-steward.agent"
locate "$GEN0" --tool claude > "$OUT"
json "$OUT" 'd["roles"]["architect"]["model"] == "user-owned/custom-model" and d["roles"]["architect"]["model_source"] == "user-override"' \
  && ok "a user's model line overrides the profile tiers" || bad "user model override ignored"
json "$OUT" '"data-steward" in d["roles"]' && ok "a role added with /new-agent is located without rendering" || bad "custom role not located"
(cd "$GEN0" && python3 "$GEN" --skip-apm --mode full --runtime-hooks disabled >/dev/null)
grep -q '^model: user-owned/custom-model$' "$GEN0/.agent-army/agents/agent-army-architect.agent" \
  && ok "re-bootstrap preserves a user-owned model line" || bad "re-bootstrap removed a user-owned model line"
NOPROF="$WORK/no-profile"; init_repo "$NOPROF"
locate "$NOPROF" --tool claude > "$OUT"
json "$OUT" 'd["profile"] == "baseline" and d["bootstrap"].endswith("bootstrap/SKILL.md") and "/baseline/core/agents/" in d["roles"]["tester"]["contract_path"]' \
  && ok "no profile: baseline roles from the package and a /bootstrap pointer" || bad "no-profile fallback wrong"
[ ! -e "$NOPROF/.agent-army" ] && ok "locate never writes" || bad "locate created .agent-army"

printf '\n\033[1mGATE 1 · ownership and non-clobbering\033[0m\n'
OWN="$WORK/ownership"; init_repo "$OWN"
mkdir -p "$OWN/.github/workflows"; printf 'name: user-ci\n' > "$OWN/.github/workflows/user.yml"
mkdir -p "$OWN/.git/hooks"; printf '#!/usr/bin/env node\n' > "$OWN/.git/hooks/pre-commit"; chmod +x "$OWN/.git/hooks/pre-commit"
bootstrap "$OWN" --runtime-hooks external --git-precommit external --ci external >/dev/null
grep -q 'env node' "$OWN/.git/hooks/pre-commit" && ok "external pre-commit preserved" || bad "external pre-commit changed"
[ ! -f "$OWN/.github/workflows/agent-army-quality.yml" ] && ok "external CI preserved" || bad "external CI unexpectedly installed"
grep -q '"mode": "external"' "$OWN/.agent-army/config.json" && ok "external ownership recorded" || bad "external ownership not recorded"
printf '\nSMOKE-SPECIALIZATION\n' >> "$OWN/.agent-army/agents/agent-army-architect.agent"
bootstrap "$OWN" --mode full >/dev/null
grep -q 'SMOKE-SPECIALIZATION' "$OWN/.agent-army/agents/agent-army-architect.agent" && ok "re-bootstrap preserves specialized agent source" || bad "re-bootstrap overwrote specialized agent source"
grep -q '"mode": "external"' "$OWN/.agent-army/config.json" && ok "re-bootstrap preserves ownership choice" || bad "re-bootstrap changed ownership choice"

BLOCK="$WORK/blocked"; init_repo "$BLOCK"
mkdir -p "$BLOCK/.git/hooks"; printf '#!/usr/bin/env node\n' > "$BLOCK/.git/hooks/pre-commit"; chmod +x "$BLOCK/.git/hooks/pre-commit"
bootstrap "$BLOCK" --runtime-hooks disabled --git-precommit army --ci disabled >/dev/null
json "$BLOCK/.agent-army/config.json" 'd["enforcement"]["git_precommit"]["mode"] == "blocked"' && ok "unsafe hook replacement blocked" || bad "unsafe hook replacement was not blocked"

printf '\n\033[1mGATE 1.2 · where the profile lives in git\033[0m\n'
EXC="$WORK/visibility-exclude"; init_repo "$EXC"
quiet_bootstrap "$EXC" --visibility exclude
grep -qx '.agent-army/' "$EXC/.git/info/exclude" && ok "exclude: .agent-army/ in .git/info/exclude" || bad "exclude entry missing"
[ ! -f "$EXC/.gitignore" ] && ok "exclude: the repo's .gitignore is untouched" || bad "exclude wrote .gitignore"
(cd "$EXC" && git status --porcelain) | grep -q '.agent-army' && bad "exclude: profile still visible to git" || ok "exclude: profile invisible to git"
IGN="$WORK/visibility-gitignore"; init_repo "$IGN"
bootstrap "$IGN" --visibility gitignore --runtime-hooks disabled --git-precommit disabled --ci army >/dev/null
grep -qx '.agent-army/' "$IGN/.gitignore" && ok "gitignore: .agent-army/ in .gitignore" || bad "gitignore entry missing"
json "$IGN/.agent-army/config.json" 'd["enforcement"]["ci"]["mode"] == "blocked"' && [ ! -f "$IGN/.github/workflows/agent-army-quality.yml" ] \
  && ok "owned CI is blocked when the profile is not committed" || bad "owned CI installed for an uncommitted profile"
bootstrap "$IGN" >/dev/null
json "$IGN/.agent-army/config.json" 'd["visibility"] == "gitignore"' && ok "visibility choice preserved on rerun" || bad "visibility choice lost"

printf '\n\033[1mGATE 1.3 · per-tool model routing\033[0m\n'
MOD="$WORK/models"; init_repo "$MOD"
if quiet_bootstrap "$MOD" --model-light a --model-mid b --model-strong c 2>/dev/null; then bad "model IDs without --tool accepted"; else ok "model IDs need --tool"; fi
if quiet_bootstrap "$MOD" --tool codex --model-light a --model-mid b --model-strong c 2>/dev/null; then bad "model IDs accepted for a main-thread tool"; else ok "main-thread tool refuses per-role model IDs"; fi
quiet_bootstrap "$MOD" --tool claude --model-light test/light --model-mid test/mid --model-strong test/strong
json "$MOD/.agent-army/config.json" 'd["model_routing"]["tools"]["claude"]["strong"] == "test/strong" and d["model_routing"]["source"] == "user-provided"' \
  && ok "exact model IDs recorded for the named tool" || bad "per-tool model IDs not recorded"
grep -l '^model:' "$MOD"/.agent-army/agents/*.agent >/dev/null 2>&1 && bad "model IDs leaked into contracts" || ok "model IDs stay out of the shared contracts"
quiet_bootstrap "$MOD" --role-model-routing inherit
json "$MOD/.agent-army/config.json" 'd["model_routing"]["strategy"] == "inherit" and d["model_routing"]["tools"] == {}' \
  && ok "inherit disables per-role models" || bad "inherit did not disable routing"
locate "$MOD" --tool claude > "$OUT"
json "$OUT" 'd["roles"]["architect"]["model"] is None' && ok "inherit: locate reports no role model" || bad "inherit: locate still pins a model"

printf '\n\033[1mGATE 1.5 · incremental package migration\033[0m\n'
UPGRADE="$WORK/upgrade"; init_repo "$UPGRADE"
quiet_bootstrap "$UPGRADE"
printf '# Existing repo specialization\n' > "$UPGRADE/AGENTS.md"
printf '\n# PROFILE-SPECIALIZATION\n' >> "$UPGRADE/.agent-army/agents/agent-army-architect.agent"
legacy_profile "$UPGRADE/.agent-army/config.json"
(cd "$UPGRADE" && python3 "$GEN" --mode auto --dry-run --skip-apm > "$WORK/upgrade-plan.txt")
grep -q 'legacy profile -> 0.5.4' "$WORK/upgrade-plan.txt" && ok "unversioned profile gets an incremental plan" || bad "incremental plan missing"
grep -q 'Incremental Upgrade Review' "$WORK/upgrade-plan.txt" && grep -q 'new-skill' "$WORK/upgrade-plan.txt" && ok "unversioned profile previews package capabilities" || bad "upgrade review missing capabilities"
grep -q 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md" && bad "incremental dry-run changed AGENTS.md" || ok "incremental dry-run preserves AGENTS.md"
if (cd "$UPGRADE" && python3 "$GEN" --mode auto --skip-apm) >/dev/null 2>&1; then bad "incremental ran without a review outcome"; else ok "incremental needs the resolved review outcome"; fi
(cd "$UPGRADE" && python3 "$GEN" --mode auto --upgrade-review-outcome applied --skip-apm >/dev/null)
grep -q 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md" && ok "incremental migration adds managed feedback router" || bad "feedback router missing after migration"
json "$UPGRADE/.agent-army/config.json" 'd["package"]["version"] == "0.5.4" and d["package"]["upgrade_review"]["status"] == "applied"' \
  && ok "incremental migration records package version and review" || bad "package version or review not recorded"
grep -q 'PROFILE-SPECIALIZATION' "$UPGRADE/.agent-army/agents/agent-army-architect.agent" && ok "incremental update preserves specialized agent" || bad "incremental update overwrote specialized agent"
count="$(grep -c 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md")"
(cd "$UPGRADE" && python3 "$GEN" --mode auto --skip-apm >/dev/null)
[ "$count" = "$(grep -c 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md")" ] && ok "incremental migration is idempotent" || bad "incremental migration duplicated managed block"

UPGRADE_SKIP="$WORK/upgrade-role-skip"; init_repo "$UPGRADE_SKIP"
quiet_bootstrap "$UPGRADE_SKIP"; prepare_planning_role_upgrade "$UPGRADE_SKIP"
printf '\n# LOCAL-ARCHITECT-DECISION\n' >> "$UPGRADE_SKIP/.agent-army/agents/agent-army-architect.agent"
(cd "$UPGRADE_SKIP" && python3 "$GEN" --mode auto --dry-run --skip-apm > "$WORK/role-skip-plan.txt")
grep -q 'planning-analyst.md' "$WORK/role-skip-plan.txt" && grep -q 'plan-reviewer.md' "$WORK/role-skip-plan.txt" \
  && ok "upgrade review exposes both new role contracts" || bad "new role contracts missing from upgrade review"
(cd "$UPGRADE_SKIP" && python3 "$GEN" --mode auto --upgrade-review-outcome skipped --skip-apm >/dev/null)
[ ! -e "$UPGRADE_SKIP/.agent-army/agents/agent-army-planning-analyst.agent" ] \
  && grep -q 'LOCAL-ARCHITECT-DECISION' "$UPGRADE_SKIP/.agent-army/agents/agent-army-architect.agent" \
  && ok "skipped role upgrade preserves local role sources" || bad "skipped role upgrade changed local role sources"

UPGRADE_APPLY="$WORK/upgrade-role-apply"; init_repo "$UPGRADE_APPLY"
quiet_bootstrap "$UPGRADE_APPLY"; prepare_planning_role_upgrade "$UPGRADE_APPLY"
(cd "$UPGRADE_APPLY" && python3 "$GEN" --mode auto --upgrade-review-outcome applied --skip-apm >/dev/null)
[ -f "$UPGRADE_APPLY/.agent-army/agents/agent-army-planning-analyst.agent" ] && [ -f "$UPGRADE_APPLY/.agent-army/agents/agent-army-plan-reviewer.agent" ] \
  && ok "approved role upgrade adds the two roles" || bad "approved role upgrade failed"

ROLE_CONFLICT="$WORK/role-name-conflict"; init_repo "$ROLE_CONFLICT"
quiet_bootstrap "$ROLE_CONFLICT"; prepare_planning_role_upgrade "$ROLE_CONFLICT" yes
cp "$ROLE_CONFLICT/.agent-army/config.json" "$WORK/role-conflict-before.json"
if (cd "$ROLE_CONFLICT" && python3 "$GEN" --mode auto --upgrade-review-outcome applied --skip-apm) >/dev/null 2>&1; then
  bad "new planning role collision was silently accepted"
else ok "new planning role collision stops the upgrade"; fi
cmp -s "$WORK/role-conflict-before.json" "$ROLE_CONFLICT/.agent-army/config.json" && ok "planning role collision leaves config untouched" || bad "planning role collision changed config"

CONFLICT="$WORK/migration-conflict"; init_repo "$CONFLICT"
quiet_bootstrap "$CONFLICT"
printf '<!-- agent-army:feedback-router:start -->\nuser edit\n<!-- agent-army:feedback-router:end -->\n' > "$CONFLICT/AGENTS.md"
legacy_profile "$CONFLICT/.agent-army/config.json"
cp "$CONFLICT/.agent-army/config.json" "$WORK/conflict-config-before.json"
if (cd "$CONFLICT" && python3 "$GEN" --mode incremental --upgrade-review-outcome applied --skip-apm) >/dev/null 2>&1; then
  bad "modified managed block was overwritten"
else ok "modified managed block blocks incremental migration"; fi
cmp -s "$WORK/conflict-config-before.json" "$CONFLICT/.agent-army/config.json" && ok "conflicting migration preserves config" || bad "conflicting migration rewrote config"
sed -i.bak 's/"version": "0.5.4"/"version": "9.0.0"/' "$UPGRADE/.agent-army/config.json"; rm -f "$UPGRADE/.agent-army/config.json.bak"
if (cd "$UPGRADE" && python3 "$GEN" --mode auto --skip-apm) >/dev/null 2>&1; then bad "newer profile downgrade was allowed"; else ok "newer profile downgrade is blocked"; fi

printf '\n\033[1mGATE 1.6 · real 0.4.0 profile with native copies -> 0.5.4\033[0m\n'
PKG040="$WORK/pkg040"; mkdir -p "$PKG040"
if git -C "$ROOT" archive 241499c .apm/skills 2>/dev/null | tar -x -C "$PKG040" 2>/dev/null; then
  for tool in claude windsurf; do
    M="$WORK/from-040-$tool"; init_repo "$M"
    (cd "$M" && python3 "$PKG040/.apm/skills/bootstrap/bootstrap.py" "$tool" --skip-apm --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1)
    json "$M/.agent-army/config.json" 'd["version"] == 2 and d["target"] == "'"$tool"'"' && ok "$tool: the real 0.4.0 generator wrote a target-bound v2 profile" || bad "$tool: 0.4.0 profile not created"
    if [ "$tool" = claude ]; then
      # What APM 0.4 rendered: a byte copy of every contract (model line included).
      mkdir -p "$M/.claude/agents"
      for f in "$M"/.agent-army/agents/*.agent; do cp "$f" "$M/.claude/agents/$(basename "$f" .agent).md"; done
      printf '\n# hand edit\n' >> "$M/.claude/agents/agent-army-coder.md"
      printf -- '---\nname: my-own\n---\n' > "$M/.claude/agents/my-own.md"
      grep -q '^model:.*agent-army-role-profile' "$M/.agent-army/agents/agent-army-tester.agent" && ok "claude: 0.4.0 wrote a generated model line into the contract" || bad "claude: 0.4.0 contract has no generated model line"
      edited=".claude/agents/agent-army-coder.md"; sample=".claude/agents/agent-army-tester.md"
    else
      edited=".windsurf/skills/agent-army-coder/SKILL.md"; sample=".windsurf/skills/agent-army-tester/SKILL.md"
      printf '\n# hand edit\n' >> "$M/$edited"
    fi
    (cd "$M" && python3 "$GEN" --mode auto --dry-run --skip-apm > "$WORK/040-$tool.txt" 2>&1)
    grep -q '0.4.0 -> 0.5.4' "$WORK/040-$tool.txt" && grep -q "conflict: native role copies kept.*$edited" "$WORK/040-$tool.txt" \
      && ok "$tool: review lists the edited native copy as a conflict" || bad "$tool: review missed the edited copy"
    (cd "$M" && python3 "$GEN" --mode auto --upgrade-review-outcome applied --skip-apm >/dev/null 2>&1)
    [ ! -e "$M/$sample" ] && ok "$tool: identical native copies removed" || bad "$tool: identical native copy left behind"
    [ -f "$M/$edited" ] && ok "$tool: edited native copy kept" || bad "$tool: edited native copy deleted"
    json "$M/.agent-army/config.json" 'd["version"] == 3 and "target" not in d' && ok "$tool: profile migrated to schema v3 without target" || bad "$tool: profile not migrated"
    grep -l 'agent-army-role-profile' "$M"/.agent-army/agents/*.agent >/dev/null 2>&1 && bad "$tool: generated model lines left in contracts" || ok "$tool: generated model lines moved out of contracts"
  done
  json "$WORK/from-040-claude/.agent-army/config.json" 'd["model_routing"]["tools"]["claude"]["strong"] == "opus"' \
    && ok "claude: model tiers carried into per-tool routing" || bad "claude: model tiers lost"
  [ -f "$WORK/from-040-claude/.claude/agents/my-own.md" ] && ok "claude: the user's own agents are untouched" || bad "claude: a user agent was removed"
else
  bad "cannot extract the 0.4.0 package (commit 241499c) for the migration gate"
fi

LEGACY_AGENTS="$WORK/legacy-agent-sources"; init_repo "$LEGACY_AGENTS"
mkdir -p "$LEGACY_AGENTS/.apm/agents"
cp "$ROOT/.apm/skills/bootstrap/baseline/core/agents/architect.md" "$LEGACY_AGENTS/.apm/agents/agent-army-architect.agent.md"
printf '\nLEGACY-SPECIALIZATION\n' >> "$LEGACY_AGENTS/.apm/agents/agent-army-architect.agent.md"
quiet_bootstrap "$LEGACY_AGENTS"
grep -q 'LEGACY-SPECIALIZATION' "$LEGACY_AGENTS/.agent-army/agents/agent-army-architect.agent" \
  && [ ! -f "$LEGACY_AGENTS/.apm/agents/agent-army-architect.agent.md" ] \
  && ok "pre-0.3 Markdown agent source migrated to the canonical source" || bad "legacy Markdown agent source migration failed"

printf '\n\033[1mGATE 2 · runtime safety\033[0m\n'
SAFE="$WORK/safety"; init_repo "$SAFE"
printf '{"scripts":{"lint":"true","test":"true"}}\n' > "$SAFE/package.json"
bootstrap "$SAFE" --runtime-hooks army --git-precommit army --ci disabled >/dev/null
[ -f "$SAFE/.apm/hooks/agent-army-guard.json" ] && ok "hook primitives written without a tool" || bad "hook primitives missing"
if printf '%s' '{"tool_name":"Bash","tool_input":{"command":"printf secret > .env"}}' | (cd "$SAFE" && python3 .agent-army/runtime.py guard) >/dev/null 2>&1; then
  bad "shell write to .env was allowed"
else ok "shell write to .env blocked"; fi
printf 'AWS_ACCESS_KEY_ID=AKIA1234567890ABCDEF\n' > "$SAFE/normal.txt"
(cd "$SAFE" && git add normal.txt)
if (cd "$SAFE" && python3 .agent-army/runtime.py precommit) >/dev/null 2>&1; then
  bad "staged secret in ordinary file was allowed"
else ok "staged secret in ordinary file blocked"; fi
sed -i.bak 's/"npm"/"definitely-not-a-command"/g' "$SAFE/.agent-army/config.json"; rm -f "$SAFE/.agent-army/config.json.bak"
if (cd "$SAFE" && python3 .agent-army/runtime.py verify) >/dev/null 2>&1; then
  bad "failed structured quality command passed"
else ok "failed structured quality command fails"; fi

printf '\n\033[1mGATE 3 · real APM renders hooks only\033[0m\n'
if command -v apm >/dev/null 2>&1; then
  HOOKS="$WORK/apm-hooks"; init_repo "$HOOKS"
  if (cd "$HOOKS" && python3 "$GEN" --tool claude --runtime-hooks army --git-precommit disabled --ci disabled) >"$WORK/apm.txt" 2>&1; then
    grep -q 'runtime.py guard' "$HOOKS/.claude/settings.json" 2>/dev/null && ok "claude: APM rendered the runtime hooks" || bad "claude: runtime hooks not rendered"
    no_native_agents "$HOOKS" && ok "claude: APM pass created no native agent copy" || bad "claude: APM pass created native agents"
  else
    bad "apm hook render failed (see $WORK/apm.txt)"
  fi
else
  ok "apm not installed; hook render gate skipped"
fi

printf '\n\033[1mGATE · package-local Army discovery (test_army.py)\033[0m\n'
if python3 "$ROOT/.apm/skills/bootstrap/tests/test_army.py" >"$WORK/test_army.txt" 2>&1; then
  ok "nested/explicit Army selection, isolation and path-escape checks pass"
else
  bad "test_army.py failed (see $WORK/test_army.txt)"
fi

printf '\n\033[1mResult: %d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
