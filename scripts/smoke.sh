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
# Where APM installs the package skills for a target: the one copy (tools/<target>.yml dirs.skills).
skills_dir_for(){ case "$1" in claude) echo .claude/skills ;; *) echo .agents/skills ;; esac; }
# Place the package skills where APM would, then run the generator from that copy.
install_skills(){
  local dir="$1" target="$2" sd; sd="$(skills_dir_for "$target")"
  mkdir -p "$dir/$(dirname "$sd")"; cp -R "$ROOT/.apm/skills" "$dir/$sd"
}
bootstrap_apm(){
  local dir="$1" target="$2"; shift 2
  (cd "$dir" && python3 "$(skills_dir_for "$target")/bootstrap/bootstrap.py" "$target" "$@")
}
# Deployed copies of the bootstrap skill (APM sources in .apm and the apm_modules cache are not copies).
skill_copies(){
  find "$1" \( -path "$1/.git" -o -path "$1/apm_modules" -o -path "$1/.apm" \) -prune \
    -o -path '*/skills/bootstrap/SKILL.md' -print 2>/dev/null | wc -l | tr -d ' '
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
  local dir="$1" sd skill; sd="$(skills_dir_for "${2:-}")"
  for skill in $PACKAGE_SKILLS; do [ -f "$dir/$sd/$skill/SKILL.md" ] || return 1; done
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
  downgrade_profile_to_031 "$dir"
}
# The profile half only: on Claude, `apm update` has already put 0.4.0 into .claude/skills.
downgrade_profile_to_031(){
  local dir="$1"
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
  all_skills_present "$dir" "$target" && ok "$target: all 19 package skills present in $(skills_dir_for "$target")" || bad "$target: package skills missing"
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
for skill in $PRODUCT_SKILLS; do grep -Eq "new skills: (.*, )?$skill(,|$)" "$WORK/upgrade-031-plan.txt" || missing_new="$missing_new $skill"; done
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
# Skip the review on a 0.3.1 profile without the planning roles, then change one setting explicitly.
RC="$WORK/upgrade-031-rolechange"; cp -R "$WORK/upgrade-031-apply" "$RC"
prepare_planning_role_upgrade "$RC"
(cd "$RC" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --upgrade-review-outcome skipped --skip-apm >/dev/null 2>&1)
(cd "$RC" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --ci external --skip-apm >/dev/null 2>&1)
grep -A1 '"ci"' "$RC/.agent-army/config.json" | grep -q '"mode": "external"' \
  && [ ! -f "$RC/.agent-army/agents/agent-army-planning-analyst.agent" ] \
  && ok "an explicit profile change after a skipped review adds no role" || bad "explicit profile change: setting not applied or a skipped planning role added"
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

printf '\n\033[1mGATE 1.7 · real 0.3.1 Claude install (stale core copy in .agents/skills, 0.4.0 in .claude/skills)\033[0m\n'
PKG031="$WORK/pkg031"; mkdir -p "$PKG031"
if git -C "$ROOT" archive 1e751e6 .apm/skills 2>/dev/null | tar -x -C "$PKG031" 2>/dev/null; then
  C031="$WORK/claude-031"; init_repo "$C031"; mkdir -p "$C031/.agents" "$C031/.claude"
  cp -R "$PKG031/.apm/skills" "$C031/.agents/skills"; cp -R "$ROOT/.apm/skills" "$C031/.claude/skills"
  (cd "$C031" && python3 .agents/skills/bootstrap/bootstrap.py claude --skip-apm --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1)
  grep -q '"version": "0.3.1"' "$C031/.agent-army/config.json" && ok "the real 0.3.1 generator wrote a 0.3.1 profile" || bad "0.3.1 profile not created"
  printf '\n# LOCAL-NEW-AGENT-NOTE\n' >> "$C031/.agents/skills/new-agent/SKILL.md"
  printf 'team notes\n' > "$C031/.agents/skills/ship/team-notes.md"
  python3 - "$PKG031/.apm/skills" "$ROOT/.apm/skills/bootstrap/package-manifests/0.3.1.json" <<'PY'
import hashlib, json, pathlib, sys
root = pathlib.Path(sys.argv[1]); manifest = json.loads(pathlib.Path(sys.argv[2]).read_text())['files']
actual = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file()}
sys.exit(0 if actual == manifest else 1)
PY
  [ $? -eq 0 ] && ok "package-manifests/0.3.1.json matches the 0.3.1 release" || bad "0.3.1 manifest differs from git archive 1e751e6"
  before="$(tree_digest "$C031")"
  (cd "$C031" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --dry-run --skip-apm > "$WORK/claude-031-plan.txt" 2>&1)
  [ "$before" = "$(tree_digest "$C031")" ] && ok "the dry run changes nothing" || bad "the dry run wrote or removed files"
  grep -q '0.3.1 -> 0.4.0' "$WORK/claude-031-plan.txt" && ok "the loaded 0.4.0 generator plans 0.3.1 -> 0.4.0" || bad "no 0.3.1 -> 0.4.0 plan from .claude/skills"
  grep -Eq 'changed skills: (.*, )?bootstrap(,|$)' "$WORK/claude-031-plan.txt" && grep -Eq 'changed skills: (.*, )?ship(,|$)' "$WORK/claude-031-plan.txt" \
    && ok "dry run previews the changed bootstrap and ship" || bad "dry run misses the changed core skills"
  grep -q 'recommended local diff: .*docs-writer.md -> .agent-army/agents/agent-army-docs-writer.agent' "$WORK/claude-031-plan.txt" \
    && ok "dry run recommends the docs-writer merge" || bad "docs-writer recommendation missing for the Claude upgrade"
  grep -q 'plan remove .agents/skills/bootstrap' "$WORK/claude-031-plan.txt" \
    && ok "dry run lists the unmodified stale copy it would remove" || bad "dry run does not plan the stale-copy removal"
  grep -q 'conflict: .*new-agent' "$WORK/claude-031-plan.txt" && ok "a locally changed stale copy is reported as a conflict" || bad "local skill change not reported"
  cp -R "$C031" "$WORK/claude-031-pre"
  (cd "$C031" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --upgrade-review-outcome skipped --skip-apm > "$WORK/claude-031-up.txt" 2>&1)
  [ ! -e "$C031/.agents/skills/bootstrap" ] && [ ! -e "$C031/.agents/skills/adapt-army" ] && [ ! -e "$C031/.agents/skills/new-skill" ] \
    && ok "unmodified 0.3.1 copies in .agents/skills are removed" || bad "unmodified 0.3.1 copies left in .agents/skills"
  grep -q 'LOCAL-NEW-AGENT-NOTE' "$C031/.agents/skills/new-agent/SKILL.md" && ok "the locally changed skill is kept" || bad "a locally changed skill was removed or overwritten"
  [ -f "$C031/.agents/skills/ship/team-notes.md" ] && [ -f "$C031/.agents/skills/ship/SKILL.md" ] \
    && grep -q 'conflict: .*ship' "$WORK/claude-031-up.txt" \
    && ok "a skill dir holding a user file is kept whole and reported" || bad "a skill dir with a user file was removed or not reported"
  all_skills_present "$C031" claude && [ ! -e "$C031/.agents/skills/product" ] \
    && ok "the 19 skills live only in .claude/skills (nothing added to .agents/skills)" || bad "skills missing in .claude/skills or copied to .agents/skills"
  before="$(tree_digest "$C031")"
  (cd "$C031" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --skip-apm > "$WORK/claude-031-next.txt" 2>&1)
  [ "$before" = "$(tree_digest "$C031")" ] && grep -q 'profile is current' "$WORK/claude-031-next.txt" \
    && ok "the next run sees a current profile (kept conflicts alone trigger nothing)" \
    || bad "follow-up run was not a no-op: $(head -1 "$WORK/claude-031-next.txt")"
  # A newer release must still keep the conflict: the recorded inventory is not proof of a package copy.
  C041="$WORK/claude-041"; cp -R "$C031" "$C041"
  sed -i.bak 's/^PACKAGE_VERSION = "0.4.0"/PACKAGE_VERSION = "0.4.1"/' "$C041/.claude/skills/bootstrap/bootstrap.py"; rm -f "$C041/.claude/skills/bootstrap/bootstrap.py.bak"
  printf '\n# 0.4.1 change\n' >> "$C041/.claude/skills/new-agent/SKILL.md"
  (cd "$C041" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --upgrade-review-outcome skipped --skip-apm > "$WORK/claude-041-up.txt" 2>&1)
  grep -q 'LOCAL-NEW-AGENT-NOTE' "$C041/.agents/skills/new-agent/SKILL.md" && grep -q 'conflict: .*new-agent' "$WORK/claude-041-up.txt" \
    && ok "the next release still keeps and reports the local change" || bad "the next release removed a kept local change"
  # Links and the user's own folders are never removed or written through.
  CS="$WORK/claude-031-links"; cp -R "$WORK/claude-031-pre" "$CS"; OUT="$WORK/outside"; mkdir -p "$OUT"
  mv "$CS/.agents/skills/adapt-army" "$OUT/adapt-army"; ln -s "$OUT/adapt-army" "$CS/.agents/skills/adapt-army"
  rm -f "$CS/.agents/skills/ship/team-notes.md"
  mv "$CS/.agents/skills/ship/SKILL.md" "$OUT/ship-SKILL.md"; ln "$OUT/ship-SKILL.md" "$CS/.agents/skills/ship/SKILL.md"
  mkdir -p "$CS/.agents/skills/product"; printf 'my notes\n' > "$CS/.agents/skills/product/notes.md"
  outside_before="$(tree_digest "$OUT")"
  (cd "$CS" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --upgrade-review-outcome skipped --skip-apm > "$WORK/claude-031-links.txt" 2>&1)
  [ "$outside_before" = "$(tree_digest "$OUT")" ] && ok "symlinked and hard-linked files outside the copy are untouched" || bad "a write or removal went through a link"
  [ -L "$CS/.agents/skills/adapt-army" ] && [ -f "$CS/.agents/skills/ship/SKILL.md" ] \
    && grep -q 'conflict: .*adapt-army' "$WORK/claude-031-links.txt" && grep -q 'conflict: .*ship' "$WORK/claude-031-links.txt" \
    && ok "a symlinked skill and a hard-linked file are kept and reported" || bad "linked skills removed or not reported"
  [ -f "$CS/.agents/skills/product/notes.md" ] && [ ! -f "$CS/.agents/skills/product/SKILL.md" ] && grep -q 'conflict: .*product' "$WORK/claude-031-links.txt" \
    && ok "a user folder with a product-skill name is kept, not filled in" || bad "a user folder was removed or filled with package files"
