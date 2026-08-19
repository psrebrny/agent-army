#!/usr/bin/env bash
# A runtime feedback gate. It intentionally reports failure once; a tool may
# choose to finish after receiving that feedback, so CI/pre-commit are the hard
# repository controls when their ownership is Agent Army.
set -euo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
exec python3 "$ROOT/.agent-army/runtime.py" gate
