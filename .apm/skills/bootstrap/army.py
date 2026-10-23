#!/usr/bin/env python3
"""Locate the Agent Army profile of the repository a skill was invoked from.

Skills are installed once (globally or per repo) and stay generic; everything repo-specific lives
in `.agent-army/`. A skill runs this file relative to itself (`../bootstrap/army.py`) to find:

  army.py locate [--cwd DIR] [--army-root DIR] [--tool TOOL]
  army.py role NAME [--cwd DIR] [--army-root DIR]

Read-only: it never writes, never runs project commands and never renders native agent files.
A repository without a profile resolves to the package's baseline roles (`profile: "baseline"`).
The nearest ancestor profile wins; --army-root explicitly selects a package within the same checkout.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
import armylib as lib  # noqa: E402


def same_checkout(path: Path, root: Path) -> None:
    target = path.resolve()
    if path.exists() and lib.repo_root(target if target.is_dir() else target.parent) != root:
        raise ValueError(f"Army path belongs to a different Git checkout: {path}")


def context(cwd: Path, selected: Path | None = None) -> tuple[Path, Path]:
    """Return independent Git and Army roots, without searching descendants or other checkouts."""
    start = cwd.resolve()
    git = subprocess.run(["git", "-C", str(start), "rev-parse", "--show-toplevel"],
                         text=True, capture_output=True)
    if git.returncode:
        raise ValueError("Army discovery requires a task directory inside a Git checkout")
    root = Path(git.stdout.strip()).resolve()
    if selected is not None:
        owner = (selected if selected.is_absolute() else start / selected)
        # Accept either the owning directory or its .agent-army directory.
        if owner.name == lib.PROFILE_DIR:
            owner = owner.parent
        owner = owner.resolve()
        if not owner.is_relative_to(root) or not (owner / lib.PROFILE_DIR).is_dir():
            raise ValueError("--army-root must select an existing .agent-army in this Git checkout")
        if lib.repo_root(owner) != root:
            raise ValueError("--army-root cannot select a different Git checkout")
    else:
        owner = start
        while not (owner / lib.PROFILE_DIR).exists() and not (owner / lib.PROFILE_DIR).is_symlink():
            if owner == root:
                break
            owner = owner.parent
    directory = owner / lib.PROFILE_DIR
    if directory.exists() or directory.is_symlink():
        if not directory.is_dir() or not directory.resolve().is_relative_to(owner):
            raise ValueError(f"Army directory must stay inside its scope: {directory}")
        same_checkout(directory, root)
        for name in ("config.json", "agents", "stores.json"):
            if not (directory / name).resolve().is_relative_to(directory.resolve()):
                raise ValueError(f"Army path escapes the selected profile: {directory / name}")
            same_checkout(directory / name, root)
    return root, owner


def version_key(value: Any) -> tuple[int, ...] | None:
    try:
        return tuple(int(part) for part in str(value).split("."))
    except ValueError:
        return None


def upgrade_state(profile_version: Any) -> tuple[bool, bool]:
    """(upgrade_pending, profile_newer); an unparsable version still counts as pending."""
    if profile_version == lib.PACKAGE_VERSION:
        return False, False
    profile_key, package_key = version_key(profile_version), version_key(lib.PACKAGE_VERSION)
    if profile_key is None or package_key is None:
        return True, False
    return profile_key < package_key, profile_key > package_key


def contracts(owner: Path) -> dict[str, Path]:
    """Read canonical and legacy role filenames; ambiguity is an error, not a precedence rule."""
    found: dict[str, Path] = {}
    directory = owner / lib.LOCAL_AGENT_SOURCE_DIR
    root = lib.repo_root(owner)
    for path in sorted(directory.glob("agent-army-*")):
        suffix = next((s for s in (".agent.md", ".agent") if path.name.endswith(s)), None)
        if suffix is None or not path.is_file():
            continue
        if not path.resolve().is_relative_to((owner / lib.PROFILE_DIR).resolve()):
            raise ValueError(f"Role contract escapes the selected profile: {path}")
        same_checkout(path, root)
        role = path.name[len("agent-army-"):-len(suffix)]
        if role in found:
            raise ValueError(f"Ambiguous role {role}: {found[role]} and {path}")
        found[role] = path
    return found


def resolve_role(root: Path, profile: dict[str, Any], role: str, tool: str | None,
                 local_contracts: dict[str, Path] | None = None) -> dict[str, Any] | None:
    local = (contracts(root) if local_contracts is None else local_contracts).get(role)
    if local is not None:
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


def locate(cwd: Path, tool: str | None, army_root: Path | None = None) -> dict[str, Any]:
    root, owner = context(cwd, army_root)
    profile = lib.read_profile(owner)
    local = contracts(owner)
    directory = owner / lib.PROFILE_DIR
    specialized = directory.is_dir()
    diagnostic = None
    if specialized and not profile:
        diagnostic = "Profile metadata is missing, invalid or unsupported; confirm policy and quality commands before execution."
    package = profile.get("package") if isinstance(profile.get("package"), dict) else {}
    roles = list(lib.ROLES) + [role for role in local if role not in lib.ROLES]
    resolved = {role: resolve_role(owner, profile, role, tool, local) for role in roles}
    stores = directory / "stores.json"
    upgrade_pending, profile_newer = upgrade_state(package.get("version")) if profile else (False, False)
    return {
        "repo_root": str(root),
        "army_root": str(owner),
        "profile_dir": str(directory) if specialized else None,
        "profile": "specialized" if specialized else "baseline",
        "metadata_diagnostic": diagnostic,
        "profile_version": profile.get("version"),
        "profile_package_version": package.get("version"),
        "package_version": lib.PACKAGE_VERSION,
        "upgrade_pending": upgrade_pending,
        "profile_newer": profile_newer,
        "tool": tool,
        "dispatch": lib.dispatch_mode(tool),
        "roles": {role: info for role, info in resolved.items() if info},
        "agents_md": str(root / "AGENTS.md") if (root / "AGENTS.md").is_file() else None,
        "stores": str(stores) if stores.is_file() else None,
        "quality": profile.get("quality") if isinstance(profile.get("quality"), dict) else None,
        "bootstrap": None if specialized else str(lib.HERE / "SKILL.md"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    find = sub.add_parser("locate", help="print the resolved profile as JSON")
    find.add_argument("--cwd", type=Path, default=Path.cwd())
    find.add_argument("--army-root", type=Path, help="Army owner or .agent-army path, relative to --cwd")
    find.add_argument("--tool", help="the tool running this skill, e.g. claude; detected from the environment if omitted")
    show = sub.add_parser("role", help="print one role contract with placeholders resolved")
    show.add_argument("name")
    show.add_argument("--cwd", type=Path, default=Path.cwd())
    show.add_argument("--army-root", type=Path, help="Army owner or .agent-army path, relative to --cwd")
    args = parser.parse_args()

    try:
        resolved = locate(args.cwd, lib.detect_tool(getattr(args, "tool", None)), args.army_root)
    except ValueError as error:
        parser.error(str(error))
    if args.command == "locate":
        print(json.dumps(resolved, indent=2))
        return 0
    info = resolved["roles"].get(args.name)
    if info is None:
        print(f"unknown role: {args.name}", file=sys.stderr)
        return 2
    sys.stdout.write(lib.fill_placeholders(Path(info["contract_path"]).read_text(encoding="utf-8")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