else
  bad "cannot read the 0.3.1 package (git archive 1e751e6); run smoke from a full clone"
fi

printf '\n\033[1mGATE 1.75 · one copy of the skills\033[0m\n'
[ ! -e "$WORK/claude/.agents/skills" ] && all_skills_present "$WORK/claude" claude && [ "$(skill_copies "$WORK/claude")" = 1 ] \
  && ok "fresh Claude bootstrap: one copy in .claude/skills, no .agents/skills" || bad "fresh Claude bootstrap made a second copy or missed .claude/skills"
! grep -qx '.claude/skills/' "$WORK/claude/.gitignore" 2>/dev/null \
  && ok "Claude bootstrap leaves .claude/skills out of .gitignore (the user's own skills live there)" || bad "Claude bootstrap ignores .claude/skills"
grep -q '"product/advisor-contract.md"' "$WORK/claude/.agent-army/config.json" \
  && ok "the package inventory tracks the shared advisor contract" || bad "advisor contract missing from the package inventory"
MIGC="$WORK/cache-migration-claude"; init_repo "$MIGC"
mkdir -p "$MIGC/apm_modules/psrebrny/agent-army/.apm"
cp -R "$ROOT/.apm/skills" "$MIGC/apm_modules/psrebrny/agent-army/.apm/"
(cd "$MIGC" && python3 apm_modules/psrebrny/agent-army/.apm/skills/bootstrap/bootstrap.py claude --runtime-hooks disabled --git-precommit disabled --ci disabled --skip-apm >/dev/null 2>&1)
all_skills_present "$MIGC" claude && [ ! -e "$MIGC/.agents/skills" ] \
  && ok "Claude run from the apm_modules cache fills .claude/skills only" || bad "cache run on Claude missed .claude/skills or made .agents/skills"
