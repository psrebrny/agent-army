#!/usr/bin/env python3
"""Locate the Agent Army profile of the repository a skill was invoked from.

Skills are installed once (globally or per repo) and stay generic; everything repo-specific lives
in `.agent-army/`. A skill runs this file relative to itself (`../bootstrap/army.py`) to find:

  army.py locate [--cwd DIR] [--tool TOOL]   JSON: repo root, profile, roles, dispatch mode
  army.py role NAME [--cwd DIR]              the role contract to hand to a subagent or main thread

Read-only: it never writes, never runs project commands and never renders native agent files.
A repository without a profile resolves to the package's baseline roles (`profile: "baseline"`).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
import armylib as lib  # noqa: E402


def resolve_role(root: Path, profile: dict[str, Any], role: str, tool: str | None) -> dict[str, Any] | None:
    local = lib.contract_path(root, role)
    if profile and local.is_file():
        path, source = local, "specialized"
    elif lib.baseline_contract_path(role).is_file():
        path, source = lib.baseline_contract_path(role), "baseline"
    else:
        return None
    text = path.read_text(encoding="utf-8")
    capability = lib.ROLE_CAPABILITY.get(role, "mid")
    model, generated = lib.frontmatter_model(text)
    if model and not generated:
        model_source = "user-override"
    else:
        tiers = lib.tool_tiers(profile, tool) if profile else dict(lib.DEFAULT_MODEL_TIERS.get(tool or "", {}))
        model = tiers.get(capability)
        model_source = "profile" if model and profile else ("package-default" if model else "inherit")
    return {
        "contract_path": str(path),
        "source": source,
        "capability": capability,
        "model": model,
        "model_source": model_source,
    }


def locate(cwd: Path, tool: str | None) -> dict[str, Any]:
    root = lib.repo_root(cwd)
    profile = lib.read_profile(root)
    package = profile.get("package") if isinstance(profile.get("package"), dict) else {}
    roles = list(lib.ROLES)
    if profile:
        roles += [role for role in lib.local_roles(root) if role not in roles]
    resolved = {role: resolve_role(root, profile, role, tool) for role in roles}
    stores = root / lib.PROFILE_DIR / "stores.json"
    return {
        "repo_root": str(root),
        "profile": "specialized" if profile else "baseline",
        "profile_version": profile.get("version"),
        "profile_package_version": package.get("version"),
        "package_version": lib.PACKAGE_VERSION,
        "upgrade_pending": bool(profile) and package.get("version") != lib.PACKAGE_VERSION,
        "tool": tool,
        "dispatch": lib.dispatch_mode(tool),
        "roles": {role: info for role, info in resolved.items() if info},
        "agents_md": str(root / "AGENTS.md") if (root / "AGENTS.md").is_file() else None,
        "stores": str(stores) if stores.is_file() else None,
        "quality": profile.get("quality") if isinstance(profile.get("quality"), dict) else None,
        "bootstrap": None if profile else str(lib.HERE / "SKILL.md"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    find = sub.add_parser("locate", help="print the resolved profile as JSON")
    find.add_argument("--cwd", type=Path, default=Path.cwd())
    find.add_argument("--tool", help="the tool running this skill, e.g. claude; detected from the environment if omitted")
    show = sub.add_parser("role", help="print one role contract with placeholders resolved")
    show.add_argument("name")
    show.add_argument("--cwd", type=Path, default=Path.cwd())
    args = parser.parse_args()

    if args.command == "locate":
        print(json.dumps(locate(args.cwd, lib.detect_tool(args.tool)), indent=2))
        return 0
    root = lib.repo_root(args.cwd)
    info = resolve_role(root, lib.read_profile(root), args.name, None)
    if info is None:
        print(f"unknown role: {args.name}", file=sys.stderr)
        return 2
    sys.stdout.write(lib.fill_placeholders(Path(info["contract_path"]).read_text(encoding="utf-8")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
