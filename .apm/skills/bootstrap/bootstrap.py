#!/usr/bin/env python3
"""Create and incrementally migrate an Agent Army profile (package 0.6.1, profile schema v3).

This is intentionally deterministic.  The chat skill decides *what the project
needs*; this program owns filesystem layout and ownership boundaries.  It never
rewrites a user-owned hook or workflow.

One profile serves every tool: role contracts live only in `.agent-army/agents`
and skills find them with `army.py`.  No target is chosen and no native agent
copy (.claude/agents, .codex/agents, ...) is rendered.  `--tool` is needed only
to render Agent Army runtime hooks for the tool the user runs.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
import armylib as lib  # noqa: E402
from armylib import (  # noqa: E402
    BASE,
    DEFAULT_MODEL_TIERS,
    HERE,
    LOCAL_AGENT_SOURCE_DIR,
    LOCAL_AGENT_SUFFIX,
    PACKAGE_VERSION,
    PROFILE_SCHEMA_VERSION,
    ROLE_CAPABILITY,
    ROLE_MODEL_MARKER,
    ROLES,
)

TOOLS_DIR = BASE / "tools"
# The neutral skill location older bootstraps wrote into the router block.
SHARED_SKILLS_DIR = ".agents/skills"
PLANNING_ROLES = ("planning-analyst", "plan-reviewer")
# The 0.3.1 core identifies an Agent Army install; the product skills joined in 0.4.0.
CORE_SKILLS = ("bootstrap", "ship", "new-agent", "new-skill", "adapt-army")
PRODUCT_SKILLS = (
    "product",
    "product-strategy",
    "product-red-team",
    "market-research",
    "business-case",
    "validate-product",
    "product-spec",
    "solution-architecture",
    "delivery-plan",
    "go-to-market",
    "product-metrics",
    "ux-review",
    "legal-review",
    "launch-readiness",
)
SKILLS = CORE_SKILLS + PRODUCT_SKILLS
RUNTIME_TOOLS = {"claude", "codex", "cursor", "copilot", "gemini", "windsurf"}
ALL_TOOLS = {"claude", "codex", "cursor", "copilot", "opencode", "gemini", "windsurf"}
OWNERSHIP_MARKER = "# agent-army-owned"
MANAGED_ROUTER_START = "<!-- agent-army:feedback-router:start -->"
MANAGED_ROUTER_END = "<!-- agent-army:feedback-router:end -->"
PROFILE_IGNORE = ".agent-army/"
STATE_IGNORE = ".agent-army/state.json"
VISIBILITIES = ("committed", "gitignore", "exclude")
# User-owned files the generator never writes, in any mode.
PRESERVED_PATHS = (".agent-army/stores.json",)
# Pre-0.3 permanent sources, later temporary APM staging; both are gone in 0.5.
APM_AGENT_STAGING_DIR = ".apm/agents"
APM_AGENT_SUFFIX = ".agent.md"
# Where 0.3.x/0.4.x rendered (or APM deployed) a native copy of each role contract.
LEGACY_NATIVE_AGENT_PATHS = (
    ".claude/agents/agent-army-{role}.md",
    ".cursor/agents/agent-army-{role}.md",
    ".gemini/agents/agent-army-{role}.md",
    ".opencode/agents/agent-army-{role}.md",
    ".github/agents/agent-army-{role}.agent.md",
    ".codex/agents/agent-army-{role}.toml",
    ".windsurf/skills/agent-army-{role}/SKILL.md",
)
ADVISOR_CONTRACT = "product/advisor-contract.md"


def version_key(value: str) -> tuple[int, int, int]:
    """Compare the package's stable semver releases without extra dependencies."""
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", value)
    if not match:
        raise ValueError(f"unsupported Agent Army version: {value}")
    return tuple(int(part) for part in match.groups())


def owns_marker(text: str) -> bool:
    return OWNERSHIP_MARKER in text


def descriptor_dir(tool: str, key: str) -> str | None:
    """Read `dirs.<key>` from tools/<tool>.yml; check.sh compares it with a real YAML parse."""
    return lib.descriptor_value(tool, "dirs", key)


_SKILLS_DIRS: dict[str, str] = {}


def skills_dir(tool: str) -> str:
    """Where a per-repo APM install puts the skills for this tool (descriptor `dirs.skills`).

    Informational since 0.5: skills may equally be installed globally; bootstrap never relies on it.
    """
    if tool not in _SKILLS_DIRS:
        value = descriptor_dir(tool, "skills") or descriptor_dir("_default", "skills")
        parts = value.split("/") if value else []
        if not parts or any(part in {".", ".."} or not re.fullmatch(r"[A-Za-z0-9._-]+", part) for part in parts):
            raise RuntimeError(f"tools/{tool}.yml has no valid relative dirs.skills ({value!r})")
        _SKILLS_DIRS[tool] = value
    return _SKILLS_DIRS[tool]