for target in codex cursor copilot opencode gemini windsurf; do
  dir="$WORK/$target"
  [ -f "$dir/.agents/skills/bootstrap/SKILL.md" ] && [ "$(skill_copies "$dir")" = 1 ] \
    && ok "$target: exactly one copy, in .agents/skills" || bad "$target: expected one copy in .agents/skills, found $(skill_copies "$dir")"
done
before="$(tree_digest "$WORK/codex/.agents/skills")"
bootstrap "$WORK/codex" codex --mode full >/dev/null 2>&1
[ "$before" = "$(tree_digest "$WORK/codex/.agents/skills")" ] && [ -f "$WORK/codex/.agents/skills/bootstrap/SKILL.md" ] \
  && ok "codex: a full re-bootstrap never touches .agents/skills" || bad "codex: .agents/skills changed on re-bootstrap"
# A 0.4.0 Claude repo: the earlier bootstrap copied .claude/skills to .agents/skills, and its
# router block named .agents/skills (the block every .agents/skills target still writes).
C040="$WORK/claude-040"; init_repo "$C040"
bootstrap "$C040" claude --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1
mkdir -p "$C040/.agents"; cp -R "$C040/.claude/skills" "$C040/.agents/skills" 2>/dev/null
cp "$WORK/codex/AGENTS.md" "$C040/AGENTS.md"
CM="$WORK/claude-040-modified"; cp -R "$C040" "$CM"
before="$(tree_digest "$C040")"
(cd "$C040" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --dry-run --skip-apm > "$WORK/claude-040-plan.txt" 2>&1)
[ "$before" = "$(tree_digest "$C040")" ] && grep -q 'plan remove .agents/skills/ship' "$WORK/claude-040-plan.txt" \
  && ok "0.4.0 Claude: the dry run lists the stale copy and changes nothing" || bad "0.4.0 Claude: dry run wrote files or planned no removal"
