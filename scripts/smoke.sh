#!/usr/bin/env bash
# Deterministic v0.4 smoke tests.  They intentionally exercise the generator
# without APM network/install state; the generator itself owns the frozen APM
# handoff in normal bootstrap mode.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
need(){ "$@" >/dev/null 2>&1 && ok "$2" || bad "$2"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-army-v2.XXXXXX")"
cleanup(){ [ -n "${KEEP_WORK:-}" ] && echo "kept $WORK" || rm -rf "$WORK"; }
trap cleanup EXIT
init_repo(){
  local dir="$1"
  mkdir -p "$dir"
  (cd "$dir" && git init -q && git config user.email smoke@example.test && git config user.name smoke)
}
bootstrap(){
  local dir="$1" target="$2"; shift 2
  (cd "$dir" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" "$target" --skip-apm "$@")
}
bootstrap_apm(){
  local dir="$1" target="$2"; shift 2
  (cd "$dir" && python3 .agents/skills/bootstrap/bootstrap.py "$target" "$@")
}
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

PACKAGE_SKILLS="bootstrap ship new-agent new-skill adapt-army product product-strategy product-red-team market-research business-case validate-product product-spec solution-architecture delivery-plan go-to-market product-metrics ux-review legal-review launch-readiness"
PRODUCT_SKILLS="${PACKAGE_SKILLS#bootstrap ship new-agent new-skill adapt-army }"
all_skills_present(){
  local dir="$1" skill
  for skill in $PACKAGE_SKILLS; do [ -f "$dir/.agents/skills/$skill/SKILL.md" ] || return 1; done
}
no_advisor_agents(){
  # Product skills are skills only: no role contract, APM staging or native
  # agent/role-skill output may carry a product skill name.
  local dir="$1" skill
  for skill in $PRODUCT_SKILLS; do
    if find "$dir" \( -path "$dir/.git" -o -path "$dir/apm_modules" \) -prune \
      -o \( -path "*/agents/*$skill*" -o -path "*/agent/*$skill*" -o -name "agent-army-$skill*" \) -print 2>/dev/null | grep -q .; then return 1; fi
  done
}
tree_digest(){
  (cd "$1" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs sha256sum | sha256sum)
}
# Turn a fresh 0.4.0 profile into the shape a 0.3.1 install leaves behind:
# the five core skills, package version 0.3.1, a hash-only inventory without
# the product skills, and the pre-ADR docs-writer template digest.
downgrade_to_031(){
  local dir="$1" skill
  for skill in $PRODUCT_SKILLS; do rm -rf "$dir/.agents/skills/$skill"; done
  python3 - "$dir" $PRODUCT_SKILLS <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
path = root / '.agent-army/config.json'
data = json.loads(path.read_text())
package = data['package']
package['version'] = '0.3.1'
package.pop('upgrade_review', None)
for skill in sys.argv[2:]:
    package['inventory']['skills'].pop(skill, None)
package['inventory']['templates']['bootstrap/baseline/core/agents/docs-writer.md'] = '0' * 64
path.write_text(json.dumps(data, indent=2) + '\n')
PY
}

printf '\n\033[1mGATE 0 · profile generation for every target\033[0m\n'
for target in claude codex cursor copilot opencode gemini windsurf; do
  dir="$WORK/$target"; init_repo "$dir"
  bootstrap "$dir" "$target" --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
  if [ "$target" = windsurf ]; then
    [ -f "$dir/.windsurf/skills/agent-army-architect/SKILL.md" ] && ok "$target: role-skills fallback" || bad "$target: fallback role missing"
  else
    count="$(find "$dir/.agent-army/agents" -name 'agent-army-*.agent' 2>/dev/null | wc -l | tr -d ' ')"
    [ "$count" = 9 ] && ok "$target: nine canonical agent sources" || bad "$target: expected nine agent sources, got $count"
    python3 - "$dir/.agent-army/config.json" <<'PY'
import json, pathlib, sys
roles = json.loads(pathlib.Path(sys.argv[1]).read_text())['model_routing']['roles']
assert roles.get('planning-analyst') == 'mid'
assert roles.get('plan-reviewer') == 'strong'
PY
    [ "$?" -eq 0 ] && ok "$target: planning roles have the selected capability tiers" || bad "$target: planning-role capability tiers are wrong"
    if [ "$target" = opencode ]; then
      [ ! -f "$dir/.apm/agents/agent-army-architect.agent.md" ] && ok "$target: no APM agent staging" || bad "$target: unexpected APM agent staging"
      [ ! -f "$dir/.opencode/agents/agent-army-architect.md" ] && ok "$target: no native Markdown agent output" || bad "$target: unexpected native Markdown agent output"
    else
      [ -f "$dir/.apm/agents/agent-army-architect.agent.md" ] && ok "$target: APM staging source present" || bad "$target: APM staging source missing"
      git -C "$dir" check-ignore -q .apm/agents/agent-army-architect.agent.md \
        && ok "$target: APM Markdown staging is ignored" || bad "$target: APM Markdown staging is tracked"
    fi
  fi
  if [ "$target" = windsurf ]; then
    progress_agent="$dir/.windsurf/skills/agent-army-architect/SKILL.md"
  else
    progress_agent="$dir/.agent-army/agents/agent-army-architect.agent"
  fi
  grep -q '## Execution Progress' "$progress_agent" && grep -q 'Temporary delegation' "$progress_agent" \
    && ok "$target: resumable interactive contract present" || bad "$target: interactive contract missing"
  all_skills_present "$dir" && ok "$target: all 19 package skills present" || bad "$target: package skills missing"
  no_advisor_agents "$dir" && ok "$target: no agent output for product skills" || bad "$target: product skill rendered as an agent"
  "$ROOT/scripts/check.sh" --target-dir "$dir" >/dev/null 2>&1 && ok "$target: profile validates" || bad "$target: profile validation failed"
done

LEGACY_AGENTS="$WORK/legacy-agent-sources"; init_repo "$LEGACY_AGENTS"
mkdir -p "$LEGACY_AGENTS/.apm/agents"
mkdir -p "$LEGACY_AGENTS/.opencode/agents"
cp "$ROOT/.apm/skills/bootstrap/baseline/core/agents/architect.md" \
  "$LEGACY_AGENTS/.apm/agents/agent-army-architect.agent.md"
printf '\nLEGACY-SPECIALIZATION\n' >> "$LEGACY_AGENTS/.apm/agents/agent-army-architect.agent.md"
printf '# generated native output\n' > "$LEGACY_AGENTS/.opencode/agents/agent-army-architect.md"
bootstrap "$LEGACY_AGENTS" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
[ -f "$LEGACY_AGENTS/.agent-army/agents/agent-army-architect.agent" ] \
  && grep -q 'LEGACY-SPECIALIZATION' "$LEGACY_AGENTS/.agent-army/agents/agent-army-architect.agent" \
  && [ ! -f "$LEGACY_AGENTS/.apm/agents/agent-army-architect.agent.md" ] \
  && [ ! -f "$LEGACY_AGENTS/.opencode/agents/agent-army-architect.md" ] \
  && ok "legacy Markdown agent source migrated to canonical source" \
  || bad "legacy Markdown agent source migration failed"

MIG="$WORK/cache-migration"; init_repo "$MIG"
mkdir -p "$MIG/apm_modules/psrebrny/agent-army/.apm"
cp -R "$ROOT/.apm/skills" "$MIG/apm_modules/psrebrny/agent-army/.apm/"
(cd "$MIG" && python3 apm_modules/psrebrny/agent-army/.apm/skills/bootstrap/bootstrap.py opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1)
all_skills_present "$MIG" \
  && ok "cache migration: all skills materialized to .agents/skills" || bad "cache migration: skills not materialized"
[ -f "$MIG/.agent-army/agents/agent-army-architect.agent" ] \
  && [ ! -f "$MIG/.opencode/agents/agent-army-architect.md" ] \
  && ok "cache migration: OpenCode keeps canonical role contracts only" \
  || bad "cache migration: OpenCode native agent output unexpectedly exists"

LEGACY="$WORK/legacy-model"; init_repo "$LEGACY"
bootstrap "$LEGACY" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
sed -i.bak '3i\
model: user-owned/custom-model' "$LEGACY/.agent-army/agents/agent-army-architect.agent"; rm -f "$LEGACY/.agent-army/agents/agent-army-architect.agent.bak"
bootstrap "$LEGACY" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --upgrade-review-outcome applied >/dev/null
if grep -q '^model: user-owned/custom-model$' "$LEGACY/.agent-army/agents/agent-army-architect.agent"; then
  ok "user-owned role model preserved on re-bootstrap"
else
  bad "user-owned role model was overwritten"
fi
grep -q '"strategy": "inherit"' "$LEGACY/.agent-army/config.json" \
  && ok "OpenCode role contracts use the main-session model" || bad "OpenCode unexpectedly recorded native role routing"

ROUTED="$WORK/role-routing"; init_repo "$ROUTED"
bootstrap "$ROUTED" cursor --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --model-light test/light-v1 --model-mid test/mid-v1 --model-strong test/strong-v1 >/dev/null
grep -q '^model: "test/strong-v1" # agent-army-role-profile: strong$' "$ROUTED/.agent-army/agents/agent-army-architect.agent" \
  && grep -q '^model: "test/light-v1" # agent-army-role-profile: light$' "$ROUTED/.agent-army/agents/agent-army-tester.agent" \
  && grep -q '^model: "test/mid-v1" # agent-army-role-profile: mid$' "$ROUTED/.agent-army/agents/agent-army-planning-analyst.agent" \
  && grep -q '^model: "test/strong-v1" # agent-army-role-profile: strong$' "$ROUTED/.agent-army/agents/agent-army-plan-reviewer.agent" \
  && ok "exact target model IDs route by role" || bad "role model routing missing or wrong"
bootstrap "$ROUTED" cursor --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --model-light test/light-v2 --model-mid test/mid-v2 --model-strong test/strong-v2 \
  --upgrade-review-outcome applied >/dev/null
grep -q '^model: "test/strong-v2" # agent-army-role-profile: strong$' "$ROUTED/.agent-army/agents/agent-army-architect.agent" \
  && ok "generated role model updated on re-bootstrap" || bad "generated role model did not update"
grep -q '"strategy": "per_role_static"' "$ROUTED/.agent-army/config.json" \
  && ok "role model routing recorded" || bad "role model routing not recorded"
bootstrap "$ROUTED" cursor --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --role-model-routing inherit --upgrade-review-outcome applied >/dev/null
if grep -q '^model:' "$ROUTED/.agent-army/agents/agent-army-architect.agent"; then
  bad "managed role model was not removed for inherit fallback"
else
  ok "managed role model removed for inherit fallback"
fi

printf '\n\033[1mGATE 1 · ownership and non-clobbering\033[0m\n'
OWN="$WORK/ownership"; init_repo "$OWN"
mkdir -p "$OWN/.github/workflows"; printf 'name: user-ci\n' > "$OWN/.github/workflows/user.yml"
mkdir -p "$OWN/.git/hooks"; printf '#!/usr/bin/env node\n' > "$OWN/.git/hooks/pre-commit"; chmod +x "$OWN/.git/hooks/pre-commit"
bootstrap "$OWN" claude --runtime-hooks external --git-precommit external --ci external >/dev/null
grep -q 'env node' "$OWN/.git/hooks/pre-commit" && ok "external pre-commit preserved" || bad "external pre-commit changed"
[ ! -f "$OWN/.github/workflows/agent-army-quality.yml" ] && ok "external CI preserved" || bad "external CI unexpectedly installed"
grep -q '"mode": "external"' "$OWN/.agent-army/config.json" && ok "external ownership recorded" || bad "external ownership not recorded"
printf '\nSMOKE-SPECIALIZATION\n' >> "$OWN/.agent-army/agents/agent-army-architect.agent"
bootstrap "$OWN" claude --upgrade-review-outcome applied >/dev/null
grep -q 'SMOKE-SPECIALIZATION' "$OWN/.agent-army/agents/agent-army-architect.agent" && ok "re-bootstrap preserves specialized agent source" || bad "re-bootstrap overwrote specialized agent source"
grep -q '"mode": "external"' "$OWN/.agent-army/config.json" && ok "re-bootstrap preserves ownership choice" || bad "re-bootstrap changed ownership choice"

BLOCK="$WORK/blocked"; init_repo "$BLOCK"
mkdir -p "$BLOCK/.git/hooks"; printf '#!/usr/bin/env node\n' > "$BLOCK/.git/hooks/pre-commit"; chmod +x "$BLOCK/.git/hooks/pre-commit"
bootstrap "$BLOCK" codex --runtime-hooks disabled --git-precommit army --ci disabled >/dev/null
grep -A2 'git_precommit' "$BLOCK/.agent-army/config.json" | grep -q blocked && ok "unsafe hook replacement blocked" || bad "unsafe hook replacement was not blocked"

printf '\n\033[1mGATE 1.5 · incremental package migration\033[0m\n'
UPGRADE="$WORK/upgrade"; init_repo "$UPGRADE"
bootstrap "$UPGRADE" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
printf '# Existing repo specialization\n' > "$UPGRADE/AGENTS.md"
printf '\n# PROFILE-SPECIALIZATION\n' >> "$UPGRADE/.agent-army/agents/agent-army-architect.agent"
legacy_profile "$UPGRADE/.agent-army/config.json"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --dry-run --skip-apm > "$WORK/upgrade-plan.txt")
grep -q 'legacy profile -> 0.4.0' "$WORK/upgrade-plan.txt" && ok "unversioned profile gets an incremental plan" || bad "incremental plan missing"
grep -q 'Incremental Upgrade Review' "$WORK/upgrade-plan.txt" && grep -q 'new-skill' "$WORK/upgrade-plan.txt" && ok "unversioned profile previews package capabilities" || bad "upgrade review missing capabilities"
grep -q 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md" && bad "incremental dry-run changed AGENTS.md" || ok "incremental dry-run preserves AGENTS.md"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome applied --skip-apm >/dev/null)
grep -q 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md" && ok "incremental migration adds managed feedback router" || bad "feedback router missing after migration"
grep -q '"version": "0.4.0"' "$UPGRADE/.agent-army/config.json" && ok "incremental migration records package version" || bad "package version not recorded"
grep -q '"inventory"' "$UPGRADE/.agent-army/config.json" && grep -q '"upgrade_review"' "$UPGRADE/.agent-army/config.json" && ok "incremental migration records hash-only inventory and review" || bad "incremental inventory or review missing"
grep -q 'PROFILE-SPECIALIZATION' "$UPGRADE/.agent-army/agents/agent-army-architect.agent" && ok "incremental update preserves specialized agent" || bad "incremental update overwrote specialized agent"
count="$(grep -c 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md")"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm >/dev/null)
[ "$count" = "$(grep -c 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md")" ] && ok "incremental migration is idempotent" || bad "incremental migration duplicated managed block"
printf '\n# local template change\n' >> "$UPGRADE/.agents/skills/bootstrap/baseline/core/agents/tester.md"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --dry-run --skip-apm > "$WORK/template-review.txt")
grep -q 'changed baseline templates' "$WORK/template-review.txt" && grep -q 'baseline/core/agents/tester.md' "$WORK/template-review.txt" && ok "template change creates a recommendation" || bad "template change was not surfaced for review"
grep -q 'PROFILE-SPECIALIZATION' "$UPGRADE/.agent-army/agents/agent-army-architect.agent" && ok "template review does not overwrite local agent" || bad "template review overwrote local agent"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome skipped --skip-apm >/dev/null)
grep -A2 '"upgrade_review"' "$UPGRADE/.agent-army/config.json" | grep -q '"status": "skipped"' && ok "upgrade review decision is recorded" || bad "upgrade review decision was not recorded"

