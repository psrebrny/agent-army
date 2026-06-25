#!/usr/bin/env bash
cat >/dev/null 2>&1
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/detect.sh"
[ -n "$FMT_CMD" ] && eval "$FMT_CMD" >/dev/null 2>&1
exit 0
