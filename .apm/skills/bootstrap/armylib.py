"""Shared, read-only Agent Army facts used by bootstrap.py (writer) and army.py (resolver).

One profile lives in `.agent-army/` and serves every tool. Nothing here knows a target: a tool is
only asked about when a skill dispatches a role (`dispatch`) or picks a model for it.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
BASE = HERE / "baseline"
TOOLS_DIR = BASE / "tools"
PACKAGE_VERSION = "0.5.4"
PROFILE_SCHEMA_VERSION = 3
# Schema versions this package can read (and migrate from).
READABLE_SCHEMA_VERSIONS = {2, PROFILE_SCHEMA_VERSION}
PROFILE_DIR = ".agent-army"
LOCAL_AGENT_SOURCE_DIR = ".agent-army/agents"
LOCAL_AGENT_SUFFIX = ".agent"
ROLES = (
    "architect",
    "coder",
    "tester",
    "code-reviewer",
    "security-auditor",
    "perf-auditor",
    "docs-writer",
    "planning-analyst",
    "plan-reviewer",
)
ROLE_CAPABILITY = {
    "architect": "strong",
    "coder": "mid",
    "tester": "light",
    "code-reviewer": "strong",
    "security-auditor": "strong",
    "perf-auditor": "mid",
    "docs-writer": "light",
    "planning-analyst": "mid",
    "plan-reviewer": "strong",
}
# Claude documents portable tier names; any other tool needs exact model IDs that bootstrap receives
# explicitly rather than inventing them.
DEFAULT_MODEL_TIERS = {"claude": {"light": "haiku", "mid": "sonnet", "strong": "opus"}}
ROLE_MODEL_MARKER = "# agent-army-role-profile:"
# Environment markers set by each tool's shell; only used when a skill does not name its tool.
TOOL_ENV_MARKERS = (("CLAUDECODE", "claude"), ("CODEX_SANDBOX", "codex"), ("CURSOR_AGENT", "cursor"), ("OPENCODE", "opencode"))


def repo_root(cwd: Path | None = None) -> Path:
    start = (cwd or Path.cwd()).resolve()
    found = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=start, text=True, capture_output=True)
    return Path(found.stdout.strip()).resolve() if found.returncode == 0 else start


def read_profile(root: Path) -> dict[str, Any]:
    """The raw `.agent-army/config.json`, or {} when absent, unreadable or of an unknown schema."""
    try:
        profile = json.loads((root / PROFILE_DIR / "config.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(profile, dict) or type(profile.get("version")) is not int:
        return {}
    return profile if profile["version"] in READABLE_SCHEMA_VERSIONS else {}


def descriptor_value(tool: str, section: str, key: str) -> str | None:
    """Read `<section>.<key>` from tools/<tool>.yml (flat two-level YAML; no PyYAML needed)."""
    try:
        lines = (TOOLS_DIR / f"{tool}.yml").read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    inside = False
    for line in lines:
        content = line.split("#", 1)[0].rstrip()
        if not content.strip():
            continue
        if not content[0].isspace():
            inside = content == f"{section}:"
            continue
        match = re.fullmatch(r"\s+" + re.escape(key) + r":\s*(\S+)", content) if inside else None
        if match:
            return match.group(1).strip("'\"")
    return None


def known_tools() -> list[str]:
    return sorted(path.stem for path in TOOLS_DIR.glob("*.yml") if not path.stem.startswith("_"))


def detect_tool(explicit: str | None = None) -> str | None:
    if explicit:
        return explicit
    for variable, tool in TOOL_ENV_MARKERS:
        if os.environ.get(variable):
            return tool
    return None


def dispatch_mode(tool: str | None) -> str:
    """How a skill runs a role in this tool: a generic subagent fed the contract, or the main thread."""
    value = descriptor_value(tool, "capabilities", "dispatch") if tool else None
    return value or descriptor_value("_default", "capabilities", "dispatch") or "main-thread"


def model_capable(tool: str | None) -> bool:
    """Only a subagent call can carry a per-role model; a main-thread role keeps the session model."""
    return dispatch_mode(tool) == "subagent-with-prompt"


def split_frontmatter(text: str) -> tuple[str, str] | None:
    parts = text.split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        return None
    return parts[1], parts[2]


def frontmatter_model(text: str) -> tuple[str | None, bool]:
    """(model value, generated?) of a role contract's `model:` line, if it has one."""
    split = split_frontmatter(text)
    if split is None:
        return None, False
    match = re.search(r"^model:\s*(.*?)(?:\s+#.*)?$", split[0], flags=re.MULTILINE)
    if not match:
        return None, False
    value = match.group(1).strip()
    if value.startswith('"'):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            pass
    return value or None, ROLE_MODEL_MARKER in match.group(0)


def contract_path(root: Path, role: str) -> Path:
    return root / LOCAL_AGENT_SOURCE_DIR / f"agent-army-{role}{LOCAL_AGENT_SUFFIX}"


def baseline_contract_path(role: str) -> Path:
    return BASE / "core/agents" / f"{role}.md"


def local_roles(root: Path) -> list[str]:
    """Every role the repo defines: the shipped roster plus roles authored with /new-agent."""
    source = root / LOCAL_AGENT_SOURCE_DIR
    found = {path.name[len("agent-army-"):-len(LOCAL_AGENT_SUFFIX)] for path in source.glob(f"agent-army-*{LOCAL_AGENT_SUFFIX}")}
    return sorted(found, key=lambda role: (ROLES.index(role) if role in ROLES else len(ROLES), role))


def fill_placeholders(text: str) -> str:
    return text.replace("<AGENTS_DIR>", LOCAL_AGENT_SOURCE_DIR).replace("<TOOL_DIR>", PROFILE_DIR)


def tool_tiers(profile: dict[str, Any], tool: str | None) -> dict[str, str]:
    """light/mid/strong model IDs bootstrap recorded for this tool; {} means inherit."""
    routing = profile.get("model_routing") if isinstance(profile.get("model_routing"), dict) else {}
    if not tool or routing.get("strategy") == "inherit":
        return {}
    tools = routing.get("tools")
    if isinstance(tools, dict):
        tiers = tools.get(tool)
        return dict(tiers) if isinstance(tiers, dict) else {}
    # Schema v2 recorded one target's tiers.
    if routing.get("target") == tool and isinstance(routing.get("tiers"), dict):
        return dict(routing["tiers"])
    return {}