UPGRADE_SKIP="$WORK/upgrade-role-skip"; init_repo "$UPGRADE_SKIP"
bootstrap "$UPGRADE_SKIP" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
prepare_planning_role_upgrade "$UPGRADE_SKIP"
printf '\n# LOCAL-ARCHITECT-DECISION\n' >> "$UPGRADE_SKIP/.agent-army/agents/agent-army-architect.agent"
(cd "$UPGRADE_SKIP" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --dry-run --skip-apm > "$WORK/role-skip-plan.txt")
grep -q 'planning-analyst.md' "$WORK/role-skip-plan.txt" && grep -q 'plan-reviewer.md' "$WORK/role-skip-plan.txt" \
  && ok "upgrade review exposes both new role contracts" || bad "new role contracts missing from upgrade review"
(cd "$UPGRADE_SKIP" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome skipped --skip-apm >/dev/null)
[ ! -e "$UPGRADE_SKIP/.agent-army/agents/agent-army-planning-analyst.agent" ] \
  && [ ! -e "$UPGRADE_SKIP/.agent-army/agents/agent-army-plan-reviewer.agent" ] \
  && grep -q 'LOCAL-ARCHITECT-DECISION' "$UPGRADE_SKIP/.agent-army/agents/agent-army-architect.agent" \
  && ok "skipped role upgrade preserves local role sources" || bad "skipped role upgrade changed local role sources"

