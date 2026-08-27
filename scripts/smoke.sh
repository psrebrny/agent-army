#!/usr/bin/env bash
# Deterministic v0.3 smoke tests.  They intentionally exercise the generator
# without APM network/install state; the generator itself owns the frozen APM
# handoff in normal bootstrap mode.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
need(){ "$@" >/dev/null 2>&1 && ok "$2" || bad "$2"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-army-v2.XXXXXX")"
cleanup(){ rm -rf "$WORK"; }
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

printf '\n\033[1mGATE 0 · profile generation for every target\033[0m\n'
for target in claude codex cursor copilot opencode gemini windsurf; do
  dir="$WORK/$target"; init_repo "$dir"
  bootstrap "$dir" "$target" --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
  if [ "$target" = windsurf ]; then
    [ -f "$dir/.windsurf/skills/agent-army-architect/SKILL.md" ] && ok "$target: role-skills fallback" || bad "$target: fallback role missing"
  else
    count="$(find "$dir/.apm/agents" -name 'agent-army-*.agent.md' 2>/dev/null | wc -l | tr -d ' ')"
    [ "$count" = 7 ] && ok "$target: seven local APM agent sources" || bad "$target: expected seven agent sources, got $count"
  fi
  "$ROOT/scripts/check.sh" --target-dir "$dir" >/dev/null 2>&1 && ok "$target: profile validates" || bad "$target: profile validation failed"
done

MIG="$WORK/cache-migration"; init_repo "$MIG"
mkdir -p "$MIG/apm_modules/psrebrny/agent-army/.apm"
cp -R "$ROOT/.apm/skills" "$MIG/apm_modules/psrebrny/agent-army/.apm/"
(cd "$MIG" && python3 apm_modules/psrebrny/agent-army/.apm/skills/bootstrap/bootstrap.py opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null 2>&1)
[ -f "$MIG/.agents/skills/ship/SKILL.md" ] && [ -f "$MIG/.agents/skills/new-skill/SKILL.md" ] \
  && ok "cache migration: all skills materialized to .agents/skills" || bad "cache migration: skills not materialized"
[ -f "$MIG/.opencode/agents/agent-army-architect.md" ] && ok "cache migration: native agents rendered" || bad "cache migration: native agents missing"

LEGACY="$WORK/legacy-model"; init_repo "$LEGACY"
bootstrap "$LEGACY" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
sed -i.bak '3i\
model: user-owned/custom-model' "$LEGACY/.apm/agents/agent-army-architect.agent.md"; rm -f "$LEGACY/.apm/agents/agent-army-architect.agent.md.bak"
bootstrap "$LEGACY" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --model-light test/light --model-mid test/mid --model-strong test/strong >/dev/null
if grep -q '^model: user-owned/custom-model$' "$LEGACY/.apm/agents/agent-army-architect.agent.md"; then
  ok "user-owned role model preserved on re-bootstrap"
else
  bad "user-owned role model was overwritten"
fi
grep -A4 '"architect"' "$LEGACY/.agent-army/config.json" | grep -q '"source": "user-override"' \
  && ok "user-owned role override recorded" || bad "user-owned role override not recorded"

ROUTED="$WORK/role-routing"; init_repo "$ROUTED"
bootstrap "$ROUTED" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --model-light test/light-v1 --model-mid test/mid-v1 --model-strong test/strong-v1 >/dev/null
grep -q '^model: "test/strong-v1" # agent-army-role-profile: strong$' "$ROUTED/.apm/agents/agent-army-architect.agent.md" \
  && grep -q '^model: "test/light-v1" # agent-army-role-profile: light$' "$ROUTED/.apm/agents/agent-army-tester.agent.md" \
  && ok "exact target model IDs route by role" || bad "role model routing missing or wrong"
bootstrap "$ROUTED" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --model-light test/light-v2 --model-mid test/mid-v2 --model-strong test/strong-v2 >/dev/null
grep -q '^model: "test/strong-v2" # agent-army-role-profile: strong$' "$ROUTED/.apm/agents/agent-army-architect.agent.md" \
  && ok "generated role model updated on re-bootstrap" || bad "generated role model did not update"
grep -q '"strategy": "per_role_static"' "$ROUTED/.agent-army/config.json" \
  && ok "role model routing recorded" || bad "role model routing not recorded"
bootstrap "$ROUTED" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled \
  --role-model-routing inherit >/dev/null
if grep -q '^model:' "$ROUTED/.apm/agents/agent-army-architect.agent.md"; then
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
printf '\nSMOKE-SPECIALIZATION\n' >> "$OWN/.apm/agents/agent-army-architect.agent.md"
bootstrap "$OWN" claude >/dev/null
grep -q 'SMOKE-SPECIALIZATION' "$OWN/.apm/agents/agent-army-architect.agent.md" && ok "re-bootstrap preserves specialized agent source" || bad "re-bootstrap overwrote specialized agent source"
grep -q '"mode": "external"' "$OWN/.agent-army/config.json" && ok "re-bootstrap preserves ownership choice" || bad "re-bootstrap changed ownership choice"

BLOCK="$WORK/blocked"; init_repo "$BLOCK"
mkdir -p "$BLOCK/.git/hooks"; printf '#!/usr/bin/env node\n' > "$BLOCK/.git/hooks/pre-commit"; chmod +x "$BLOCK/.git/hooks/pre-commit"
bootstrap "$BLOCK" codex --runtime-hooks disabled --git-precommit army --ci disabled >/dev/null
grep -A2 'git_precommit' "$BLOCK/.agent-army/config.json" | grep -q blocked && ok "unsafe hook replacement blocked" || bad "unsafe hook replacement was not blocked"

printf '\n\033[1mGATE 1.5 · incremental package migration\033[0m\n'
UPGRADE="$WORK/upgrade"; init_repo "$UPGRADE"
bootstrap "$UPGRADE" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
printf '# Existing repo specialization\n' > "$UPGRADE/AGENTS.md"
printf '\n# MIGRATION-SPECIALIZATION\n' >> "$UPGRADE/.apm/agents/agent-army-architect.agent.md"
sed -i.bak '/^[[:space:]]*"package": {$/,/^[[:space:]]*},$/d' "$UPGRADE/.agent-army/config.json"; rm -f "$UPGRADE/.agent-army/config.json.bak"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --dry-run --skip-apm > "$WORK/upgrade-plan.txt")
grep -q '0.2.0 -> 0.3.0' "$WORK/upgrade-plan.txt" && ok "legacy v0.2 profile gets an incremental plan" || bad "legacy migration plan missing"
grep -q 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md" && bad "incremental dry-run changed AGENTS.md" || ok "incremental dry-run preserves AGENTS.md"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm >/dev/null)
grep -q 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md" && ok "incremental migration adds managed feedback router" || bad "feedback router missing after migration"
grep -q '"version": "0.3.0"' "$UPGRADE/.agent-army/config.json" && ok "incremental migration records package version" || bad "package version not recorded"
grep -q 'MIGRATION-SPECIALIZATION' "$UPGRADE/.apm/agents/agent-army-architect.agent.md" && ok "incremental migration preserves specialized agent" || bad "incremental migration overwrote specialized agent"
count="$(grep -c 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md")"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm >/dev/null)
[ "$count" = "$(grep -c 'agent-army:feedback-router:start' "$UPGRADE/AGENTS.md")" ] && ok "incremental migration is idempotent" || bad "incremental migration duplicated managed block"
mkdir -p "$UPGRADE/.agent-army/overrides/skills"; printf 'local /ship guidance\n' > "$UPGRADE/.agent-army/overrides/skills/ship.md"
(cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm >/dev/null)
[ -f "$UPGRADE/.agent-army/overrides/skills/ship.md" ] && ok "local skill overlay survives bootstrap" || bad "local skill overlay was removed"

