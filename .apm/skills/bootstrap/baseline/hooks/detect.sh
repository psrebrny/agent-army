#!/usr/bin/env bash
# Compatibility shim. Commands are structured in .agent-army/config.json;
# this file no longer sources project configuration or evaluates shell strings.
set -euo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export AGENT_ARMY_CONFIG="$ROOT/.agent-army/config.json"
