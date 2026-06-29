#!/usr/bin/env bash
# smoke.sh — e2e smoke test for the `bootstrap` skill.
#
# Like a Playwright/Cypress run, except the "app under test" is the bootstrap skill
# driven headlessly by `claude -p`. Flow:
#   1. copy a fixture repo (tests/fixtures/<name>) to a temp dir + git init
#   2. install the army hermetically (source .apm/skills -> <work>/.claude/skills)
#   3. run the bootstrap skill headless in BOOTSTRAP_MODE=auto
#   4. GATE A (deterministic, zero-LLM): check.sh on the GENERATED agents + grep the
#      fixture's planted facts (see tests/fixtures/README.md)
#   5. GATE B (optional, --judge): an LLM scores each agent on internalization/evidence/variety
#
# Usage:
#   scripts/smoke.sh                       # fixture py-monorepo, deterministic gate only
#   scripts/smoke.sh --judge               # also run the LLM judge
#   scripts/smoke.sh --fixture py-monorepo --keep
#   scripts/smoke.sh --work <dir> --no-bootstrap   # re-run assertions on an existing run
#   scripts/smoke.sh --setup-only          # just build the work dir + install, print path
#
# Env: SMOKE_TIMEOUT (default 1800s)  SMOKE_MODEL (claude model for bootstrap)
#      SMOKE_JUDGE_MODEL (claude model for the judge)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FIXTURE="py-monorepo"; JUDGE=0; KEEP=0; RUN_BOOTSTRAP=1; SETUP_ONLY=0; WORK=""
while [ $# -gt 0 ]; do
  case "$1" in
    --fixture) FIXTURE="${2:?}"; shift 2 ;;
    --judge) JUDGE=1; shift ;;
    --keep) KEEP=1; shift ;;
    --work) WORK="${2:?}"; shift 2 ;;
    --no-bootstrap) RUN_BOOTSTRAP=0; shift ;;
    --setup-only) SETUP_ONLY=1; shift ;;
    -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

FIXTURE_DIR="$ROOT/tests/fixtures/$FIXTURE"
[ -d "$FIXTURE_DIR" ] || { echo "no such fixture: $FIXTURE_DIR" >&2; exit 2; }

bold(){ printf '\n\033[1m%s\033[0m\n' "$1"; }
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '  \033[31m✗ %s\033[0m\n' "$1"; FAIL=$((FAIL+1)); }
PASS=0; FAIL=0

# --- 1+2. setup work dir + hermetic install --------------------------------
if [ -z "$WORK" ]; then
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/army-smoke.XXXXXX")"
fi
AGENTS_OUT="$WORK/.claude/agents"

if [ "$RUN_BOOTSTRAP" = 1 ] || [ "$SETUP_ONLY" = 1 ]; then
  bold "Setup → $WORK"
  rm -rf "$WORK"; mkdir -p "$WORK"
  cp -R "$FIXTURE_DIR/." "$WORK/"
  ( cd "$WORK" && git init -q && git add -A && git -c user.email=smoke@test -c user.name=smoke commit -qm "fixture" )
  mkdir -p "$WORK/.claude"
  cp -R "$ROOT/.apm/skills" "$WORK/.claude/skills"
  echo "  fixture=$FIXTURE  skills installed to .claude/skills"
fi

if [ "$SETUP_ONLY" = 1 ]; then
  echo "WORK=$WORK"; exit 0
fi

# --- 3. run the bootstrap skill headless ------------------------------------
if [ "$RUN_BOOTSTRAP" = 1 ]; then
  bold "Run bootstrap skill (headless)"
  command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 2; }
  PROMPT="Invoke the bootstrap skill (.claude/skills/bootstrap/SKILL.md) to materialize and \
tailor the agent team for THIS repository. Run in BOOTSTRAP_MODE=auto: do NOT pause at any \
gate, do NOT ask me any questions. This repo uses Claude Code — materialize into .claude/. \
Use strict defaults (TEST_POLICY=strict, LINT_POLICY=on) and the default model tiers. \
Discover every stack and every nested AGENTS.md, author the agents, write army.conf and \
AGENTS.md, then stop. Do not git commit."
  LOG="$WORK/.smoke-bootstrap.log"
  MODEL_ARG=(); [ -n "${SMOKE_MODEL:-}" ] && MODEL_ARG=(--model "$SMOKE_MODEL")
  RUNNER=(claude -p "$PROMPT" --permission-mode bypassPermissions "${MODEL_ARG[@]}")
  command -v timeout >/dev/null && RUNNER=(timeout "${SMOKE_TIMEOUT:-1800}" "${RUNNER[@]}")
  echo "  logging to $LOG"
  ( cd "$WORK" && "${RUNNER[@]}" ) >"$LOG" 2>&1
  rc=$?
  [ $rc -eq 0 ] && echo "  bootstrap run exited 0" || echo "  ⚠ bootstrap run exited $rc (see $LOG) — continuing to assertions"
fi

