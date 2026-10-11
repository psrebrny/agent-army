#!/usr/bin/env python3
"""Create and incrementally migrate an Agent Army v0.3.1 profile.

This is intentionally deterministic.  The chat skill decides *what the project
needs*; this program owns filesystem layout, ownership boundaries and the APM
handoff.  It never rewrites a user-owned hook or workflow.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import Any


HERE = Path(__file__).resolve().parent
BASE = HERE / "baseline"
TOOLS_DIR = BASE / "tools"
# The neutral skill location. Most targets install there; for a target whose descriptor names
# another place (Claude: .claude/skills), an earlier bootstrap left a second copy here.
SHARED_SKILLS_DIR = ".agents/skills"
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
RUNTIME_TARGETS = {"claude", "codex", "cursor", "copilot", "gemini", "windsurf"}
AGENT_TARGETS = {"claude", "codex", "cursor", "copilot", "opencode", "gemini"}
NATIVE_AGENT_TARGETS = {"claude", "codex", "cursor", "copilot", "gemini"}
ALL_TARGETS = AGENT_TARGETS | {"windsurf"}
PACKAGE_VERSION = "0.4.0"
PROFILE_SCHEMA_VERSION = 2
OWNERSHIP_MARKER = "# agent-army-owned"
MANAGED_ROUTER_START = "<!-- agent-army:feedback-router:start -->"
MANAGED_ROUTER_END = "<!-- agent-army:feedback-router:end -->"
LOCAL_AGENT_SOURCE_DIR = ".agent-army/agents"
# User-owned files the generator never writes, in any mode.
PRESERVED_PATHS = (".agent-army/stores.json",)
APM_AGENT_STAGING_DIR = ".apm/agents"
APM_AGENT_SUFFIX = ".agent.md"
LOCAL_AGENT_SUFFIX = ".agent"
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
MODEL_CAPABLE_TARGETS = {"claude", "cursor"}
# Claude documents these portable tier names. Other adapters require their exact
# model IDs, which bootstrap receives explicitly rather than inventing them.
DEFAULT_MODEL_TIERS = {
    "claude": {"light": "haiku", "mid": "sonnet", "strong": "opus"},
}
ROLE_MODEL_MARKER = "# agent-army-role-profile:"


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
    """Read `dirs.<key>` from tools/<tool>.yml.

    The descriptors are flat two-level YAML, so a line parser is enough and PyYAML is not
    needed. check.sh compares the result with a real YAML parse of every descriptor.
    """
    try:
        lines = (TOOLS_DIR / f"{tool}.yml").read_text(encoding="utf-8").splitlines()
    except OSError:
        return None
    in_dirs = False
    for line in lines:
        content = line.split("#", 1)[0].rstrip()
        if not content.strip():
            continue
        if not content[0].isspace():
            in_dirs = content == "dirs:"
            continue
        match = re.fullmatch(r"\s+" + re.escape(key) + r":\s*(\S+)", content) if in_dirs else None
        if match:
            return match.group(1).strip("'\"")
    return None


_SKILLS_DIRS: dict[str, str] = {}


def skills_dir(target: str) -> str:
    """Return where APM installs the skills for this target, the one copy: descriptor `dirs.skills`."""
    if target not in _SKILLS_DIRS:
        value = descriptor_dir(target, "skills") or descriptor_dir("_default", "skills")
        parts = value.split("/") if value else []
        if not parts or any(part in {".", ".."} or not re.fullmatch(r"[A-Za-z0-9._-]+", part) for part in parts):
            raise RuntimeError(f"tools/{target}.yml has no valid relative dirs.skills ({value!r})")
        _SKILLS_DIRS[target] = value
    return _SKILLS_DIRS[target]


def feedback_router_block(target_skills_dir: str = SHARED_SKILLS_DIR) -> str:
    """A small, explicitly-owned extension safe to add to specialized AGENTS.md files.

    For the shared location this is byte-for-byte the block 0.3.1 and 0.4.0 wrote for every target.
    """
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


def managed_router_status(path: Path, target: str) -> str:
    """Return append, current, replace or conflict without touching user-authored AGENTS content.

    `replace` means the block is one this generator wrote for another skill location (e.g. the
    `.agents/skills` block an earlier bootstrap wrote for Claude): unedited, so safe to update.
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
    if current == feedback_router_block(skills_dir(target)).strip():
        return "current"
    known = {feedback_router_block(SHARED_SKILLS_DIR).strip()}
    known |= {feedback_router_block(skills_dir(other)).strip() for other in ALL_TARGETS}
    return "replace" if current in known else "conflict"


def ensure_feedback_router(root: Path, target: str, dry_run: bool) -> list[str]:
    path = root / "AGENTS.md"
    status = managed_router_status(path, target)
    if status == "conflict":
        return [str(path.relative_to(root)) + " has a modified Agent Army feedback-router block"]
    if status == "current":
        print(f"kept {path.relative_to(root)} (feedback-router already current)")
        return []
    block = feedback_router_block(skills_dir(target))
    existing = path.read_text(encoding="utf-8") if path.exists() else "# AGENTS.md\n"
    span = managed_router_span(existing) if status == "replace" else None
    if span:
        # An unedited block for another skill location: update it in place.
        write_text(path, existing[:span[0]] + block.strip() + existing[span[1]:], dry_run)
    else:
        write_text(path, existing.rstrip() + "\n" + block, dry_run)
    return []


def repo_root() -> Path:
    found = subprocess.run(["git", "rev-parse", "--show-toplevel"], text=True, capture_output=True)
    return Path(found.stdout.strip()).resolve() if found.returncode == 0 else Path.cwd().resolve()


def is_tracked(root: Path, path: Path) -> bool:
    """Distinguish committed legacy input from ignored, regenerable staging."""
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", "--", str(path.relative_to(root))],
        cwd=root,
        text=True,
        capture_output=True,
    )
    return result.returncode == 0


def write_text(path: Path, content: str, dry_run: bool) -> None:
    if any(path.resolve() == (ROOT / preserved).resolve() for preserved in PRESERVED_PATHS):
        raise RuntimeError(f"refusing to write user-owned {path.relative_to(ROOT)}")
    print(f"{'plan' if dry_run else '+'} {path.relative_to(ROOT)}")
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_new_text(path: Path, content: str, dry_run: bool) -> None:
    """Create authorable agent sources once; never erase specialization."""
    if path.exists():
        print(f"kept {path.relative_to(ROOT)}")
        return
    write_text(path, content, dry_run)