def feedback_router_block() -> str:
    """A small, explicitly-owned extension safe to add to specialized AGENTS.md files."""
    return """\n""" + MANAGED_ROUTER_START + """
## Keeping Agent Army current

When the user corrects an agent, identifies a repeatable weakness, asks for a better workflow, or
needs a missing specialist, first fix the current task inside its approved scope. Then classify the
lesson with the `/adapt-army` skill: task-local correction, repo convention, existing agent, existing
skill, deterministic control, new agent, or new skill. Never modify the Army silently. Show an **Army
Improvement Proposal** with the evidence, recommended target, write scope, verification and one approval
question. Durable proposals and decisions live locally in `.agent-army/state.json`; do not store raw user
text, secrets, blueprint paths or `design-docs` references there. The Agent Army skills are
package-managed and may be installed globally or in this repo; never edit them here. Role contracts live
only in `.agent-army/agents` (skills find them with `bootstrap/army.py locate`); there is no native agent
copy to edit. Put a repo law in `AGENTS.md`, a role responsibility in `.agent-army/agents`, and a separate
user-invoked workflow in a new repo-local skill. After a package update, run `/bootstrap` to review new
package skills and templates before choosing any local specialization changes.
""" + MANAGED_ROUTER_END + """\n"""


def legacy_router_block(target_skills_dir: str) -> str:
    """The block 0.3.1/0.4.0 wrote, byte for byte, for one installed skill location."""
    managed = "APM-managed and shared across tools" if target_skills_dir == SHARED_SKILLS_DIR else "APM-managed"
    return """\n""" + MANAGED_ROUTER_START + """
## Keeping Agent Army current

When the user corrects an agent, identifies a repeatable weakness, asks for a better workflow, or
needs a missing specialist, first fix the current task inside its approved scope. Then classify the
lesson with `""" + target_skills_dir + """/adapt-army/SKILL.md`: task-local correction, repo convention, existing
agent, existing skill, deterministic control, new agent, or new skill. Never modify the Army
silently. Show an **Army Improvement Proposal** with the evidence, recommended target, write scope,
verification and one approval question. Durable proposals and decisions live locally in
`.agent-army/state.json`; do not store raw user text, secrets, blueprint paths or `design-docs` references
there. Core skills in `""" + target_skills_dir + """/` are """ + managed + """. Before a durable proposal,
read the live skill, applicable `AGENTS.md` and local `.agent-army/agents` sources. Put a repo law in `AGENTS.md`,
a role responsibility in `.agent-army/agents`, and a separate user-invoked workflow in a new `.apm/skills` skill;
never edit a package-managed core skill in a target repository. After `apm update`, run `/bootstrap` to
review new package skills and templates before choosing any local specialization changes.
""" + MANAGED_ROUTER_END + """\n"""


def managed_router_span(text: str) -> tuple[int, int] | None:
    start = text.find(MANAGED_ROUTER_START)
    end = text.find(MANAGED_ROUTER_END)
    if start == -1 or end == -1 or end < start:
        return None
    return start, end + len(MANAGED_ROUTER_END)


def managed_router_status(path: Path) -> str:
    """Return append, current, replace or conflict without touching user-authored AGENTS content.

    `replace` means an unedited block an earlier package wrote: safe to update in place.
    """
    if not path.exists():
        return "append"
    text = path.read_text(encoding="utf-8")
    if MANAGED_ROUTER_START not in text and MANAGED_ROUTER_END not in text:
        return "append"
    span = managed_router_span(text)
    if span is None:
        return "conflict"
    current = text[span[0]:span[1]].strip()
    if current == feedback_router_block().strip():
        return "current"
    known = {legacy_router_block(SHARED_SKILLS_DIR).strip()}
    known |= {legacy_router_block(skills_dir(tool)).strip() for tool in ALL_TOOLS}
    return "replace" if current in known else "conflict"


def ensure_feedback_router(root: Path, dry_run: bool) -> list[str]:
    path = root / "AGENTS.md"
    status = managed_router_status(path)
    if status == "conflict":
        return [str(path.relative_to(root)) + " has a modified Agent Army feedback-router block"]
    if status == "current":
        print(f"kept {path.relative_to(root)} (feedback-router already current)")
        return []
    block = feedback_router_block()
    existing = path.read_text(encoding="utf-8") if path.exists() else "# AGENTS.md\n"
    span = managed_router_span(existing) if status == "replace" else None
    if span:
        write_text(path, existing[:span[0]] + block.strip() + existing[span[1]:], dry_run)
    else:
        write_text(path, existing.rstrip() + "\n" + block, dry_run)
    return []


def is_tracked(root: Path, path: Path) -> bool:
    """Distinguish committed legacy input from ignored, regenerable staging."""
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", "--", str(path.relative_to(root))],
        cwd=root,
        text=True,
        capture_output=True,
    )
    return result.returncode == 0