# --- 4. GATE A: deterministic assertions on the GENERATED output ------------
bold "GATE A · structure (check.sh on generated agents)"
if [ -d "$AGENTS_OUT" ] && ls "$AGENTS_OUT"/*.md >/dev/null 2>&1; then
  if "$ROOT/scripts/check.sh" --target-dir "$WORK/.claude" >/dev/null 2>&1; then
    ok "check.sh passed on generated .claude/agents"
  else
    bad "check.sh FAILED on generated agents (run: scripts/check.sh --target-dir $WORK/.claude)"
  fi
else
  bad "no generated agents at $AGENTS_OUT — bootstrap did not produce a team"
fi

bold "GATE A · planted facts ($FIXTURE)"
A="$AGENTS_OUT"
have(){ ls "$1" >/dev/null 2>&1; }   # file exists
gci(){ grep -liE "$2" "$1" >/dev/null 2>&1; }  # case-insensitive grep, file(s) glob in $1

if [ "$FIXTURE" = "py-monorepo" ]; then
  # #1 repository law surfaced in architect + code-reviewer
  if have "$A/architect.md" && gci "$A/architect.md" 'repositor'; then ok "#1 repository law in architect"; else bad "#1 repository law MISSING in architect"; fi
  if have "$A/code-reviewer.md" && gci "$A/code-reviewer.md" 'repositor'; then ok "#1 repository law in code-reviewer"; else bad "#1 repository law MISSING in code-reviewer"; fi
  # #2 nested frontend/AGENTS.md discovered -> "primitive" law lands somewhere
  if gci "$A/*.md" 'primitive'; then ok "#2 nested frontend/AGENTS.md discovered (design-system 'primitive' law present)"; else bad "#2 nested frontend/AGENTS.md MISSED (no 'primitive' law) — the known regression"; fi
  # #3 pytest in tester + army.conf
  if have "$A/tester.md" && gci "$A/tester.md" 'pytest'; then ok "#3 pytest wired in tester"; else bad "#3 pytest MISSING in tester"; fi
  if gci "$WORK/.claude/army.conf" 'pytest' || gci "$WORK/army.conf" 'pytest'; then ok "#3 pytest in army.conf TEST_CMD"; else bad "#3 pytest MISSING in army.conf"; fi
  # #4 vitest wired somewhere (monorepo chaining)
  if gci "$A/*.md" 'vitest' || gci "$WORK/.claude/army.conf" 'vitest' || gci "$WORK/AGENTS.md" 'vitest'; then ok "#4 vitest wired (frontend stack)"; else bad "#4 vitest MISSING (frontend stack dropped)"; fi
  # #6 both stacks named in generated AGENTS.md
  if gci "$WORK/AGENTS.md" 'python' && gci "$WORK/AGENTS.md" 'typescript|react|vitest|tsx'; then ok "#6 both stacks named in AGENTS.md"; else bad "#6 AGENTS.md does not name both stacks"; fi
else
  echo "  (no planted-fact assertions defined for fixture '$FIXTURE')"
fi

# --- 5. GATE B: LLM judge (optional) ----------------------------------------
if [ "$JUDGE" = 1 ]; then
  bold "GATE B · LLM judge (rubric: tests/judge/rubric.md)"
  RUBRIC="$(cat "$ROOT/tests/judge/rubric.md")"
  FACTS="$(cat "$ROOT/tests/fixtures/README.md")"
  JMODEL=(); [ -n "${SMOKE_JUDGE_MODEL:-}" ] && JMODEL=(--model "$SMOKE_JUDGE_MODEL")
  for agent in architect tester code-reviewer security-auditor perf-auditor; do
    f="$A/$agent.md"
    [ -f "$f" ] || { bad "judge: $agent.md not generated"; continue; }
    out="$( { printf '%s\n\n## PLANTED FACTS\n%s\n\n## AGENT FILE (%s)\n' "$RUBRIC" "$FACTS" "$agent"; cat "$f"; } \
            | claude -p "${JMODEL[@]}" 2>/dev/null )"
    verdict="$(printf '%s' "$out" | grep -oE '"verdict"[[:space:]]*:[[:space:]]*"(PASS|FAIL)"' | grep -oE 'PASS|FAIL' | head -1)"
    scores="$(printf '%s' "$out" | grep -oE '"(internalization|evidence|variety)"[[:space:]]*:[[:space:]]*[0-9]' | tr '\n' ' ')"
    if [ "$verdict" = "PASS" ]; then ok "judge $agent → PASS  [$scores]"; else bad "judge $agent → ${verdict:-NO-VERDICT}  [$scores]"; fi
  done
fi

# --- report -----------------------------------------------------------------
bold "Result: $PASS passed, $FAIL failed"
if [ "$KEEP" = 1 ] || [ "$FAIL" -gt 0 ]; then
  echo "  work dir kept: $WORK"
else
  rm -rf "$WORK"
fi
[ "$FAIL" -eq 0 ]