def model_routing(target: str, previous: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    """Resolve model IDs once at bootstrap; never ask an LLM to manufacture one."""
    supplied = {tier: getattr(args, f"model_{tier}") for tier in ("light", "mid", "strong")}
    supplied_values = [value for value in supplied.values() if value]
    if supplied_values and len(supplied_values) != len(supplied):
        raise ValueError("--model-light, --model-mid and --model-strong must be supplied together")
    if supplied_values and target not in MODEL_CAPABLE_TARGETS:
        raise ValueError(f"{target} has no confirmed native subagent model field")

    if args.role_model_routing == "inherit":
        return {
            "strategy": "inherit",
            "source": "user-disabled",
            "tiers": {},
            "roles": ROLE_CAPABILITY,
            "effort": "unsupported",
            "reason": "user selected inherited subagent models",
        }

    previous_routing = previous.get("model_routing") if isinstance(previous.get("model_routing"), dict) else {}
    previous_tiers = previous_routing.get("tiers") if isinstance(previous_routing.get("tiers"), dict) else {}
    previous_complete = all(isinstance(previous_tiers.get(tier), str) and previous_tiers[tier] for tier in supplied)
    if supplied_values:
        tiers, source = supplied, "user-provided"
    elif target in DEFAULT_MODEL_TIERS:
        tiers, source = DEFAULT_MODEL_TIERS[target], "target-default"
    elif target in MODEL_CAPABLE_TARGETS and previous_routing.get("target") == target and previous_complete:
        tiers, source = {tier: previous_tiers[tier] for tier in supplied}, "previous-bootstrap"
    else:
        reason = (
            "target has no confirmed native subagent model field"
            if target not in MODEL_CAPABLE_TARGETS
            else "exact light/mid/strong model IDs were not provided for this target"
        )
        return {
            "strategy": "inherit",
            "source": "fallback",
            "tiers": {},
            "roles": ROLE_CAPABILITY,
            "effort": "unsupported",
            "reason": reason,
        }

    return {
        "strategy": "per_role_static",
        "source": source,
        "tiers": tiers,
        "roles": ROLE_CAPABILITY,
        "effort": "unsupported",
        "reason": "native agent files select a model per role; the tool selects no effort per role",
    }


def model_line(model: str, capability: str) -> str:
    # JSON strings are valid YAML scalars and safely preserve provider/model IDs.
    return f"model: {json.dumps(model)} {ROLE_MODEL_MARKER} {capability}\n"


def with_role_model(text: str, role: str, routing: dict[str, Any]) -> str:
    """Add a generated model declaration to a baseline definition, when available."""
    if routing["strategy"] != "per_role_static":
        return text
    capability = ROLE_CAPABILITY[role]
    model = routing["tiers"][capability]
    parts = text.split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        raise ValueError(f"baseline {role} has invalid frontmatter")
    frontmatter, body = parts[1], parts[2]
    if re.search(r"^model:\s*", frontmatter, flags=re.MULTILINE):
        raise ValueError(f"baseline {role} already declares model; routing must remain target-owned")
    return "---" + frontmatter + model_line(model, capability) + "---" + body


def reconcile_role_model(path: Path, role: str, routing: dict[str, Any], dry_run: bool) -> None:
    """Update only generated declarations; a user's unmarked model stays untouched."""
    text = path.read_text(encoding="utf-8")
    parts = text.split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        return
    frontmatter, body = parts[1], parts[2]
    existing = re.search(r"^model:.*(?:\s+" + re.escape(ROLE_MODEL_MARKER) + r"\s+\w+)?\s*$", frontmatter, flags=re.MULTILINE)
    managed = existing is not None and ROLE_MODEL_MARKER in existing.group(0)
    desired = None
    capability = ROLE_CAPABILITY[role]
    if routing["strategy"] == "per_role_static":
        desired = model_line(routing["tiers"][capability], capability)

    if existing and not managed:
        return
    if desired is None and not managed:
        return
    if desired is None:
        updated_frontmatter = frontmatter[:existing.start()] + frontmatter[existing.end():]
    elif managed:
        updated_frontmatter = frontmatter[:existing.start()] + desired + frontmatter[existing.end():]
    else:
        updated_frontmatter = frontmatter + desired
    if updated_frontmatter == frontmatter:
        return
    print(f"{'plan' if dry_run else '~'} {path.relative_to(ROOT)} (reconcile generated role model)")
    if not dry_run:
        path.write_text("---" + updated_frontmatter + "---" + body, encoding="utf-8")


def effective_role_models(root: Path, target: str) -> dict[str, dict[str, str | None]]:
    """Snapshot the rendered-source choice, including user-owned overrides."""
    effective: dict[str, dict[str, str | None]] = {}
    if target not in MODEL_CAPABLE_TARGETS:
        return effective
    for role in ROLES:
        path = root / LOCAL_AGENT_SOURCE_DIR / f"agent-army-{role}{LOCAL_AGENT_SUFFIX}"
        if not path.is_file():
            continue
        parts = path.read_text(encoding="utf-8").split("---", 2)
        frontmatter = parts[1] if len(parts) == 3 and not parts[0].strip() else ""
        match = re.search(r"^model:\s*(.*?)(?:\s+#.*)?$", frontmatter, flags=re.MULTILINE)
        value = match.group(1).strip() if match else None
        if value and value.startswith('"'):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                pass
        effective[role] = {
            "capability": ROLE_CAPABILITY[role],
            "model": value,
            "source": "bootstrap" if match and ROLE_MODEL_MARKER in match.group(0) else ("user-override" if value else "inherit"),
        }
    return effective


def migrate_legacy_agent_sources(root: Path, dry_run: bool) -> list[str]:
    """Move old tracked Markdown sources to the non-Markdown local source path."""
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
            print(f"{'plan' if dry_run else 'remove'} {legacy.relative_to(root)} (canonical source wins over regenerable APM staging)")
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


def migrate_legacy_artifacts(root: Path, target: str, dry_run: bool) -> list[str]:
    """Migrate old Agent Army agent sources without touching task documents."""
    conflicts = migrate_legacy_agent_sources(root, dry_run)
    if conflicts:
        return conflicts
    remove_legacy_native_agents(root, target, dry_run)
    return []


def remove_legacy_native_agents(root: Path, target: str, dry_run: bool) -> None:
    """Remove old generated OpenCode agents now that this profile uses main-thread roles."""
    if target != "opencode":
        return
    native_dir = root / ".opencode/agents"
    for agent in sorted(native_dir.glob("agent-army-*.md")):
        print(f"{'plan' if dry_run else 'remove'} {agent.relative_to(root)} (OpenCode main-thread fallback)")
        if not dry_run:
            agent.unlink()


def sync_apm_agent_sources(root: Path, dry_run: bool) -> None:
    """Stage canonical non-Markdown sources for APM's required *.agent.md input."""
    source_dir = root / LOCAL_AGENT_SOURCE_DIR
    staging_dir = root / APM_AGENT_STAGING_DIR
    if not source_dir.is_dir():
        return

    for source in sorted(source_dir.glob(f"agent-army-*{LOCAL_AGENT_SUFFIX}")):
        staging = staging_dir / f"{source.name}.md"
        content = source.read_text(encoding="utf-8")
        if staging.is_file() and staging.read_text(encoding="utf-8") == content:
            print(f"kept {staging.relative_to(root)} (APM staging)")
        else:
            write_text(staging, content, dry_run)

    for staging in sorted(staging_dir.glob(f"agent-army-*{APM_AGENT_SUFFIX}")):
        source = source_dir / staging.name[: -len(".md")]
        if source.is_file():
            continue
        print(f"{'plan' if dry_run else 'remove'} {staging.relative_to(root)} (stale APM staging)")
        if not dry_run:
            staging.unlink()


def agent_source_digests(root: Path) -> dict[str, str]:
    """Digests of the canonical role contracts, recorded when they are staged for APM."""
    source_dir = root / LOCAL_AGENT_SOURCE_DIR
    return {path.name: sha256_file(path) for path in sorted(source_dir.glob(f"agent-army-*{LOCAL_AGENT_SUFFIX}"))}


def agent_sources_need_staging(root: Path, target: str, previous: dict[str, Any] | None = None) -> bool:
    """Tell a current profile to rerender when canonical sources changed since they were last staged.

    Staging is temporary (removed after a successful render), so its absence alone means
    nothing once the profile records the staged digests; older profiles fall back to it.
    """
    if target not in NATIVE_AGENT_TARGETS | {"windsurf"}:
        return False
    source_dir = root / LOCAL_AGENT_SOURCE_DIR
    staging_dir = root / APM_AGENT_STAGING_DIR
    sources = sorted(source_dir.glob(f"agent-army-*{LOCAL_AGENT_SUFFIX}"))
    if not sources:
        return False
    package = (previous or {}).get("package") if isinstance((previous or {}).get("package"), dict) else {}
    staged = package.get("agent_sources")
    if isinstance(staged, dict):
        return staged != agent_source_digests(root)
    if target not in NATIVE_AGENT_TARGETS:
        return False  # windsurf renders without APM staging; an old profile has nothing to compare
    for source in sources:
        staging = staging_dir / f"{source.name}.md"
        if not staging.is_file() or staging.read_bytes() != source.read_bytes():
            return True
    return any(
        staging.is_file()
        and not (source_dir / staging.name[: -len(".md")]).is_file()
        for staging in staging_dir.glob(f"agent-army-*{APM_AGENT_SUFFIX}")
    )


def planning_role_collisions(root: Path, previous: dict[str, Any]) -> list[str]:
    """A newly introduced role path is a conflict unless this profile already owns that role."""
    routing = previous.get("model_routing") if isinstance(previous.get("model_routing"), dict) else {}
    roles = routing.get("roles") if isinstance(routing.get("roles"), dict) else {}
    conflicts = []
    for role in PLANNING_ROLES:
        path = root / LOCAL_AGENT_SOURCE_DIR / f"agent-army-{role}{LOCAL_AGENT_SUFFIX}"
        if role not in roles and path.exists():
            conflicts.append(str(path.relative_to(root)))
    return conflicts


def cleanup_apm_agent_staging(root: Path) -> None:
    """Remove temporary APM Markdown inputs after a successful native render."""
    staging_dir = root / APM_AGENT_STAGING_DIR
    for staging in sorted(staging_dir.glob(f"agent-army-*{APM_AGENT_SUFFIX}")):
        print(f"remove {staging.relative_to(root)} (temporary APM staging)")
        staging.unlink()


def copy_file(source: Path, target: Path, dry_run: bool, executable: bool = False) -> None:
    print(f"{'plan' if dry_run else '+'} {target.relative_to(ROOT)}")
    if dry_run:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    if executable:
        target.chmod(target.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def detect_existing(root: Path, target: str) -> dict[str, list[str]]:
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


def is_agent_army_skills(path: Path) -> bool:
    """Recognise any Agent Army install, including a 0.3.1 one without product skills."""
    return all((path / skill / "SKILL.md").is_file() for skill in CORE_SKILLS) and (path / "bootstrap/bootstrap.py").is_file()


def has_all_skills(path: Path) -> bool:
    return all((path / skill / "SKILL.md").is_file() for skill in SKILLS)


def skill_source_candidates(root: Path, target: str) -> list[Path]:
    candidates = [root / skills_dir(target)]
    if target == "opencode":
        # OpenCode also discovers the shared project skill location. Accept
        # its native directory as a migration source from older installs.
        candidates.append(root / ".opencode/skills")

    # The bootstrap skill may itself be running from an installed package
    # cache (apm_modules/.../.apm/skills) rather than a materialized location.
    candidates.append(HERE.parent)
    modules = root / "apm_modules"
    if modules.is_dir():
        candidates.extend(sorted(modules.glob("**/.apm/skills")))

    unique: list[Path] = []
    for candidate in candidates:
        resolved = candidate.resolve()
        if resolved not in {path.resolve() for path in unique}:
            unique.append(candidate)
    return unique


def skill_digests(skills_root: Path, skill: str) -> dict[str, str]:
    """Hash what the package inventory tracks for one skill: SKILL.md, plus baseline templates for bootstrap."""
    digests: dict[str, str] = {}
    if (skills_root / skill / "SKILL.md").is_file():
        digests[skill] = sha256_file(skills_root / skill / "SKILL.md")
    if skill == "bootstrap":
        baseline = skills_root / "bootstrap/baseline"
        if baseline.is_dir():
            for path in sorted(baseline.rglob("*")):
                if path.is_file() and path.suffix in {".md", ".py", ".yml", ".yaml"}:
                    digests[str(path.relative_to(skills_root))] = sha256_file(path)
    if skill == "product" and (skills_root / ADVISOR_CONTRACT).is_file():
        digests[ADVISOR_CONTRACT] = sha256_file(skills_root / ADVISOR_CONTRACT)
    return digests


def known_package_digests() -> dict[str, set[str]]:
    """File digests of earlier released packages (package-manifests/*.json), keyed by skill-relative path."""
    known: dict[str, set[str]] = {}
    for manifest in sorted((HERE / "package-manifests").glob("*.json")):
        try:
            files = json.loads(manifest.read_text(encoding="utf-8")).get("files", {})
        except (OSError, ValueError):
            continue
        for rel, digest in files.items():
            known.setdefault(rel, set()).add(digest)
    return known


def tree_digests(skill_dir: Path) -> dict[str, str] | None:
    """Digest every regular file under a skill dir; None if it contains a symlink."""
    digests: dict[str, str] = {}
    for path in sorted(skill_dir.rglob("*")):
        if path.is_symlink():
            return None
        if path.is_file():
            digests[str(path.relative_to(skill_dir))] = sha256_file(path)
    return digests


def materialize_skills(
    root: Path, target: str, dry_run: bool, previous_inventory: dict[str, Any] | None = None
) -> tuple[dict[str, Path], list[str]]:
    """Fill and refresh the one skills copy at skills_dir(target); never create a second one.

    Missing skills are copied in from a package source (e.g. when this generator runs from an
    apm_modules cache). A file there is overwritten only when its content equals that file in a
    known released package (package-manifests) or is missing; nothing is ever deleted. A skill with
    any file that matches neither the running package nor a known release (a local change), or with
    a symlink, is kept whole and returned as a conflict.
    """
    destination = root / skills_dir(target)
    added: dict[str, Path] = {}
    kept: list[str] = []
    # The running generator's own package is the newest source when it runs from elsewhere
    # (an apm_modules cache) than the installed copy.
    package = HERE.parent
    if (
        is_agent_army_skills(destination)
        and has_all_skills(package)
        and package.resolve() != destination.resolve()
    ):
        known = known_package_digests()
        for skill in SKILLS:
            dst = destination / skill
            if not dst.exists() and not dst.is_symlink():
                continue
            live = None if dst.is_symlink() or not dst.is_dir() else tree_digests(dst)
            wanted = tree_digests(package / skill) or {}
            if live is None:
                print(f"kept {dst.relative_to(ROOT)} (symlink; not refreshed)")
                kept.append(skill)
                continue
            writes = [rel for rel, digest in wanted.items() if live.get(rel) != digest]
            if not writes:
                continue
            # A dir is a package copy only if its SKILL.md is one; otherwise it is the user's own folder.
            if live.get("SKILL.md") not in known.get(f"{skill}/SKILL.md", set()) | {wanted.get("SKILL.md")}:
                print(f"kept {dst.relative_to(ROOT)} (not an Agent Army copy; not refreshed)")
                kept.append(skill)
                continue
            local = [rel for rel in writes if rel in live and live[rel] not in known.get(f"{skill}/{rel}", set())]
            # A hard-linked file would carry the write outside this copy.
            local += [rel for rel in writes if rel in live and (dst / rel).stat().st_nlink > 1]
            if local:
                print(f"kept {dst.relative_to(ROOT)} (local changes in {', '.join(local[:3])}; not refreshed)")
                kept.append(skill)
                continue
            print(f"{'plan' if dry_run else 'refresh'} {dst.relative_to(ROOT)} (unmodified package files: {len(writes)})")
            added[skill] = package / skill
            if not dry_run:
                for rel in writes:
                    target_file = dst / rel
                    target_file.parent.mkdir(parents=True, exist_ok=True)
                    temp = target_file.with_name(target_file.name + ".agent-army-tmp")
                    shutil.copy2(package / skill / rel, temp)
                    os.replace(temp, target_file)
    if is_agent_army_skills(destination) and has_all_skills(destination):
        return added, kept
    sources = [
        path
        for path in skill_source_candidates(root, target)
        if is_agent_army_skills(path) and path.resolve() != destination.resolve()
    ]
    # Prefer a complete package over an older cache; copy only missing skills.
    source = next((path for path in sources if has_all_skills(path)), sources[0] if sources else None)
    if source is None:
        return added, kept
    for skill in SKILLS:
        src = source / skill
        dst = destination / skill
        if not src.is_dir() or dst.exists():
            continue
        print(f"{'plan' if dry_run else '+'} {dst.relative_to(ROOT)}")
        added[skill] = src
        if not dry_run:
            destination.mkdir(parents=True, exist_ok=True)
            shutil.copytree(src, dst)
    return added, kept


def _raise(error: OSError) -> None:
    raise error


def plain_copy_digests(skill_dir: Path) -> dict[str, str] | None:
    """Digest every file under a dir; None unless all are plain, single-link, readable files.

    A symlink anywhere, a special file, a hard-linked file (st_nlink > 1) or an unreadable entry
    means the dir is not a plain package copy: its content may be reachable elsewhere.
    """
    digests: dict[str, str] = {}
    try:
        for current, dirnames, filenames in os.walk(skill_dir, onerror=_raise):
            for name in dirnames + filenames:
                path = Path(current) / name
                info = path.lstat()
                if stat.S_ISDIR(info.st_mode):
                    continue
                if not stat.S_ISREG(info.st_mode) or info.st_nlink > 1:
                    return None
                digests[str(path.relative_to(skill_dir))] = sha256_file(path)
    except OSError:
        return None
    return digests


def links_into(directory: Path, other: Path) -> bool:
    """True when anything under `directory` (or itself) resolves into `other`."""
    target = other.resolve()
    paths = [directory]
    for current, dirnames, filenames in os.walk(directory):
        paths.extend(Path(current) / name for name in dirnames + filenames)
    for path in paths:
        resolved = path.resolve()
        if resolved == target or target in resolved.parents:
            return True
    return False


def classify_stale_shared_skills(
    root: Path, target: str, planned: dict[str, Path] | None = None
) -> tuple[dict[str, dict[str, str]], list[tuple[str, str]]]:
    """Find the `.agents/skills` copies an earlier bootstrap made for a target that installs elsewhere.

    Returns ({removable skill: its file digests}, [(kept skill, reason)]). A skill dir is removable
    only when it is a real directory (no symlink, no hard-linked or special file anywhere) whose every
    file equals that file in the running package or in a known release (package-manifests), and the
    target's own copy of that skill exists (or is about to be copied, in a dry run) without linking
    into it. Names outside the package are the user's own skills and are never considered. Nothing
    is considered for a target whose skills_dir is the shared location itself.
    """
    live = root / skills_dir(target)
    shared = root / SHARED_SKILLS_DIR
    if Path(skills_dir(target)) == Path(SHARED_SKILLS_DIR):
        return {}, []
    if not shared.exists() and not shared.is_symlink():
        return {}, []
    if shared.is_symlink() or not shared.is_dir() or shared.resolve() != root.resolve() / SHARED_SKILLS_DIR:
        return {}, [(SHARED_SKILLS_DIR, "a symlink, behind a symlink or not a directory")]
    if shared.resolve() in {live.resolve(), HERE.parent.resolve()}:
        # It is the installed copy behind a link, or the package this generator runs from.
        return {}, [(SHARED_SKILLS_DIR, f"in use as {skills_dir(target)} or by the running bootstrap")]
    known = known_package_digests()
    removable: dict[str, dict[str, str]] = {}
    kept: list[tuple[str, str]] = []
    for entry in sorted(shared.iterdir()):
        skill = entry.name
        if skill not in SKILLS:
            continue
        installed = live / skill
        if entry.is_symlink():
            kept.append((skill, "symlink"))
            continue
        if not entry.is_dir():
            kept.append((skill, "not a directory"))
            continue
        if not (installed / "SKILL.md").is_file() and skill not in (planned or {}):
            kept.append((skill, f"no installed copy in {skills_dir(target)}"))
            continue
        if installed.exists() and links_into(installed, entry):
            kept.append((skill, f"{skills_dir(target)}/{skill} links into it"))
            continue
        files = plain_copy_digests(entry)
        if files is None:
            kept.append((skill, "contains a symlink, hard link or special file"))
            continue
        if "SKILL.md" not in files:
            kept.append((skill, "not an Agent Army copy"))
            continue
        package = HERE.parent / skill
        local = [
            rel
            for rel, digest in files.items()
            if digest not in known.get(f"{skill}/{rel}", set())
            and not ((package / rel).is_file() and sha256_file(package / rel) == digest)
        ]
        if local:
            kept.append((skill, f"local changes in {', '.join(local[:3])}"))
            continue
        removable[skill] = files
    return removable, kept


def remove_verified_copy(skill_dir: Path, files: dict[str, str]) -> bool:
    """Unlink only the verified files (re-checked first), then the emptied dirs; never rmtree."""
    try:
        for rel, digest in files.items():
            path = skill_dir / rel
            info = path.lstat()
            if not stat.S_ISREG(info.st_mode) or info.st_nlink > 1 or sha256_file(path) != digest:
                return False
        for rel in files:
            (skill_dir / rel).unlink()
        for current, _dirs, _files in os.walk(skill_dir, topdown=False, onerror=_raise):
            os.rmdir(current)  # fails, and keeps the dir, if anything new appeared in it
    except OSError:
        return False
    return True


def remove_stale_shared_skills(
    root: Path, target: str, dry_run: bool, planned: dict[str, Path] | None = None
) -> list[str]:
    """Remove the unmodified second copy an earlier bootstrap left in `.agents/skills`.

    Returns the kept skill names, for the upgrade review's conflict line. `.agents/skills` itself
    goes only when it ends up empty.
    """
    removable, kept = classify_stale_shared_skills(root, target, planned)
    shared = root / SHARED_SKILLS_DIR
    live = skills_dir(target)
    for name, reason in kept:
        shown = name if name == SHARED_SKILLS_DIR else f"{SHARED_SKILLS_DIR}/{name}"
        print(f"kept {shown} ({reason}; stale copy not removed, {live} is the installed copy)")
    names = [name for name, _reason in kept]
    for skill, files in removable.items():
        print(f"{'plan remove' if dry_run else 'remove'} {SHARED_SKILLS_DIR}/{skill} (unmodified package copy; the one copy is {live}/{skill})")
        if not dry_run and not remove_verified_copy(shared / skill, files):
            print(f"kept {SHARED_SKILLS_DIR}/{skill} (changed during removal; stale copy not fully removed)")
            names.append(skill)
    if removable and shared.is_dir() and not shared.is_symlink():
        left = [entry.name for entry in shared.iterdir() if not (dry_run and entry.name in removable)]
        if not left:
            print(f"{'plan remove' if dry_run else 'remove'} {SHARED_SKILLS_DIR} (empty)")
            if not dry_run:
                try:
                    shared.rmdir()  # never rmtree: fails, and keeps it, if anything appeared
                except OSError:
                    print(f"kept {SHARED_SKILLS_DIR} (no longer empty)")
    return names


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package_inventory(root: Path, target: str) -> dict[str, dict[str, str]]:
    """Hash only the live installed package materials; never inspect cache content for review."""
    skills_root = root / skills_dir(target)
    if not skills_root.is_dir():
        return {"skills": {}, "templates": {}}
    skills = {
        skill: sha256_file(skills_root / skill / "SKILL.md")
        for skill in SKILLS
        if (skills_root / skill / "SKILL.md").is_file()
    }
    # The shared advisor contract changes every product skill's behavior, so it is reviewed too.
    if (skills_root / ADVISOR_CONTRACT).is_file():
        skills[ADVISOR_CONTRACT] = sha256_file(skills_root / ADVISOR_CONTRACT)
    baseline = skills_root / "bootstrap/baseline"
    templates: dict[str, str] = {}
    if baseline.is_dir():
        for path in sorted(baseline.rglob("*")):
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
    root: Path,
    target: str,
    from_version: str | None,
    delta: dict[str, dict[str, list[str]]],
    kept_skills: list[str] | None = None,
    stale_kept: list[str] | None = None,
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
    if kept_skills:
        print(f"  conflict: local changes kept, not refreshed to {PACKAGE_VERSION}: {', '.join(kept_skills)} (merge by hand, or move the dir away to receive the package copy)")
    if stale_kept:
        print(
            f"  conflict: stale {SHARED_SKILLS_DIR} copies kept (not identical to a package release; "
            f"{skills_dir(target)} is the one installed copy): {', '.join(stale_kept)} "
            "(move any local change into a repo-local skill or AGENTS.md, then delete the dir)"
        )
    for name in delta["templates"]["changed"]:
        role = re.fullmatch(r"bootstrap/baseline/core/agents/([a-z-]+)\.md", name)
        if role and role.group(1) in ROLES:
            local = f"{LOCAL_AGENT_SOURCE_DIR}/agent-army-{role.group(1)}{LOCAL_AGENT_SUFFIX}"
            print(f"  recommended local diff: {name} -> {local} (merge into the specialization, never replace it)")
    print(f"  inspect before recommending a local diff: {skills_dir(target)}, AGENTS.md, .agent-army/agents")
    print("  decision: apply selected | apply all | show details | skip")


def source_agent(role: str, target: str, routing: dict[str, Any]) -> str:
    text = (BASE / "core/agents" / f"{role}.md").read_text(encoding="utf-8")
    # APM owns native conversion. These are the local authoring sources, with
    # the installed skill path made explicit for the selected target.
    text = text.replace("<SKILLS_DIR>", skills_dir(target)).replace("<AGENTS_DIR>", LOCAL_AGENT_SOURCE_DIR).replace("<TOOL_DIR>", ".agent-army")
    return with_role_model(text, role, routing)


def existing_profile(root: Path) -> dict[str, Any]:
    try:
        profile = json.loads((root / ".agent-army/config.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return profile if profile.get("version") == PROFILE_SCHEMA_VERSION else {}


def installed_package_version(profile: dict[str, Any]) -> str | None:
    package = profile.get("package")
    if isinstance(package, dict) and isinstance(package.get("version"), str):
        return package["version"]
    return None


def resolve_bootstrap_mode(previous: dict[str, Any], target: str, requested: str) -> tuple[str, str | None]:
    """Choose a safe mode; target switches and downgrades require an explicit full bootstrap."""
    if not previous:
        if requested == "incremental":
            raise ValueError("no existing Agent Army profile; incremental mode needs a prior bootstrap")
        return "initial" if requested == "auto" else "full", None

    previous_target = previous.get("target")
    if previous_target and previous_target != target:
        if requested != "full":
            raise ValueError(f"profile target is {previous_target}; run with --mode full to switch to {target}")
        return "full", installed_package_version(previous)

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
    if version_key(installed) < version_key(PACKAGE_VERSION):
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
        or args.model_light
        or args.model_mid
        or args.model_strong
        or args.role_model_routing == "inherit"
        or args.upgrade_review_outcome is not None
    )


def apply_incremental_changes(root: Path, target: str, dry_run: bool) -> list[str]:
    """Apply idempotent, package-owned fragments without version-specific routes."""
    return ensure_feedback_router(root, target, dry_run) + migrate_legacy_artifacts(root, target, dry_run)


def needs_package_maintenance(previous: dict[str, Any], root: Path, target: str) -> bool:
    """Detect incomplete state or changed live package material on every update."""
    package = previous.get("package") if isinstance(previous.get("package"), dict) else {}
    # A pre-0.3 install kept permanent *.agent.md sources here; temporary staging for a
    # canonical .agent-army/agents contract is not legacy.
    legacy_agents = any(
        legacy.is_file() and not (root / LOCAL_AGENT_SOURCE_DIR / legacy.name[: -len(".md")]).is_file()
        for legacy in (root / APM_AGENT_STAGING_DIR).glob(f"agent-army-*{APM_AGENT_SUFFIX}")
    )
    legacy_native_agents = previous.get("target") == "opencode" and any(
        agent.is_file() for agent in (root / ".opencode/agents").glob("agent-army-*.md")
    )
    return (
        not isinstance(package.get("inventory"), dict)
        or has_inventory_delta(inventory_delta(package, package_inventory(root, target)))
        or managed_router_status(root / "AGENTS.md", target) != "current"
        or legacy_agents
        or legacy_native_agents
        # Only a removable stale copy; a kept conflict alone does not reopen the review.
        or bool(classify_stale_shared_skills(root, target)[0])
    )


def hook_document(event: str, action: str) -> str:
    # APM hook primitives use event-name -> list.  The nested shape is the
    # Claude-compatible representation that APM can translate for targets
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


def write_ci(root: Path, mode: str, evidence: list[str], dry_run: bool) -> tuple[str, list[str]]:
    if mode != "army":
        return mode, evidence
    path = root / ".github/workflows/agent-army-quality.yml"
    if path.exists() and not owns_marker(path.read_text(encoding="utf-8", errors="ignore")):
        return "blocked", [str(path.relative_to(root))]
    copy_file(BASE / ".github/workflows/quality.yml", path, dry_run)
    return "army", [str(path.relative_to(root))]


def write_runtime_sources(root: Path, target: str, install_hooks: bool, dry_run: bool) -> None:
    copy_file(BASE / "runtime.py", root / ".agent-army/runtime.py", dry_run, executable=True)
    if install_hooks and target in RUNTIME_TARGETS:
        for event, action in (("PreToolUse", "guard"), ("PostToolUse", "format"), ("SubagentStop", "verify"), ("Stop", "gate")):
            write_text(root / f".apm/hooks/agent-army-{action}.json", hook_document(event, action), dry_run)
    elif install_hooks:
        print(f"note runtime_hooks: {target} has no supported native runtime hook adapter")


def write_agents(
    root: Path, target: str, routing: dict[str, Any], dry_run: bool, add_missing: bool = True, reconcile: bool = True
) -> None:
    """Degraded targets also need write_degraded_adapters after this, with the recorded digests."""
    """Write missing role contracts when allowed, reconcile existing ones, and stage every existing one."""
    for role in ROLES:
        path = root / LOCAL_AGENT_SOURCE_DIR / f"agent-army-{role}{LOCAL_AGENT_SUFFIX}"
        if path.exists():
            if reconcile:
                reconcile_role_model(path, role, routing, dry_run)
        elif add_missing:
            write_text(path, source_agent(role, target, routing), dry_run)
    if target in NATIVE_AGENT_TARGETS:
        sync_apm_agent_sources(root, dry_run)


DEGRADED_TARGETS = {"gemini", "windsurf"}


def degraded_adapter_files(root: Path, target: str) -> dict[str, str]:
    """The adapter file each existing role contract renders to: {repo-relative path: content}."""
    files: dict[str, str] = {}
    for role in ROLES:
        source = root / LOCAL_AGENT_SOURCE_DIR / f"agent-army-{role}{LOCAL_AGENT_SUFFIX}"
        if not source.is_file():
            continue
        text = source.read_text(encoding="utf-8")
        if target == "gemini":
            # APM 0.19 did not deploy project Gemini agents. Keep the adapter local and explicit.
            files[f".gemini/agents/agent-army-{role}.md"] = text
        elif target == "windsurf":
            # Windsurf has no native subagent file; named skills retain roles without
            # pretending that it can delegate to native subagents.
            files[f".windsurf/skills/agent-army-{role}/SKILL.md"] = (
                "---\nname: agent-army-" + role + "\ndescription: Agent Army fallback role for Windsurf.\n---\n\n" + text
            )
    return files


def write_degraded_adapters(
    root: Path, target: str, dry_run: bool, recorded: dict[str, str] | None = None
) -> dict[str, str]:
    """Render the degraded adapter files and return the digests to record for them.

    A file is (re)written when it is missing or still equals what this generator last wrote
    (its recorded digest); a file changed by hand is kept and reported, never overwritten.
    """
    recorded = recorded if isinstance(recorded, dict) else {}
    outputs: dict[str, str] = {}
    for rel, content in degraded_adapter_files(root, target).items():
        path = root / rel
        digest = hashlib.sha256(content.encode("utf-8")).hexdigest()
        if path.is_symlink():
            print(f"kept {rel} (symlink; not refreshed)")
            if rel in recorded:
                outputs[rel] = recorded[rel]
            continue
        if path.is_file():
            live = sha256_file(path)
            if live == digest:
                outputs[rel] = digest
                continue
            if live != recorded.get(rel):
                print(f"kept {rel} (local changes; not refreshed — delete it to regenerate)")
                if rel in recorded:
                    outputs[rel] = recorded[rel]
                continue
        write_text(path, content, dry_run)
        outputs[rel] = digest
    return outputs


def update_gitignore(root: Path, target: str, dry_run: bool) -> None:
    path = root / ".gitignore"
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    # Only the shared .agents/skills copy is ignored; a tool's own skill dir (.claude/skills) also holds
    # the user's skills, so ignoring it would hide them.
    entries = [".agent-army/state.json"]
    if skills_dir(target) == ".agents/skills":
        entries.insert(0, ".agents/skills/")
    if target in NATIVE_AGENT_TARGETS:
        entries.insert(1, f"{APM_AGENT_STAGING_DIR}/")
    missing = [entry for entry in entries if entry not in existing.splitlines()]
    if missing:
        write_text(path, existing.rstrip() + "\n" + "\n".join(missing) + "\n", dry_run)


def run_apm(root: Path, target: str) -> tuple[int, bool]:
    apm = shutil.which("apm")
    if not apm:
        print("WARN: apm not found; generated sources are ready, run `apm install --frozen --target %s` later." % target, file=sys.stderr)
        return 0, False
    manifest = root / "apm.yml"
    if not manifest.exists():
        # Package-style installs can deploy skills without creating a project
        # manifest. Promote those installed skills into a local APM project so
        # the frozen second pass does not remove the bootstrap command itself.
        installed_skills = root / skills_dir(target)
        if not installed_skills.is_dir() and target == "opencode":
            # Migrate a project that was initially installed into OpenCode's
            # native directory before using the shared compatible path.
            installed_skills = root / ".opencode/skills"
        local_skills = root / ".apm/skills"
        if not installed_skills.is_dir():
            print("WARN: no apm.yml and no installed skill directory; local agent sources were generated but cannot be rendered by APM.", file=sys.stderr)
            return 0, False
        if local_skills.exists():
            print("WARN: no apm.yml but .apm/skills already exists; refusing to guess ownership. Run `apm lock` and `apm install --frozen --target %s` yourself." % target, file=sys.stderr)
            return 0, False
        shutil.copytree(installed_skills, local_skills)
        write_text(manifest, f"name: agent-army-profile\nversion: {PACKAGE_VERSION}\ndescription: Local Agent Army bootstrap profile\nincludes: auto\ndependencies:\n  apm: []\n  mcp: []\n", False)
        lock = subprocess.run([apm, "lock"], cwd=root)
        if lock.returncode != 0:
            return lock.returncode, False
    command = [apm, "install", "--frozen", "--target", target]
    result = subprocess.run(command, cwd=root)
    return result.returncode, result.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=sorted(ALL_TARGETS))
    parser.add_argument("--runtime-hooks", choices=("army", "external", "disabled"))
    parser.add_argument("--git-precommit", choices=("army", "external", "disabled"))
    parser.add_argument("--ci", choices=("army", "external", "disabled"))
    parser.add_argument("--role-model-routing", choices=("auto", "inherit"), default="auto")
    parser.add_argument("--model-light", metavar="MODEL", help="exact target-native model ID for light roles")
    parser.add_argument("--model-mid", metavar="MODEL", help="exact target-native model ID for mid roles")
    parser.add_argument("--model-strong", metavar="MODEL", help="exact target-native model ID for strong roles")
    parser.add_argument("--mode", choices=("auto", "incremental", "full"), default="auto", help="auto-detect, migrate only, or intentionally re-specialize")
    parser.add_argument("--upgrade-review-outcome", choices=("applied", "skipped"), help="record the user's resolved Incremental Upgrade Review")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-apm", action="store_true", help="test-only: do not run apm install")
    args = parser.parse_args()

    global ROOT
    ROOT = repo_root()
    previous = existing_profile(ROOT)
    try:
        bootstrap_mode, from_version = resolve_bootstrap_mode(previous, args.target, args.mode)
    except ValueError as exc:
        parser.error(str(exc))
    restage_only = False
    profile_change_only = False
    if bootstrap_mode == "current":
        if needs_package_maintenance(previous, ROOT, args.target):
            bootstrap_mode = "incremental"
            print("Agent Army package is current; applying the pending shared-skills correction and upgrade review.")
        elif agent_sources_need_staging(ROOT, args.target, previous):
            bootstrap_mode = "full"
            restage_only = True
            print("Agent Army canonical agent sources changed; refreshing native output.")
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
    if bootstrap_mode == "incremental":
        print(f"\nAgent Army incremental migration plan: {from_version or 'legacy profile'} -> {PACKAGE_VERSION}")
        print("  apply: AGENTS.md managed feedback-router block; package metadata; inventory refresh")
        print("  preserve: .agent-army/agents, .agent-army/stores.json, model routing, quality policy and external controls")
        print("  local role contracts: add the new planning roles only when the upgrade review is applied")
        conflicts = apply_incremental_changes(ROOT, args.target, args.dry_run)
        if conflicts:
            print("ERROR: incremental migration needs a human decision:", file=sys.stderr)
            for conflict in conflicts:
                print(f"  - {conflict}", file=sys.stderr)
            return 2
    else:
        conflicts = migrate_legacy_artifacts(ROOT, args.target, args.dry_run)
        if conflicts:
            print("ERROR: bootstrap migration needs a human decision:", file=sys.stderr)
            for conflict in conflicts:
                print(f"  - {conflict}", file=sys.stderr)
            return 2
        # The managed router block belongs to every profile; without it each later run would
        # report a pending correction. A block the user edited is left alone.
        router = managed_router_status(ROOT / "AGENTS.md", args.target)
        if router in {"append", "replace"}:
            ensure_feedback_router(ROOT, args.target, args.dry_run)
        elif router == "conflict":
            print("note AGENTS.md: the Agent Army feedback-router block was edited; kept as is")
    try:
        routing = model_routing(args.target, previous, args)
    except ValueError as exc:
        parser.error(str(exc))
    previous_modes = previous.get("enforcement", {}) if isinstance(previous.get("enforcement"), dict) else {}
    def prior_mode(name: str) -> str | None:
        value = previous_modes.get(name)
        mode = value.get("mode") if isinstance(value, dict) else None
        return mode if mode in {"army", "external", "disabled"} else None
    found = detect_existing(ROOT, args.target)
    selections = {
        "runtime_hooks": args.runtime_hooks or prior_mode("runtime_hooks") or ("external" if found["runtime_hooks"] else "army"),
        "git_precommit": args.git_precommit or prior_mode("git_precommit") or ("external" if found["git_precommit"] else "army"),
        "ci": args.ci or prior_mode("ci") or ("external" if found["ci"] else "army"),
    }
    if args.target == "opencode" and selections["runtime_hooks"] == "army":
        selections["runtime_hooks"] = "blocked"

    previous_package = previous.get("package") if isinstance(previous.get("package"), dict) else {}
    previous_inventory = previous_package.get("inventory") if isinstance(previous_package.get("inventory"), dict) else {}
    planned_skills, kept_skills = materialize_skills(ROOT, args.target, args.dry_run, previous_inventory)
    # The one copy is where APM installed the skills; drop the unmodified second copy an earlier
    # bootstrap made in .agents/skills (only for targets that install elsewhere, e.g. Claude).
    stale_kept = remove_stale_shared_skills(ROOT, args.target, args.dry_run, planned_skills)
    inventory = package_inventory(ROOT, args.target)
    if args.dry_run:
        # Preview the review the real run will show once skills are copied or refreshed.
        for skill, src in planned_skills.items():
            for name, digest in skill_digests(src.parent, skill).items():
                inventory["templates" if "/" in name else "skills"][name] = digest
    delta = inventory_delta(previous_package, inventory)
    if bootstrap_mode == "incremental":
        print_upgrade_review(ROOT, args.target, from_version, delta, kept_skills, stale_kept)
    if bootstrap_mode == "incremental" and args.upgrade_review_outcome == "skipped":
        print("preserve: local role contracts and model routing (Incremental Upgrade Review skipped)")
        # Stage the existing contracts so APM's frozen pass keeps their native output; add none.
        write_agents(ROOT, args.target, routing, args.dry_run, add_missing=False, reconcile=False)
    else:
        # A re-render after edited contracts stages them; it never adds a role the user did not choose.
        write_agents(ROOT, args.target, routing, args.dry_run, add_missing=not (restage_only or profile_change_only))
    adapter_outputs: dict[str, str] = {}
    if args.target in DEGRADED_TARGETS:
        adapter_outputs = write_degraded_adapters(ROOT, args.target, args.dry_run, previous_package.get("adapter_outputs"))
    routing["effective_roles"] = effective_role_models(ROOT, args.target)
    if "army" in selections.values():
        write_runtime_sources(ROOT, args.target, selections["runtime_hooks"] == "army", args.dry_run)
    git_mode, git_evidence = install_precommit(ROOT, selections["git_precommit"], found["git_precommit"], args.dry_run)
    ci_mode, ci_evidence = write_ci(ROOT, selections["ci"], found["ci"], args.dry_run)
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
        "target": args.target,
        "profile": "agent-army",
        "package": {
            "name": "agent-army",
            "version": PACKAGE_VERSION,
            "profile_schema_version": PROFILE_SCHEMA_VERSION,
            "inventory": inventory,
            **({"agent_sources": agent_source_digests(ROOT)} if args.target in NATIVE_AGENT_TARGETS | {"windsurf"} else {}),
            **({"adapter_outputs": adapter_outputs} if args.target in DEGRADED_TARGETS else {}),
            **({"upgrade_review": review} if review else {}),
        },
        "model_routing": {"target": args.target, **routing},
        "quality": previous.get("quality") if isinstance(previous.get("quality"), dict) else default_quality(ROOT),
        "policy": previous.get("policy") if isinstance(previous.get("policy"), dict) else {},
        "enforcement": {
            "runtime_hooks": {"mode": selections["runtime_hooks"], "evidence": found["runtime_hooks"]},
            "git_precommit": {"mode": git_mode, "evidence": git_evidence},
            "ci": {"mode": ci_mode, "evidence": ci_evidence},
        },
    }
    write_text(ROOT / ".agent-army/config.json", json.dumps(config, indent=2) + "\n", args.dry_run)
    update_gitignore(ROOT, args.target, args.dry_run)
    print(f"\nAgent Army package {PACKAGE_VERSION} status (profile schema v{PROFILE_SCHEMA_VERSION}):")
    for layer, value in config["enforcement"].items():
        print(f"  {layer}: {value['mode']}" + (f" ({', '.join(value['evidence'])})" if value["evidence"] else ""))
    print(f"  role model routing: {routing['strategy']} ({routing['source']}; effort: {routing['effort']})")
    if args.dry_run or args.skip_apm:
        return 0
    result, rendered = run_apm(ROOT, args.target)
    if rendered:
        cleanup_apm_agent_staging(ROOT)
        # APM may clean directories it does not integrate. Reassert only the
        # explicitly degraded adapters after its native pass; do not recreate
        # the temporary APM staging files.
        if args.target in DEGRADED_TARGETS:
            write_degraded_adapters(ROOT, args.target, False, adapter_outputs)
    return result


if __name__ == "__main__":
    raise SystemExit(main())