(cd "$C040" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --upgrade-review-outcome skipped --skip-apm > "$WORK/claude-040-up.txt" 2>&1)
[ -f "$C040/.claude/skills/bootstrap/SKILL.md" ] && [ ! -e "$C040/.agents/skills" ] && all_skills_present "$C040" claude \
  && ok "0.4.0 Claude: the unmodified .agents/skills copy is removed, .claude/skills stays complete" || bad "0.4.0 Claude: stale copy left or .claude/skills damaged"
grep -q '`.claude/skills/adapt-army/SKILL.md`' "$C040/AGENTS.md" && ! grep -q '\.agents/skills' "$C040/AGENTS.md" \
  && ok "0.4.0 Claude: the managed router block now names .claude/skills" || bad "0.4.0 Claude: router block still names .agents/skills"
before="$(tree_digest "$C040")"
(cd "$C040" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --skip-apm > "$WORK/claude-040-next.txt" 2>&1)
[ "$before" = "$(tree_digest "$C040")" ] && grep -q 'profile is current' "$WORK/claude-040-next.txt" \
  && ok "0.4.0 Claude: the rerun is a no-op" || bad "0.4.0 Claude: rerun was not a no-op: $(head -1 "$WORK/claude-040-next.txt")"
printf '\n# LOCAL-SHIP-NOTE\n' >> "$CM/.agents/skills/ship/SKILL.md"
ship_before="$(tree_digest "$CM/.agents/skills/ship")"
(cd "$CM" && python3 .claude/skills/bootstrap/bootstrap.py claude --mode auto --upgrade-review-outcome skipped --skip-apm > "$WORK/claude-040-mod.txt" 2>&1)
[ -d "$CM/.agents/skills/ship" ] && [ "$ship_before" = "$(tree_digest "$CM/.agents/skills/ship")" ] && grep -q 'conflict: .*ship' "$WORK/claude-040-mod.txt" \
  && ok "0.4.0 Claude: a modified file keeps its whole skill dir and is reported as a conflict" || bad "0.4.0 Claude: modified skill dir removed, changed or not reported"
[ ! -e "$CM/.agents/skills/bootstrap" ] && [ "$(ls "$CM/.agents/skills" 2>/dev/null)" = ship ] \
  && ok "0.4.0 Claude: the unmodified skills beside it are removed" || bad "0.4.0 Claude: unmodified stale skills left beside the conflict"

printf '\n\033[1mGATE 1.8 · Claude upgrade skip through APM keeps native agents\033[0m\n'
if command -v apm >/dev/null 2>&1; then
  CA="$WORK/claude-apm-up"; init_repo "$CA"; install_skills "$CA" claude
  bootstrap_apm "$CA" claude --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1
  rendered="$(find "$CA/.claude/agents" -name 'agent-army-*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$rendered" = 9 ] && ok "fresh Claude install renders nine native agents" || bad "fresh Claude install rendered $rendered agents"
  all_skills_present "$CA" claude && [ ! -e "$CA/.agents/skills" ] && [ "$(skill_copies "$CA")" = 1 ] \
    && ok "fresh Claude install through APM keeps one copy in .claude/skills" || bad "fresh Claude install through APM made a second skills copy"
  downgrade_profile_to_031 "$CA"
  # A 0.3.1 profile without the planning roles: the skipped review must not add them.
  prepare_planning_role_upgrade "$CA"
  rm -f "$CA/.claude/agents/agent-army-planning-analyst.md" "$CA/.claude/agents/agent-army-plan-reviewer.md"
  bootstrap_apm "$CA" claude --mode auto --upgrade-review-outcome skipped >/dev/null 2>&1
  rendered="$(find "$CA/.claude/agents" -name 'agent-army-*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$rendered" = 7 ] && ok "skipped upgrade through APM keeps the seven native agents" || bad "skipped upgrade left $rendered native agents (expected 7)"
  before="$(tree_digest "$CA")"
  bootstrap_apm "$CA" claude --mode auto > "$WORK/claude-apm-next.txt" 2>&1
  [ "$before" = "$(tree_digest "$CA")" ] && grep -q 'profile is current' "$WORK/claude-apm-next.txt" \
    && ok "next Claude run through APM is a no-op" || bad "next Claude run wrote files: $(head -1 "$WORK/claude-apm-next.txt")"
  [ ! -f "$CA/.agent-army/agents/agent-army-planning-analyst.agent" ] && ok "skipped planning roles stay absent" || bad "a skipped planning role was added later"
  [ ! -e "$CA/.agents/skills" ] && all_skills_present "$CA" claude \
    && ok "Claude upgrade through APM still has one copy in .claude/skills" || bad "Claude upgrade through APM left skills outside .claude/skills"