UPGRADE_APPLY="$WORK/upgrade-role-apply"; init_repo "$UPGRADE_APPLY"
bootstrap "$UPGRADE_APPLY" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
prepare_planning_role_upgrade "$UPGRADE_APPLY"
printf '\n# LOCAL-ARCHITECT-DECISION\n' >> "$UPGRADE_APPLY/.agent-army/agents/agent-army-architect.agent"
(cd "$UPGRADE_APPLY" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --dry-run --skip-apm > "$WORK/role-apply-plan.txt")
(cd "$UPGRADE_APPLY" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome applied --skip-apm >/dev/null)
[ -f "$UPGRADE_APPLY/.agent-army/agents/agent-army-planning-analyst.agent" ] \
  && [ -f "$UPGRADE_APPLY/.agent-army/agents/agent-army-plan-reviewer.agent" ] \
  && grep -q 'LOCAL-ARCHITECT-DECISION' "$UPGRADE_APPLY/.agent-army/agents/agent-army-architect.agent" \
  && ok "approved role upgrade adds two roles and preserves specialization" || bad "approved role upgrade failed or overwrote specialization"

ROLE_CONFLICT="$WORK/role-name-conflict"; init_repo "$ROLE_CONFLICT"
bootstrap "$ROLE_CONFLICT" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
prepare_planning_role_upgrade "$ROLE_CONFLICT" yes
cp "$ROLE_CONFLICT/.agent-army/config.json" "$WORK/role-conflict-config-before.json"
cp "$ROLE_CONFLICT/.agent-army/agents/agent-army-planning-analyst.agent" "$WORK/role-conflict-source-before.agent"
if (cd "$ROLE_CONFLICT" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome applied --skip-apm) >/dev/null 2>&1; then
  bad "new planning role collision was silently accepted"
