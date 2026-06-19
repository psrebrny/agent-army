#!/usr/bin/env bash
# Detects the project stack and sets FMT_CMD / LINT_CMD / TEST_CMD.
# Sourced by the other hooks. Universal — works in any repo.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || true
FMT_CMD=""; LINT_CMD=""; TEST_CMD=""

_pm() {
  if command -v pnpm >/dev/null 2>&1; then echo pnpm
  elif command -v yarn >/dev/null 2>&1; then echo yarn
  else echo npm; fi
}

if [ -f package.json ]; then
  PM="$(_pm)"
  grep -q '"format"' package.json 2>/dev/null && FMT_CMD="$PM run format"
  grep -q '"lint"'   package.json 2>/dev/null && LINT_CMD="$PM run lint"
  grep -q '"test"'   package.json 2>/dev/null && TEST_CMD="$PM test"
fi
if [ -f pyproject.toml ] || [ -f requirements.txt ] || ls ./*.py >/dev/null 2>&1; then
  command -v ruff   >/dev/null 2>&1 && { FMT_CMD="${FMT_CMD:-ruff format .}"; LINT_CMD="${LINT_CMD:-ruff check .}"; }
  command -v pytest >/dev/null 2>&1 && TEST_CMD="${TEST_CMD:-pytest -q}"
fi
if [ -f go.mod ]; then
  FMT_CMD="${FMT_CMD:-gofmt -w .}"; TEST_CMD="${TEST_CMD:-go test ./...}"
fi
if [ -f Cargo.toml ]; then
  FMT_CMD="${FMT_CMD:-cargo fmt}"; LINT_CMD="${LINT_CMD:-cargo clippy -q}"; TEST_CMD="${TEST_CMD:-cargo test -q}"
fi

# Project policy (.claude/army.conf) — relaxes QUALITY rigor only; security barriers are separate.
# Absent file → defaults (strict tests, lint on), so existing installs are unchanged.
CONF="$ROOT/.claude/army.conf"
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"
case "${TEST_POLICY:-strict}" in none) TEST_CMD="" ;; esac   # 'none' → no test gate
case "${LINT_POLICY:-on}"     in off)  LINT_CMD="" ;; esac   # 'off'  → no lint gate

export FMT_CMD LINT_CMD TEST_CMD TEST_POLICY LINT_POLICY CI_MODE