else
  bad "apm not on PATH: the Claude upgrade through APM is not exercised"
fi

printf '\n\033[1mGATE 1.9 · reruns and degraded adapters\033[0m\n'
NOAG="$WORK/no-agents-md"; init_repo "$NOAG"
bootstrap "$NOAG" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1
grep -q 'agent-army:feedback-router:start' "$NOAG/AGENTS.md" && ok "first bootstrap without AGENTS.md adds the managed router block" || bad "no router block after first bootstrap"
(cd "$NOAG" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --skip-apm > "$WORK/no-agents-md-rerun.txt" 2>&1)
[ $? -eq 0 ] && grep -q 'profile is current' "$WORK/no-agents-md-rerun.txt" \
  && ok "a plain rerun after a fresh install is a no-op" || bad "plain rerun demanded a review: $(head -1 "$WORK/no-agents-md-rerun.txt")"
OWNAG="$WORK/own-agents-md"; init_repo "$OWNAG"; printf '# My repo\nMY-RULE\n' > "$OWNAG/AGENTS.md"
bootstrap "$OWNAG" claude --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1
head -2 "$OWNAG/AGENTS.md" | grep -q 'MY-RULE' && [ "$(grep -c 'feedback-router:start' "$OWNAG/AGENTS.md")" = 1 ] \
  && ok "an existing AGENTS.md keeps its content and gets one router block" || bad "existing AGENTS.md changed or router duplicated"
for target in gemini windsurf; do
  DG="$WORK/degraded-$target"; init_repo "$DG"
  bootstrap "$DG" "$target" --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1
  case "$target" in
    gemini) out_arch="$DG/.gemini/agents/agent-army-architect.md"; out_coder="$DG/.gemini/agents/agent-army-coder.md" ;;
    windsurf) out_arch="$DG/.windsurf/skills/agent-army-architect/SKILL.md"; out_coder="$DG/.windsurf/skills/agent-army-coder/SKILL.md" ;;
  esac
  printf '\n# NEW-ARCHITECT-RULE\n' >> "$DG/.agent-army/agents/agent-army-architect.agent"
  printf '\n# NEW-CODER-RULE\n' >> "$DG/.agent-army/agents/agent-army-coder.agent"
  printf '\n# HAND-EDIT\n' >> "$out_coder"
  (cd "$DG" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" "$target" --skip-apm > "$WORK/degraded-$target.txt" 2>&1)
  grep -q 'NEW-ARCHITECT-RULE' "$out_arch" && ok "$target: an edited contract refreshes its unmodified adapter file" || bad "$target: adapter file kept the old text"
  grep -q 'HAND-EDIT' "$out_coder" && ! grep -q 'NEW-CODER-RULE' "$out_coder" && grep -q "kept .*agent-army-coder" "$WORK/degraded-$target.txt" \
    && ok "$target: a hand-edited adapter file is kept and reported" || bad "$target: hand-edited adapter file overwritten or not reported"
  (cd "$DG" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" "$target" --skip-apm > "$WORK/degraded-$target-2.txt" 2>&1)
  grep -q 'profile is current' "$WORK/degraded-$target-2.txt" && ok "$target: the next run is a no-op" || bad "$target: the next run re-rendered again"
done

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
  dir="$WORK/apm-$target"; init_repo "$dir"; install_skills "$dir" "$target"
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
  # Gate 3 copies the skills in itself, so this proves only that the APM pass kept them.
  all_skills_present "$dir" "$target" && ok "$target: APM kept all 19 package skills" || bad "$target: APM pruned package skills"
  [ "$(skill_copies "$dir")" = 1 ] && ok "$target: one deployed skills copy after the APM pass" || bad "$target: $(skill_copies "$dir") deployed skills copies after the APM pass"
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
