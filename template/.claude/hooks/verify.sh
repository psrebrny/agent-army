#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/detect.sh"
fail=0
if [ -n "$LINT_CMD" ]; then echo "verify> lint: $LINT_CMD"; eval "$LINT_CMD" || fail=1; fi
if [ -n "$TEST_CMD" ]; then echo "verify> test: $TEST_CMD"; eval "$TEST_CMD" || fail=1; fi
[ -z "$LINT_CMD$TEST_CMD" ] && echo "verify> brak wykrytych checków (pomijam)"
exit $fail