CONFLICT="$WORK/migration-conflict"; init_repo "$CONFLICT"
bootstrap "$CONFLICT" opencode --runtime-hooks disabled --git-precommit disabled --ci disabled >/dev/null
printf '<!-- agent-army:feedback-router:start -->\nuser edit\n<!-- agent-army:feedback-router:end -->\n' > "$CONFLICT/AGENTS.md"
sed -i.bak '/^[[:space:]]*"package": {$/,/^[[:space:]]*},$/d' "$CONFLICT/.agent-army/config.json"; rm -f "$CONFLICT/.agent-army/config.json.bak"
if (cd "$CONFLICT" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode incremental --skip-apm) >/dev/null 2>&1; then
  bad "modified managed block was overwritten"
else
  ok "modified managed block blocks incremental migration"
fi
grep -q '"package"' "$CONFLICT/.agent-army/config.json" && bad "conflicting migration rewrote config" || ok "conflicting migration preserves config"
if (cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" codex --mode auto --skip-apm) >/dev/null 2>&1; then
  bad "target switch bypassed full bootstrap"
else
  ok "target switch requires full bootstrap"
fi
sed -i.bak 's/"version": "0.3.0"/"version": "9.0.0"/' "$UPGRADE/.agent-army/config.json"; rm -f "$UPGRADE/.agent-army/config.json.bak"
if (cd "$UPGRADE" && python3 "$ROOT/.apm/skills/bootstrap/bootstrap.py" opencode --mode auto --skip-apm) >/dev/null 2>&1; then
  bad "newer profile downgrade was allowed"
else
  ok "newer profile downgrade is blocked"
fi

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
    cursor|opencode)
      render_args=(--model-light test/light --model-mid test/mid --model-strong test/strong)
      ;;
    *) render_args=(--role-model-routing auto) ;;
  esac
  if ! bootstrap_apm "$dir" "$target" --runtime-hooks disabled --git-precommit disabled --ci disabled "${render_args[@]}" >/dev/null; then
    bad "$target: frozen APM rendering failed"; continue
  fi
  case "$target" in
    claude) agent="$dir/.claude/agents/agent-army-architect.md" ;;
    codex) agent="$dir/.codex/agents/agent-army-architect.toml" ;;
    cursor) agent="$dir/.cursor/agents/agent-army-architect.md" ;;
    copilot) agent="$dir/.github/agents/agent-army-architect.agent.md" ;;
    opencode) agent="$dir/.opencode/agents/agent-army-architect.md" ;;
    gemini) agent="$dir/.gemini/agents/agent-army-architect.md" ;;
    windsurf) agent="$dir/.windsurf/skills/agent-army-architect/SKILL.md" ;;
  esac
  [ -f "$dir/.agents/skills/ship/SKILL.md" ] && [ -f "$dir/.agents/skills/new-skill/SKILL.md" ] \
    && ok "$target: five shared skills present" || bad "$target: shared skills missing"
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
