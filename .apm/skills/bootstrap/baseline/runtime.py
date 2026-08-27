#!/usr/bin/env python3
"""Runtime side of Agent Army profile schema v2 (package 0.3.0).

Commands are read from .agent-army/config.json as {cwd, argv}; no project
configuration is sourced as shell and no command is passed through a shell.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(os.environ.get("CLAUDE_PROJECT_DIR") or subprocess.run(["git", "rev-parse", "--show-toplevel"], text=True, capture_output=True).stdout.strip() or Path.cwd()).resolve()
CONFIG = ROOT / ".agent-army/config.json"
SECRET_FILE = re.compile(r"(^|/)(\.env(?:\.|$)|[^/]+\.(?:pem|key)$|id_rsa|secrets?\.)", re.I)
SECRET_VALUE = re.compile(r"(?:AKIA[0-9A-Z]{16}|aws_secret_access_key\s*[=:]|-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|(?:api[_-]?key|secret|token|password)\s*[=:]\s*['\"][^'\"]{8,})", re.I)
DANGEROUS = re.compile(r"(?:\brm\s+-rf\s+(?:/|~|\*)|\bmkfs\b|\bdd\s+if=|>\s*/dev/sd|\bchmod\s+-R\s+777\s+/|\bcurl\b[^|]*\|\s*(?:sudo\s+)?(?:ba)?sh|\bgit\s+push\b.*--force\b)", re.I)
REDIRECT = re.compile(r"(?:>|>>|tee(?:\s+-a)?)\s*([^\s;|&]+)")


def config() -> dict[str, Any]:
    try:
        data = json.loads(CONFIG.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def deny(message: str) -> int:
    # Claude accepts this protocol; other runtimes still see stderr + nonzero.
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "additionalContext": message}}))
    print(message, file=sys.stderr)
    return 2


def command_writes_protected(command: str) -> bool:
    return any(SECRET_FILE.search(match.group(1).strip("'\"")) for match in REDIRECT.finditer(command))


def guard() -> int:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        payload = {}
    tool = payload.get("tool_name", "") if isinstance(payload, dict) else ""
    inputs = (payload.get("tool_input") or payload.get("inputs") or {}) if isinstance(payload, dict) else {}
    path = str(inputs.get("file_path") or inputs.get("path") or "")
    command = str(inputs.get("command") or "")
    if tool in {"Edit", "Write", "MultiEdit"} and SECRET_FILE.search(path):
        return deny(f"Agent Army: protected file edit blocked: {path}")
    if command and command_writes_protected(command):
        return deny("Agent Army: shell write to a protected file blocked")
    if command and DANGEROUS.search(command):
        return deny("Agent Army: dangerous command blocked")
    return 0


def valid_job(job: Any) -> tuple[Path, list[str]] | None:
    if not isinstance(job, dict) or not isinstance(job.get("cwd"), str) or not isinstance(job.get("argv"), list):
        return None
    argv = job["argv"]
    if not argv or not all(isinstance(item, str) and item for item in argv):
        return None
    cwd = (ROOT / job["cwd"]).resolve()
    if ROOT != cwd and ROOT not in cwd.parents:
        return None
    return cwd, argv


def run_quality(names: tuple[str, ...]) -> int:
    jobs = config().get("quality", {})
    failed = False
    ran = False
    for name in names:
        parsed = valid_job(jobs.get(name) if isinstance(jobs, dict) else None)
        if parsed is None:
            continue
        cwd, argv = parsed
        ran = True
        print("agent-army %s> %s" % (name, " ".join(argv)))
        try:
            result = subprocess.run(argv, cwd=cwd)
        except OSError as error:
            print(f"agent-army {name}> {error}", file=sys.stderr)
            failed = True
        else:
            failed |= result.returncode != 0
    if not ran:
        print("agent-army: no configured quality commands", file=sys.stderr)
        return 1
    return 1 if failed else 0


def precommit() -> int:
    staged = subprocess.run(["git", "diff", "--cached", "--name-only", "-z"], cwd=ROOT, capture_output=True).stdout.split(b"\0")
    for raw_path in filter(None, staged):
        path = raw_path.decode("utf-8", "replace")
        if SECRET_FILE.search(path):
            print(f"agent-army: protected staged file rejected: {path}", file=sys.stderr)
            return 1
    diff = subprocess.run(["git", "diff", "--cached", "--no-color", "--unified=0"], cwd=ROOT, text=True, capture_output=True).stdout
    added = "\n".join(line[1:] for line in diff.splitlines() if line.startswith("+") and not line.startswith("+++"))
    if SECRET_VALUE.search(added):
        print("agent-army: staged diff appears to contain a secret", file=sys.stderr)
        return 1
    return run_quality(("lint", "test"))


def main() -> int:
    action = sys.argv[1] if len(sys.argv) == 2 else ""
    if action == "guard": return guard()
    if action == "format": return run_quality(("format",))
    if action in {"verify", "gate"}: return run_quality(("lint", "test"))
    if action == "precommit": return precommit()
    print("usage: runtime.py guard|format|verify|gate|precommit", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