else
  ok "new planning role collision stops the upgrade"
fi
cmp -s "$WORK/role-conflict-config-before.json" "$ROLE_CONFLICT/.agent-army/config.json" \
  && cmp -s "$WORK/role-conflict-source-before.agent" "$ROLE_CONFLICT/.agent-army/agents/agent-army-planning-analyst.agent" \
  && ok "planning role collision leaves config and local role untouched" || bad "planning role collision changed local files"

CONFLICT="$WORK/migration-conflict"; init_repo "$CONFLICT"
bootstrap "$CONFLICT" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
printf '<!-- agent-army:feedback-router:start -->\nuser edit\n<!-- agent-army:feedback-router:end -->\n' > "$CONFLICT/AGENTS.md"
legacy_profile "$CONFLICT/.agent-army/config.json"
cp "$CONFLICT/.agent-army/config.json" "$WORK/conflict-config-before.json"
if (cd "$CONFLICT" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode incremental --upgrade-review-outcome applied --skip-apm) >/dev/null 2>&1; then
  bad "modified managed block was overwritten"
else
  ok "modified managed block blocks incremental migration"
fi
cmp -s "$WORK/conflict-config-before.json" "$CONFLICT/.agent-army/config.json" && ok "conflicting migration preserves config" || bad "conflicting migration rewrote config"
if (cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" codex --mode auto --skip-apm) >/dev/null 2>&1; then
  bad "target switch bypassed full bootstrap"
else
  ok "target switch requires full bootstrap"
fi
sed -i.bak 's/"version": "0.4.0"/"version": "9.0.0"/' "$UPGRADE/.agent-army/config.json"; rm -f "$UPGRADE/.agent-army/config.json.bak"
if (cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm) >/dev/null 2>&1; then
  bad "newer profile downgrade was allowed"
else
  ok "newer profile downgrade is blocked"
fi

printf '\n\033[1mGATE 1.6 · upgrade from 0.3.1 to 0.4.0\033[0m\n'
STORES='{"stores":{"work_items":{"kind":"local"}}}'
UP031="$WORK/upgrade-031"; init_repo "$UP031"
mkdir -p "$UP031/.agent-army"; printf '%s\n' "$STORES" > "$UP031/.agent-army/stores.json"
cp "$UP031/.agent-army/stores.json" "$WORK/stores-before.json"
bootstrap "$UP031" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
cmp -s "$WORK/stores-before.json" "$UP031/.agent-army/stores.json" && ok "first bootstrap leaves stores.json byte-identical" || bad "first bootstrap changed stores.json"
downgrade_to_031 "$UP031"
printf '\n# LOCAL-DOCS-WRITER-SPECIALIZATION\n' >> "$UP031/.agent-army/agents/agent-army-docs-writer.agent"
cp -R "$UP031" "$WORK/upgrade-031-apply"
cp -R "$UP031/.agent-army/agents" "$WORK/agents-031-before"
(cd "$UP031" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --dry-run --skip-apm > "$WORK/upgrade-031-plan.txt")
grep -q '0.3.1 -> 0.4.0' "$WORK/upgrade-031-plan.txt" && ok "0.3.1 profile gets an incremental 0.4.0 plan" || bad "0.3.1 -> 0.4.0 plan missing"
missing_new=""
for skill in $PRODUCT_SKILLS; do grep -q "new skills:.*\b$skill\b" "$WORK/upgrade-031-plan.txt" || missing_new="$missing_new $skill"; done
[ -z "$missing_new" ] && ok "upgrade review lists the 14 product skills as new capabilities" || bad "upgrade review misses new skills:$missing_new"
grep -q 'recommended local diff: .*docs-writer.md -> .agent-army/agents/agent-army-docs-writer.agent' "$WORK/upgrade-031-plan.txt" \
  && ok "upgrade review recommends merging the docs-writer change into the local contract" || bad "docs-writer recommendation missing"
(cd "$UP031" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome skipped --skip-apm >/dev/null)
all_skills_present "$UP031" && ok "0.3.1 upgrade adds the 14 missing skills" || bad "0.3.1 upgrade did not add the missing skills"
diff -r "$WORK/agents-031-before" "$UP031/.agent-army/agents" >/dev/null \
  && ok "skipped upgrade leaves every local role contract byte-identical" || bad "skipped upgrade changed local role contracts"
cmp -s "$WORK/stores-before.json" "$UP031/.agent-army/stores.json" && ok "upgrade leaves stores.json byte-identical" || bad "upgrade changed stores.json"
grep -q '"version": "0.4.0"' "$UP031/.agent-army/config.json" \
  && grep -A2 '"upgrade_review"' "$UP031/.agent-army/config.json" | grep -q '"status": "skipped"' \
  && ok "upgrade records 0.4.0 and the skipped review" || bad "upgrade version or skipped review not recorded"
before="$(tree_digest "$UP031")"
(cd "$UP031" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm > "$WORK/upgrade-031-second.txt" 2>&1)
[ "$before" = "$(tree_digest "$UP031")" ] && grep -q 'profile is current' "$WORK/upgrade-031-second.txt" \
  && ok "second 0.4.0 run is a no-op" || bad "second 0.4.0 run wrote files"
bootstrap "$UP031" opencode --mode full >/dev/null
cmp -s "$WORK/stores-before.json" "$UP031/.agent-army/stores.json" && ok "--mode full leaves stores.json byte-identical" || bad "--mode full changed stores.json"
UP031_APPLY="$WORK/upgrade-031-apply"
(cd "$UP031_APPLY" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome applied --skip-apm >/dev/null)
grep -A2 '"upgrade_review"' "$UP031_APPLY/.agent-army/config.json" | grep -q '"status": "applied"' \
  && grep -q 'LOCAL-DOCS-WRITER-SPECIALIZATION' "$UP031_APPLY/.agent-army/agents/agent-army-docs-writer.agent" \
  && ok "applied upgrade records the outcome and keeps the docs-writer specialization" || bad "applied upgrade outcome or specialization missing"

printf '\n\033[1mGATE 2 · runtime safety\033[0m\n'
SAFE="$WORK/safety"; init_repo "$SAFE"
printf '{"scripts":{"lint":"true","test":"true"}}\n' > "$SAFE/package.json"
bootstrap "$SAFE" claude --runtime-hooks army --git-precommit army --ci disabled >/dev/null
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

printf '\n\033[1mGATE 3 · real APM rendering\033[0m\n'
for target in claude codex cursor copilot opencode gemini windsurf; do
  dir="$WORK/apm-$target"; mkdir -p "$dir/.agents"; cp -R "$ROOT/.apm/skills" "$dir/.agents/skills"; init_repo "$dir"
  case "$target" in
    cursor)
      render_args=(--model-light test/light --model-mid test/mid --model-strong test/strong)
      ;;
    opencode) render_args=(--role-model-routing inherit) ;;
    *) render_args=(--role-model-routing auto) ;;
  esac
  if ! bootstrap_apm "$dir" "$target" --runtime-hooks disabled --git-precommit disabled --ci disabled "${render_args[@]}" >/dev/null; then
    bad "$target: frozen APM rendering failed"; continue
  fi
  if [ "$target" = opencode ]; then
    if find "$dir/.apm/agents" -type f -name 'agent-army-*.agent.md' -print -quit 2>/dev/null | grep -q .; then
      bad "$target: APM Markdown staging was created"
    elif find "$dir/.opencode/agents" -type f -name 'agent-army-*.md' -print -quit 2>/dev/null | grep -q .; then
      bad "$target: native Markdown agent output was created"
    else
      ok "$target: canonical role contracts only"
    fi
  else
    if find "$dir/.apm/agents" -type f -name 'agent-army-*.agent.md' -print -quit 2>/dev/null | grep -q .; then
      bad "$target: temporary APM Markdown staging was left behind"
    else
      ok "$target: temporary APM Markdown staging cleaned"
    fi
  fi
  case "$target" in
    claude) agent="$dir/.claude/agents/agent-army-architect.md" ;;
    codex) agent="$dir/.codex/agents/agent-army-architect.toml" ;;
    cursor) agent="$dir/.cursor/agents/agent-army-architect.md" ;;
    copilot) agent="$dir/.github/agents/agent-army-architect.agent.md" ;;
    opencode) agent="" ;;
    gemini) agent="$dir/.gemini/agents/agent-army-architect.md" ;;
    windsurf) agent="$dir/.windsurf/skills/agent-army-architect/SKILL.md" ;;
  esac
  all_skills_present "$dir" && ok "$target: all 19 package skills present" || bad "$target: package skills missing"
  no_advisor_agents "$dir" && ok "$target: no agent output for product skills" || bad "$target: product skill rendered as an agent"
  if [ "$target" = opencode ]; then
    [ -f "$dir/.agent-army/agents/agent-army-architect.agent" ] \
      && ok "$target: main-thread role contract available" \
      || bad "$target: canonical role contract missing"
    continue
  fi
  if [ -f "$agent" ]; then
    ok "$target: expected native/degraded output rendered"
    case "$target" in
      claude|cursor|opencode)
        grep -Eq '^(model:|model =)' "$agent" && ok "$target: native agent has static role model" || bad "$target: native role model missing"
        ;;
      *)
        if grep -Eq '^(model:|model =)' "$agent"; then
          bad "$target: native agent unexpectedly pins a model"
        else
          ok "$target: native agent inherits runtime model"
        fi
        ;;
    esac
    grep -q 'Delegation Contract' "$agent" && ok "$target: delegation contract rendered" || bad "$target: delegation contract missing after render"
    grep -q '## Execution State' "$agent" && ok "$target: execution state rendered" || bad "$target: execution state missing after render"
    grep -q 'Active roles' "$agent" && ok "$target: active-role state rendered" || bad "$target: active-role state missing after render"
    grep -q 'Execution scope' "$agent" && ok "$target: scope-selection state rendered" || bad "$target: scope-selection state missing after render"
    grep -q 'Scope Profile' "$agent" && ok "$target: scope-profile state rendered" || bad "$target: scope-profile state missing after render"
    grep -q 'autonomous | interactive' "$agent" && ok "$target: two interaction modes rendered" || bad "$target: two interaction modes missing after render"
    grep -q '## Interaction Card' "$agent" && ok "$target: interaction card rendered" || bad "$target: interaction card missing after render"
    grep -q '## Execution Progress' "$agent" && grep -q 'Temporary delegation' "$agent" \
      && grep -q 'behavior decision' "$agent" && grep -q 'Discussion:' "$agent" \
      && ok "$target: progress, behavior decision and bounded delegation rendered" \
      || bad "$target: interactive delivery state missing after render"
    grep -q 'Checkpoint:' "$agent" && grep -q 'Question:' "$agent" && grep -q 'Options:' "$agent" \
      && ok "$target: interaction card has a decision contract" || bad "$target: interaction card decision contract missing after render"
    if grep -Eq '^[- ]*\*\*(Checkpoints|Interactive checkpoint):' "$agent"; then
      bad "$target: legacy checkpoint selection remains after render"
    else
      ok "$target: no legacy checkpoint selection rendered"
    fi
    grep -q 'Configuration source' "$agent" && ok "$target: manual-config state rendered" || bad "$target: manual-config state missing after render"
    grep -q 'Execution Profile' "$agent" && ok "$target: execution profile rendered" || bad "$target: execution profile missing after render"
    if grep -q 'Model & Effort Recommendation' "$agent"; then
      bad "$target: concrete model recommendation leaked into blueprint"
    else
      ok "$target: blueprint has no global model recommendation"
    fi
    grep -q '## Handoff' "$agent" && ok "$target: handoff rendered" || bad "$target: handoff missing after render"
  else
    bad "$target: expected output missing"
  fi
done

printf '\n\033[1mResult: %d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