def shown(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def write_text(path: Path, content: str, dry_run: bool) -> None:
    if any(path.resolve() == (ROOT / preserved).resolve() for preserved in PRESERVED_PATHS):
        raise RuntimeError(f"refusing to write user-owned {shown(path)}")
    print(f"{'plan' if dry_run else '+'} {shown(path)}")
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def model_routing(tool: str | None, previous: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    """Resolve per-tool model IDs once at bootstrap; never ask an LLM to manufacture one.

    The tiers are applied by the skill at dispatch time (army.py), never written into the shared
    role contracts, so one profile serves every tool.
    """
    supplied = {tier: getattr(args, f"model_{tier}") for tier in ("light", "mid", "strong")}
    supplied_values = [value for value in supplied.values() if value]
    if supplied_values and len(supplied_values) != len(supplied):
        raise ValueError("--model-light, --model-mid and --model-strong must be supplied together")
    if supplied_values and not tool:
        raise ValueError("--model-light/--model-mid/--model-strong need --tool to say which tool's model IDs they are")
    if supplied_values and not lib.model_capable(tool):
        raise ValueError(f"{tool} runs roles in the main thread; it has no per-role model to set")

    base = {"roles": ROLE_CAPABILITY, "effort": "unsupported"}
    if args.role_model_routing == "inherit":
        return {"strategy": "inherit", "source": "user-disabled", "tools": {}, **base,
                "reason": "user selected inherited subagent models"}

    previous_routing = previous.get("model_routing") if isinstance(previous.get("model_routing"), dict) else {}
    tools: dict[str, dict[str, str]] = {}
    if previous_routing.get("strategy") != "inherit" or previous_routing.get("source") != "user-disabled":
        recorded = previous_routing.get("tools")
        if isinstance(recorded, dict):
            tools = {name: dict(tiers) for name, tiers in recorded.items() if isinstance(tiers, dict)}
        elif previous_routing.get("strategy") == "per_role_static" and isinstance(previous_routing.get("tiers"), dict):
            # Schema v2 recorded one target's tiers; keep them for that tool when it can still use them.
            target = previous_routing.get("target")
            if target and lib.model_capable(target):
                tools[target] = dict(previous_routing["tiers"])
    source = "previous-bootstrap" if tools else "package-default"
    if supplied_values:
        tools[tool] = dict(supplied)
        source = "user-provided"
    for name, tiers in DEFAULT_MODEL_TIERS.items():
        tools.setdefault(name, dict(tiers))
    tools = {name: tiers for name, tiers in sorted(tools.items()) if all(tiers.get(t) for t in ("light", "mid", "strong"))}
    if not tools:
        return {"strategy": "inherit", "source": "fallback", "tools": {}, **base,
                "reason": "no tool with a per-role model has light/mid/strong model IDs"}
    return {"strategy": "per_role_static", "source": source, "tools": tools, **base,
            "reason": "skills pass the role's model when they dispatch it; tools select no effort per role"}


def strip_generated_model(path: Path, dry_run: bool) -> bool:
    """Remove the `model:` line an earlier bootstrap generated into a shared contract.

    A user's own (unmarked) model line is an override and stays untouched.
    """
    text = path.read_text(encoding="utf-8")
    split = lib.split_frontmatter(text)
    if split is None:
        return False
    frontmatter, body = split
    existing = re.search(r"^model:.*" + re.escape(ROLE_MODEL_MARKER) + r".*\n?", frontmatter, flags=re.MULTILINE)
    if not existing:
        return False
    print(f"{'plan' if dry_run else '~'} {path.relative_to(ROOT)} (generated model line moves to the profile)")
    if not dry_run:
        path.write_text("---" + frontmatter[:existing.start()] + frontmatter[existing.end():] + "---" + body, encoding="utf-8")
    return True


def role_overrides(root: Path) -> dict[str, dict[str, str | None]]:
    """Snapshot each role's capability and any user-owned model override."""
    effective: dict[str, dict[str, str | None]] = {}
    for role in lib.local_roles(root):
        model, generated = lib.frontmatter_model(lib.contract_path(root, role).read_text(encoding="utf-8"))
        effective[role] = {
            "capability": ROLE_CAPABILITY.get(role, "mid"),
            "model_override": model if model and not generated else None,
        }
    return effective


def migrate_legacy_agent_sources(root: Path, dry_run: bool) -> list[str]:
    """Move old Markdown sources (and drop old staging) to the one canonical source path."""
    legacy_dir = root / APM_AGENT_STAGING_DIR
    source_dir = root / LOCAL_AGENT_SOURCE_DIR
    if not legacy_dir.is_dir():
        return []

    conflicts: list[str] = []
    for legacy in sorted(legacy_dir.glob(f"agent-army-*{APM_AGENT_SUFFIX}")):
        if not legacy.is_file():
            continue
        local_name = legacy.name[: -len(".md")]
        destination = source_dir / local_name
        if destination.exists():
            if not destination.is_file():
                conflicts.append(
                    f"{legacy.relative_to(root)} cannot migrate because {destination.relative_to(root)} is not a file"
                )
                continue
            if is_tracked(root, legacy) and destination.read_bytes() != legacy.read_bytes():
                conflicts.append(
                    f"{legacy.relative_to(root)} differs from {destination.relative_to(root)}"
                )
                continue
            print(f"{'plan' if dry_run else 'remove'} {legacy.relative_to(root)} (canonical source wins over old APM staging)")
            if not dry_run:
                legacy.unlink()
            continue

        print(
            f"{'plan' if dry_run else 'move'} {legacy.relative_to(root)} -> "
            f"{destination.relative_to(root)}"
        )
        if not dry_run:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(legacy), str(destination))
    return conflicts


def native_renders(source: str, role: str, rel: str) -> set[str]:
    """Digests a native copy of `source` could have, as 0.3.x/0.4.x rendered it."""
    renders = {source}
    if rel.startswith(".windsurf/"):
        renders.add("---\nname: agent-army-" + role + "\ndescription: Agent Army fallback role for Windsurf.\n---\n\n" + source)
    return {hashlib.sha256(text.encode("utf-8")).hexdigest() for text in renders}


def classify_native_agents(root: Path, previous: dict[str, Any]) -> tuple[list[Path], list[tuple[Path, str]]]:
    """Find the native role copies earlier packages rendered: (removable, [(kept, reason)]).

    A copy is removable only when it is a plain single-link file whose content equals a render of
    the current canonical contract or the digest the previous profile recorded for it. Anything
    else may hold local changes and is reported, never deleted.
    """
    package = previous.get("package") if isinstance(previous.get("package"), dict) else {}
    recorded = package.get("adapter_outputs") if isinstance(package.get("adapter_outputs"), dict) else {}
    removable: list[Path] = []
    kept: list[tuple[Path, str]] = []
    for role in lib.local_roles(root):
        source = lib.contract_path(root, role).read_text(encoding="utf-8")
        for pattern in LEGACY_NATIVE_AGENT_PATHS:
            rel = pattern.format(role=role)
            path = root / rel
            if not path.exists() and not path.is_symlink():
                continue
            info = path.lstat()
            if not stat.S_ISREG(info.st_mode) or info.st_nlink > 1:
                kept.append((path, "symlink, hard link or not a file"))
                continue
            digest = sha256_file(path)
            if digest in native_renders(source, role, rel) or recorded.get(rel) == digest:
                removable.append(path)
            else:
                kept.append((path, "differs from .agent-army/agents; merge any change into the contract, then delete it"))
    return removable, kept


def remove_native_agents(root: Path, previous: dict[str, Any], dry_run: bool) -> list[str]:
    """Delete verified native copies (and their emptied dirs); return the kept ones for the review."""
    removable, kept = classify_native_agents(root, previous)
    for path in removable:
        print(f"{'plan remove' if dry_run else 'remove'} {path.relative_to(root)} (generated copy; the one source is {LOCAL_AGENT_SOURCE_DIR})")
        if dry_run:
            continue
        path.unlink()
        parent = path.parent
        while parent != root and parent.is_dir() and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent
    for path, reason in kept:
        print(f"kept {path.relative_to(root)} ({reason})")
    return [str(path.relative_to(root)) for path, _reason in kept]


def migrate_legacy_artifacts(root: Path, previous: dict[str, Any], dry_run: bool) -> tuple[list[str], list[str]]:
    """Migrate old agent sources, then drop generated native copies. Returns (conflicts, kept natives)."""
    conflicts = migrate_legacy_agent_sources(root, dry_run)
    if conflicts:
        return conflicts, []
    # Compare native copies with the contract before its generated model line is stripped.
    kept = remove_native_agents(root, previous, dry_run)
    for role in lib.local_roles(root):
        strip_generated_model(lib.contract_path(root, role), dry_run)
    return [], kept


def planning_role_collisions(root: Path, previous: dict[str, Any]) -> list[str]:
    """A newly introduced role path is a conflict unless this profile already owns that role."""
    routing = previous.get("model_routing") if isinstance(previous.get("model_routing"), dict) else {}
    roles = routing.get("roles") if isinstance(routing.get("roles"), dict) else {}
    conflicts = []
    for role in PLANNING_ROLES:
        path = lib.contract_path(root, role)
        if role not in roles and path.exists():
            conflicts.append(str(path.relative_to(root)))
    return conflicts


def copy_file(source: Path, target: Path, dry_run: bool, executable: bool = False) -> None:
    print(f"{'plan' if dry_run else '+'} {shown(target)}")
    if dry_run:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    if executable:
        target.chmod(target.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def detect_existing(root: Path) -> dict[str, list[str]]:
    runtime = []
    for name in (".claude/settings.json", ".codex/hooks", ".cursor/hooks", ".github/hooks", ".gemini/hooks", ".windsurf/hooks"):
        if (root / name).exists():
            runtime.append(name)
    git_hook = []
    configured = subprocess.run(["git", "config", "core.hooksPath"], cwd=root, text=True, capture_output=True)
    if configured.returncode == 0 and configured.stdout.strip():
        git_hook.append(configured.stdout.strip() + "/pre-commit")
    elif (root / ".git/hooks/pre-commit").exists():
        git_hook.append(".git/hooks/pre-commit")
    ci = [str(p.relative_to(root)) for p in sorted((root / ".github/workflows").glob("*.y*ml"))] if (root / ".github/workflows").exists() else []
    return {"runtime_hooks": runtime, "git_precommit": git_hook, "ci": ci}


def default_quality(root: Path) -> dict[str, Any]:
    # argv + cwd are data, never shell snippets.  Bootstrap may later replace these
    # after recon with verified commands, preserving this shape.
    quality: dict[str, Any] = {"format": None, "lint": None, "test": None}
    if (root / "package.json").exists():
        quality["format"] = {"cwd": ".", "argv": ["npm", "run", "format"]}
        quality["lint"] = {"cwd": ".", "argv": ["npm", "run", "lint"]}
        quality["test"] = {"cwd": ".", "argv": ["npm", "test"]}
    elif (root / "pyproject.toml").exists() or (root / "requirements.txt").exists():
        quality["lint"] = {"cwd": ".", "argv": ["ruff", "check", "."]}
        quality["test"] = {"cwd": ".", "argv": ["pytest", "-q"]}
    elif (root / "go.mod").exists():
        quality["format"] = {"cwd": ".", "argv": ["gofmt", "-w", "."]}
        quality["test"] = {"cwd": ".", "argv": ["go", "test", "./..."]}
    elif (root / "Cargo.toml").exists():
        quality["format"] = {"cwd": ".", "argv": ["cargo", "fmt"]}
        quality["lint"] = {"cwd": ".", "argv": ["cargo", "clippy", "-q"]}
        quality["test"] = {"cwd": ".", "argv": ["cargo", "test", "-q"]}
    return quality


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package_inventory() -> dict[str, dict[str, str]]:
    """Hash the package this generator runs from, wherever it is installed (global or per repo)."""
    skills_root = HERE.parent
    skills = {
        skill: sha256_file(skills_root / skill / "SKILL.md")
        for skill in SKILLS
        if (skills_root / skill / "SKILL.md").is_file()
    }
    # The shared advisor contract changes every product skill's behavior, so it is reviewed too.
    if (skills_root / ADVISOR_CONTRACT).is_file():
        skills[ADVISOR_CONTRACT] = sha256_file(skills_root / ADVISOR_CONTRACT)
    templates: dict[str, str] = {}
    for path in sorted(BASE.rglob("*")):
        if path.is_file() and path.suffix in {".md", ".py", ".yml", ".yaml"}:
            templates[str(path.relative_to(skills_root))] = sha256_file(path)
    return {"skills": skills, "templates": templates}


def inventory_delta(previous: dict[str, Any], current: dict[str, dict[str, str]]) -> dict[str, dict[str, list[str]]]:
    """Return deterministic added/changed names without storing material content."""
    previous_inventory = previous.get("inventory") if isinstance(previous.get("inventory"), dict) else {}
    result: dict[str, dict[str, list[str]]] = {}
    for group in ("skills", "templates"):
        before = previous_inventory.get(group) if isinstance(previous_inventory.get(group), dict) else {}
        after = current[group]
        result[group] = {
            "new": sorted(name for name in after if name not in before),
            "changed": sorted(name for name, digest in after.items() if name in before and before[name] != digest),
        }
    return result


def has_inventory_delta(delta: dict[str, dict[str, list[str]]]) -> bool:
    return any(values[change] for values in delta.values() for change in ("new", "changed"))


def print_upgrade_review(
    from_version: str | None,
    delta: dict[str, dict[str, list[str]]],
    kept_natives: list[str] | None = None,
) -> None:
    """Print the deterministic portion of the user-facing upgrade review card."""
    print("\nIncremental Upgrade Review")
    print(f"  package: {from_version or 'new profile'} -> {PACKAGE_VERSION}")
    for group, label in (("skills", "skills"), ("templates", "baseline templates")):
        for change, prefix in (("new", "new"), ("changed", "changed")):
            values = delta[group][change]
            if values:
                print(f"  {prefix} {label}: {', '.join(values)}")
    if not has_inventory_delta(delta):
        print("  package delta: no changed live package material detected")
    if kept_natives:
        print(
            "  conflict: native role copies kept (not identical to the canonical contract): "
            f"{', '.join(kept_natives)} (merge any change into {LOCAL_AGENT_SOURCE_DIR}, then delete the copy)"
        )
    for name in delta["templates"]["changed"]:
        role = re.fullmatch(r"bootstrap/baseline/core/agents/([a-z-]+)\.md", name)
        if role and role.group(1) in ROLES:
            local = f"{LOCAL_AGENT_SOURCE_DIR}/agent-army-{role.group(1)}{LOCAL_AGENT_SUFFIX}"
            print(f"  recommended local diff: {name} -> {local} (merge into the specialization, never replace it)")
    print(f"  inspect before recommending a local diff: {HERE.parent}, AGENTS.md, {LOCAL_AGENT_SOURCE_DIR}")
    print("  decision: apply selected | apply all | show details | skip")


def source_agent(role: str) -> str:
    return lib.fill_placeholders(lib.baseline_contract_path(role).read_text(encoding="utf-8"))


def installed_package_version(profile: dict[str, Any]) -> str | None:
    package = profile.get("package")
    if isinstance(package, dict) and isinstance(package.get("version"), str):
        return package["version"]
    return None


def resolve_bootstrap_mode(previous: dict[str, Any], requested: str) -> tuple[str, str | None]:
    """Choose a safe mode; downgrades are refused. A profile is no longer bound to one tool."""
    if not previous:
        if requested == "incremental":
            raise ValueError("no existing Agent Army profile; incremental mode needs a prior bootstrap")
        return "initial" if requested == "auto" else "full", None

    installed = installed_package_version(previous)
    if installed is None:
        if previous.get("profile") == "agent-army":
            return "incremental", None
        if requested == "incremental":
            raise ValueError("profile has no recognizable Agent Army package version; use --mode full")
        return "full", None
    if version_key(installed) > version_key(PACKAGE_VERSION):
        raise ValueError(f"profile uses newer Agent Army {installed}; refusing downgrade to {PACKAGE_VERSION}")
    if requested == "full":
        return "full", installed
    if version_key(installed) < version_key(PACKAGE_VERSION) or previous.get("version") != PROFILE_SCHEMA_VERSION:
        return "incremental", installed
    if requested == "incremental":
        return "incremental", installed
    return "current", installed


def has_explicit_profile_change(args: argparse.Namespace) -> bool:
    """A current package may still need a safe re-bootstrap for user-requested settings."""
    return bool(
        args.runtime_hooks
        or args.git_precommit
        or args.ci
        or args.visibility
        or args.model_light
        or args.model_mid
        or args.model_strong
        or args.role_model_routing == "inherit"
        or args.upgrade_review_outcome is not None
    )


def needs_package_maintenance(previous: dict[str, Any], root: Path) -> bool:
    """Detect incomplete state or changed package material on every update."""
    package = previous.get("package") if isinstance(previous.get("package"), dict) else {}
    legacy_agents = any(legacy.is_file() for legacy in (root / APM_AGENT_STAGING_DIR).glob(f"agent-army-*{APM_AGENT_SUFFIX}"))
    generated_models = any(
        lib.frontmatter_model(lib.contract_path(root, role).read_text(encoding="utf-8"))[1] for role in lib.local_roles(root)
    )
    return (
        not isinstance(package.get("inventory"), dict)
        or has_inventory_delta(inventory_delta(package, package_inventory()))
        or managed_router_status(root / "AGENTS.md") != "current"
        or legacy_agents
        or generated_models
        # Only a removable copy; a kept conflict alone does not reopen the review.
        or bool(classify_native_agents(root, previous)[0])
    )


def hook_document(event: str, action: str) -> str:
    # APM hook primitives use event-name -> list.  The nested shape is the
    # Claude-compatible representation that APM can translate for tools
    # which expose a corresponding lifecycle event.
    return json.dumps({event: [{"matcher": ".*", "hooks": [{"type": "command", "command": f"python3 .agent-army/runtime.py {action}"}]}]}, indent=2) + "\n"


def precommit_shim() -> str:
    return "#!/usr/bin/env bash\n" + OWNERSHIP_MARKER + "\n# agent-army-package: " + PACKAGE_VERSION + "\nexec python3 \"$(git rev-parse --show-toplevel)/.agent-army/runtime.py\" precommit\n"


def install_precommit(root: Path, mode: str, evidence: list[str], dry_run: bool) -> tuple[str, list[str]]:
    if mode != "army":
        return mode, evidence
    hooks_path = subprocess.run(["git", "config", "core.hooksPath"], cwd=root, text=True, capture_output=True).stdout.strip()
    hook = root / (hooks_path if hooks_path else ".git/hooks") / "pre-commit"
    if hook.exists() and not owns_marker(hook.read_text(encoding="utf-8", errors="ignore")):
        # A shell hook can be safely appended. Anything else remains user-owned.
        data = hook.read_text(encoding="utf-8", errors="ignore")
        if not data.startswith("#!") or not re.search(r"^#!.*(?:ba)?sh", data):
            return "blocked", [str(hook.relative_to(root))]
        addition = f"\n{OWNERSHIP_MARKER}\n# agent-army-package: {PACKAGE_VERSION}\npython3 \"$(git rev-parse --show-toplevel)/.agent-army/runtime.py\" precommit || exit 1\n"
        write_text(hook, data.rstrip() + addition, dry_run)
    elif not hook.exists():
        write_text(hook, precommit_shim(), dry_run)
    if not dry_run:
        hook.chmod(hook.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return "army", [str(hook.relative_to(root))]


def write_ci(root: Path, mode: str, evidence: list[str], visibility: str, dry_run: bool) -> tuple[str, list[str]]:
    if mode != "army":
        return mode, evidence
    if visibility != "committed":
        # CI runs on a clean checkout, which has no ignored .agent-army/runtime.py.
        return "blocked", [f"visibility={visibility}: .agent-army is not committed"]
    path = root / ".github/workflows/agent-army-quality.yml"
    if path.exists() and not owns_marker(path.read_text(encoding="utf-8", errors="ignore")):
        return "blocked", [str(path.relative_to(root))]
    copy_file(BASE / ".github/workflows/quality.yml", path, dry_run)
    return "army", [str(path.relative_to(root))]


def write_runtime_sources(root: Path, tool: str | None, install_hooks: bool, dry_run: bool) -> None:
    copy_file(BASE / "runtime.py", root / ".agent-army/runtime.py", dry_run, executable=True)
    if not install_hooks:
        return
    if tool and tool not in RUNTIME_TOOLS:
        print(f"note runtime_hooks: {tool} has no supported native runtime hook adapter")
        return
    for event, action in (("PreToolUse", "guard"), ("PostToolUse", "format"), ("SubagentStop", "verify"), ("Stop", "gate")):
        write_text(root / f".apm/hooks/agent-army-{action}.json", hook_document(event, action), dry_run)
    if not tool:
        print("note runtime_hooks: hook primitives written to .apm/hooks; render them for your tool with "
              "`apm install --target <tool>` or rerun with --tool <tool>")


def write_agents(root: Path, dry_run: bool, add_missing: bool = True) -> None:
    """Write missing role contracts when allowed; existing ones are the user's specialization."""
    for role in ROLES:
        path = lib.contract_path(root, role)
        if path.exists():
            print(f"kept {path.relative_to(root)}")
        elif add_missing:
            write_text(path, source_agent(role), dry_run)


def git_exclude_path(root: Path) -> Path:
    found = subprocess.run(["git", "rev-parse", "--git-path", "info/exclude"], cwd=root, text=True, capture_output=True)
    value = found.stdout.strip() if found.returncode == 0 else ".git/info/exclude"
    path = Path(value)
    return path if path.is_absolute() else root / path


def append_lines(path: Path, entries: list[str], dry_run: bool) -> None:
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    missing = [entry for entry in entries if entry not in existing.splitlines()]
    if missing:
        separator = "" if not existing or existing.endswith("\n") else "\n"
        write_text(path, existing + separator + "\n".join(missing) + "\n", dry_run)


def apply_visibility(root: Path, visibility: str, dry_run: bool) -> None:
    """Commit the profile, or keep it out of git through .gitignore or the local .git/info/exclude."""
    if visibility == "committed":
        append_lines(root / ".gitignore", [STATE_IGNORE], dry_run)
    elif visibility == "gitignore":
        append_lines(root / ".gitignore", [PROFILE_IGNORE], dry_run)
    else:
        append_lines(git_exclude_path(root), [PROFILE_IGNORE], dry_run)
    for path in (root / ".gitignore", git_exclude_path(root)):
        lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
        if visibility == "committed" and PROFILE_IGNORE in lines:
            print(f"note visibility: {shown(path)} still ignores {PROFILE_IGNORE}; remove that line to commit the profile")


def run_apm(root: Path, tool: str) -> int:
    """Render .apm/hooks for one tool. Agent Army itself installs nothing else through APM."""
    apm = shutil.which("apm")
    if not apm:
        print(f"WARN: apm not found; hook primitives are in .apm/hooks, run `apm install --target {tool}` later.", file=sys.stderr)
        return 0
    if not (root / "apm.yml").exists():
        write_text(root / "apm.yml", f"name: agent-army-profile\nversion: {PACKAGE_VERSION}\ndescription: Local Agent Army runtime hooks\nincludes: auto\ndependencies:\n  apm: []\n  mcp: []\n", False)
        lock = subprocess.run([apm, "lock"], cwd=root)
        if lock.returncode != 0:
            return lock.returncode
    return subprocess.run([apm, "install", "--frozen", "--target", tool], cwd=root).returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("legacy_tool", nargs="?", choices=sorted(ALL_TOOLS), metavar="TOOL",
                        help="deprecated positional form of --tool")
    parser.add_argument("--tool", choices=sorted(ALL_TOOLS), help="the tool to render runtime hooks / record model IDs for")
    parser.add_argument("--visibility", choices=VISIBILITIES, help="commit .agent-army, or ignore it via .gitignore or .git/info/exclude")
    parser.add_argument("--runtime-hooks", choices=("army", "external", "disabled"))
    parser.add_argument("--git-precommit", choices=("army", "external", "disabled"))
    parser.add_argument("--ci", choices=("army", "external", "disabled"))
    parser.add_argument("--role-model-routing", choices=("auto", "inherit"), default="auto")
    parser.add_argument("--model-light", metavar="MODEL", help="exact model ID for light roles in --tool")
    parser.add_argument("--model-mid", metavar="MODEL", help="exact model ID for mid roles in --tool")
    parser.add_argument("--model-strong", metavar="MODEL", help="exact model ID for strong roles in --tool")
    parser.add_argument("--mode", choices=("auto", "incremental", "full"), default="auto", help="auto-detect, migrate only, or intentionally re-specialize")
    parser.add_argument("--upgrade-review-outcome", choices=("applied", "skipped"), help="record the user's resolved Incremental Upgrade Review")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-apm", action="store_true", help="test-only: do not run apm install")
    args = parser.parse_args()
    if args.legacy_tool and args.tool and args.legacy_tool != args.tool:
        parser.error("positional TOOL and --tool disagree")
    tool = args.tool or args.legacy_tool

    global ROOT
    ROOT = lib.repo_root()
    previous = lib.read_profile(ROOT)
    try:
        bootstrap_mode, from_version = resolve_bootstrap_mode(previous, args.mode)
    except ValueError as exc:
        parser.error(str(exc))
    profile_change_only = False
    if bootstrap_mode == "current":
        if needs_package_maintenance(previous, ROOT):
            bootstrap_mode = "incremental"
            print("Agent Army package is current; applying the pending correction and upgrade review.")
        elif args.upgrade_review_outcome is not None:
            bootstrap_mode = "incremental"
            print("Agent Army package is current; recording the resolved Incremental Upgrade Review.")
        elif not has_explicit_profile_change(args):
            print(f"Agent Army {PACKAGE_VERSION} profile is current; no incremental changes needed. Use --mode full to re-specialize.")
            return 0
        else:
            bootstrap_mode = "full"
            profile_change_only = True
            print("Agent Army package is current; applying explicitly requested profile configuration changes.")
    if bootstrap_mode == "incremental" and not args.dry_run and args.upgrade_review_outcome is None:
        print(
            "ERROR: incremental bootstrap requires the resolved Incremental Upgrade Review choice; "
            "rerun with --upgrade-review-outcome applied or skipped after presenting the review.",
            file=sys.stderr,
        )
        return 2
    if bootstrap_mode == "incremental" and args.upgrade_review_outcome == "applied":
        collisions = planning_role_collisions(ROOT, previous)
        if collisions:
            print("ERROR: new planning role name collides with a local role; no upgrade changes applied:", file=sys.stderr)
            for path in collisions:
                print(f"  - {path}", file=sys.stderr)
            return 2
    try:
        routing = model_routing(tool, previous, args)
    except ValueError as exc:
        parser.error(str(exc))
    if bootstrap_mode == "incremental":
        print(f"\nAgent Army incremental migration plan: {from_version or 'legacy profile'} -> {PACKAGE_VERSION}")
        print("  apply: AGENTS.md managed feedback-router block; package metadata; inventory refresh")
        print(f"  apply: one profile for every tool — drop generated native role copies and generated model lines; {LOCAL_AGENT_SOURCE_DIR} stays the only source")
        print("  preserve: .agent-army/agents, .agent-army/stores.json, model routing, quality policy and external controls")
        print("  local role contracts: add the new planning roles only when the upgrade review is applied")
        conflicts = ensure_feedback_router(ROOT, args.dry_run)
    else:
        conflicts = []
        # The managed router block belongs to every profile; a block the user edited is left alone.
        router = managed_router_status(ROOT / "AGENTS.md")
        if router in {"append", "replace"}:
            ensure_feedback_router(ROOT, args.dry_run)
        elif router == "conflict":
            print("note AGENTS.md: the Agent Army feedback-router block was edited; kept as is")
    if not conflicts:
        more, kept_natives = migrate_legacy_artifacts(ROOT, previous, args.dry_run)
        conflicts += more
    if conflicts:
        print("ERROR: bootstrap migration needs a human decision:", file=sys.stderr)
        for conflict in conflicts:
            print(f"  - {conflict}", file=sys.stderr)
        return 2

    previous_modes = previous.get("enforcement", {}) if isinstance(previous.get("enforcement"), dict) else {}
    def prior_mode(name: str) -> str | None:
        value = previous_modes.get(name)
        mode = value.get("mode") if isinstance(value, dict) else None
        return mode if mode in {"army", "external", "disabled"} else None
    found = detect_existing(ROOT)
    selections = {
        "runtime_hooks": args.runtime_hooks or prior_mode("runtime_hooks") or ("external" if found["runtime_hooks"] else "army"),
        "git_precommit": args.git_precommit or prior_mode("git_precommit") or ("external" if found["git_precommit"] else "army"),
        "ci": args.ci or prior_mode("ci") or ("external" if found["ci"] else "army"),
    }
    if tool == "opencode" and selections["runtime_hooks"] == "army":
        selections["runtime_hooks"] = "blocked"
    visibility = args.visibility or (previous.get("visibility") if previous.get("visibility") in VISIBILITIES else "committed")

    previous_package = previous.get("package") if isinstance(previous.get("package"), dict) else {}
    inventory = package_inventory()
    delta = inventory_delta(previous_package, inventory)
    if bootstrap_mode == "incremental":
        print_upgrade_review(from_version, delta, kept_natives)
    if bootstrap_mode == "incremental" and args.upgrade_review_outcome == "skipped":
        print("preserve: local role contracts and model routing (Incremental Upgrade Review skipped)")
        write_agents(ROOT, args.dry_run, add_missing=False)
    else:
        # A configuration-only rerun never adds a role the user did not choose.
        write_agents(ROOT, args.dry_run, add_missing=not profile_change_only)
    routing["effective_roles"] = role_overrides(ROOT) if (ROOT / LOCAL_AGENT_SOURCE_DIR).is_dir() else {}
    if "army" in selections.values():
        write_runtime_sources(ROOT, tool, selections["runtime_hooks"] == "army", args.dry_run)
    git_mode, git_evidence = install_precommit(ROOT, selections["git_precommit"], found["git_precommit"], args.dry_run)
    ci_mode, ci_evidence = write_ci(ROOT, selections["ci"], found["ci"], visibility, args.dry_run)
    review: dict[str, Any] | None = None
    if bootstrap_mode == "incremental":
        review = {
            "status": args.upgrade_review_outcome or "pending",
            "from_version": from_version,
            "to_version": PACKAGE_VERSION,
            "delta": delta,
            "review_targets": ["AGENTS.md", LOCAL_AGENT_SOURCE_DIR],
        }
    elif isinstance(previous_package.get("upgrade_review"), dict):
        review = previous_package["upgrade_review"]
    config = {
        "version": PROFILE_SCHEMA_VERSION,
        "profile": "agent-army",
        "visibility": visibility,
        "package": {
            "name": "agent-army",
            "version": PACKAGE_VERSION,
            "profile_schema_version": PROFILE_SCHEMA_VERSION,
            "inventory": inventory,
            **({"upgrade_review": review} if review else {}),
        },
        "model_routing": routing,
        "quality": previous.get("quality") if isinstance(previous.get("quality"), dict) else default_quality(ROOT),
        "policy": previous.get("policy") if isinstance(previous.get("policy"), dict) else {},
        "enforcement": {
            "runtime_hooks": {"mode": selections["runtime_hooks"], "evidence": found["runtime_hooks"]},
            "git_precommit": {"mode": git_mode, "evidence": git_evidence},
            "ci": {"mode": ci_mode, "evidence": ci_evidence},
        },
    }
    write_text(ROOT / ".agent-army/config.json", json.dumps(config, indent=2) + "\n", args.dry_run)
    apply_visibility(ROOT, visibility, args.dry_run)
    print(f"\nAgent Army package {PACKAGE_VERSION} status (profile schema v{PROFILE_SCHEMA_VERSION}):")
    print(f"  profile: {LOCAL_AGENT_SOURCE_DIR} (one copy for every tool; visibility: {visibility})")
    for layer, value in config["enforcement"].items():
        print(f"  {layer}: {value['mode']}" + (f" ({', '.join(value['evidence'])})" if value["evidence"] else ""))
    tools = ", ".join(f"{name}={'/'.join(tiers[t] for t in ('light', 'mid', 'strong'))}" for name, tiers in routing["tools"].items())
    print(f"  role model routing: {routing['strategy']} ({routing['source']}{'; ' + tools if tools else ''}; effort: {routing['effort']})")
    if args.dry_run or args.skip_apm or selections["runtime_hooks"] != "army" or not tool or tool not in RUNTIME_TOOLS:
        return 0
    return run_apm(ROOT, tool)


if __name__ == "__main__":
    raise SystemExit(main())
