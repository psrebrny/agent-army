#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/detect.sh"
fail=0
# Make a relaxed policy LOUD, never silent (so an exception can't quietly go stale).
[ "${TEST_POLICY:-strict}" = none ] && echo "verify> TEST_POLICY=none — tests NOT enforced (project policy, .claude/army.conf)"
[ "${LINT_POLICY:-on}" = off ]      && echo "verify> LINT_POLICY=off — lint NOT enforced (project policy, .claude/army.conf)"
if [ -n "$LINT_CMD" ]; then echo "verify> lint: $LINT_CMD"; eval "$LINT_CMD" || fail=1; fi
if [ -n "$TEST_CMD" ]; then echo "verify> test: $TEST_CMD"; eval "$TEST_CMD" || fail=1; fi
[ -z "$LINT_CMD$TEST_CMD" ] && echo "verify> no checks detected (skipping)"
exit $fail
