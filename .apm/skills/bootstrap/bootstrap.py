#!/usr/bin/env python3
"""Create and incrementally migrate an Agent Army v0.3.0 profile.

This is intentionally deterministic.  The chat skill decides *what the project
needs*; this program owns filesystem layout, ownership boundaries and the APM
handoff.  It never rewrites a user-owned hook or workflow.
"""
from __future__ import annotations

import argparse
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
ROLES = ("architect", "coder", "tester", "code-reviewer", "security-auditor", "perf-auditor", "docs-writer")
SKILLS = ("bootstrap", "ship", "new-agent", "new-skill", "adapt-army")
RUNTIME_TARGETS = {"claude", "codex", "cursor", "copilot", "gemini", "windsurf"}
AGENT_TARGETS = {"claude", "codex", "cursor", "copilot", "opencode", "gemini"}
ALL_TARGETS = AGENT_TARGETS | {"windsurf"}
PACKAGE_VERSION = "0.3.0"
PROFILE_SCHEMA_VERSION = 2
OWNERSHIP_MARKER = "# agent-army-owned"
LEGACY_OWNERSHIP_MARKERS = ("# agent-army-v0.2",)
MIGRATION_020_TO_030 = "0.2.0-to-0.3.0-feedback-router"
MANAGED_ROUTER_START = "<!-- agent-army:feedback-router:start -->"
MANAGED_ROUTER_END = "<!-- agent-army:feedback-router:end -->"
ROLE_CAPABILITY = {
    "architect": "strong",
    "coder": "mid",
    "tester": "light",
    "code-reviewer": "strong",
    "security-auditor": "strong",
    "perf-auditor": "mid",
    "docs-writer": "light",
}
MODEL_CAPABLE_TARGETS = {"claude", "cursor", "opencode"}
# Claude documents these portable tier names. Other adapters require their exact
# model IDs, which bootstrap receives explicitly rather than inventing them.
DEFAULT_MODEL_TIERS = {
    "claude": {"light": "haiku", "mid": "sonnet", "strong": "opus"},
}
ROLE_MODEL_MARKER = "# agent-army-role-profile:"


def version_key(value: str) -> tuple[int, int, int]:
    """Compare the package's stable semver releases without extra dependencies."""
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", value)
    if not match:
        raise ValueError(f"unsupported Agent Army version: {value}")
    return tuple(int(part) for part in match.groups())


def owns_marker(text: str) -> bool:
    return OWNERSHIP_MARKER in text or any(marker in text for marker in LEGACY_OWNERSHIP_MARKERS)


def feedback_router_block() -> str:
    """A small, explicitly-owned extension safe to add to specialized AGENTS.md files."""
    return """\n""" + MANAGED_ROUTER_START + """
## Keeping Agent Army current

When the user corrects an agent, identifies a repeatable weakness, asks for a better workflow, or
needs a missing specialist, first fix the current task inside its approved scope. Then classify the
lesson with `.agents/skills/adapt-army/SKILL.md`: task-local correction, repo convention, existing
agent, existing skill, deterministic control, new agent, or new skill. Never modify the Army
silently. Show an **Army Improvement Proposal** with the evidence, recommended target, write scope,
verification and one approval question. Durable proposals and decisions live locally in
`.agent-army/state.json`; do not store raw user text or secrets there. A package-wide issue is an
upstream candidate, not permission to edit another repository.

Core skills in `.agents/skills/` are APM-managed. A repo-specific extension to one goes in
`.agent-army/overrides/skills/<skill>.md`; it may refine local behavior but cannot weaken security,
approval gates or hard rules. New local skills belong in `.apm/skills/` and are rendered by APM.
""" + MANAGED_ROUTER_END + """\n"""


def managed_router_status(path: Path) -> str:
    """Return append, current or conflict without touching user-authored AGENTS content."""
    if not path.exists():
        return "append"
    text = path.read_text(encoding="utf-8")
    start = text.find(MANAGED_ROUTER_START)
    end = text.find(MANAGED_ROUTER_END)
    if start == -1 and end == -1:
        return "append"
    if start == -1 or end == -1 or end < start:
        return "conflict"
    current = text[start:end + len(MANAGED_ROUTER_END)].strip()
    expected = feedback_router_block().strip()
    return "current" if current == expected else "conflict"


def ensure_feedback_router(root: Path, dry_run: bool) -> list[str]:
    path = root / "AGENTS.md"
    status = managed_router_status(path)
    if status == "conflict":
        return [str(path.relative_to(root)) + " has a modified Agent Army feedback-router block"]
    if status == "current":
        print(f"kept {path.relative_to(root)} (feedback-router migration already applied)")
        return []
    existing = path.read_text(encoding="utf-8") if path.exists() else "# AGENTS.md\n"
    write_text(path, existing.rstrip() + "\n" + feedback_router_block(), dry_run)
    return []


def repo_root() -> Path:
    found = subprocess.run(["git", "rev-parse", "--show-toplevel"], text=True, capture_output=True)
    return Path(found.stdout.strip()).resolve() if found.returncode == 0 else Path.cwd().resolve()


def write_text(path: Path, content: str, dry_run: bool) -> None:
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
    elif previous_routing.get("target") == target and previous_complete:
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
    if target not in AGENT_TARGETS:
        return effective
    for role in ROLES:
        path = root / f".apm/agents/agent-army-{role}.agent.md"
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


def skills_dir(target: str) -> str:
    """Return the installed skill location for the selected target."""
    return ".agents/skills"


def is_agent_army_skills(path: Path) -> bool:
    return all((path / skill / "SKILL.md").is_file() for skill in SKILLS) and (path / "bootstrap/bootstrap.py").is_file()


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


def materialize_skills(root: Path, target: str, dry_run: bool) -> None:
    destination = root / skills_dir(target)
    if is_agent_army_skills(destination):
        return
    source = next((path for path in skill_source_candidates(root, target) if is_agent_army_skills(path)), None)
    if source is None or source.resolve() == destination.resolve():
        return
    for skill in SKILLS:
        src = source / skill
        dst = destination / skill
        if not src.is_dir() or dst.exists():
            continue
        print(f"{'plan' if dry_run else '+'} {dst.relative_to(ROOT)}")
        if not dry_run:
            destination.mkdir(parents=True, exist_ok=True)
            shutil.copytree(src, dst)


def source_agent(role: str, target: str, routing: dict[str, Any]) -> str:
    text = (BASE / "core/agents" / f"{role}.md").read_text(encoding="utf-8")
    # APM owns native conversion. These are the local authoring sources, with
    # the installed skill path made explicit for the selected target.
    text = text.replace("<SKILLS_DIR>", skills_dir(target)).replace("<AGENTS_DIR>", ".apm/agents").replace("<TOOL_DIR>", ".agent-army")
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
    # v0.2 profiles used schema version 2 but had no package metadata.
    if profile.get("version") == PROFILE_SCHEMA_VERSION and profile.get("profile") == "agent-army":
        return "0.2.0"
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
        raise ValueError(f"profile is already current at Agent Army {PACKAGE_VERSION}")
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
    )


def migrate_profile(root: Path, previous: dict[str, Any], from_version: str, dry_run: bool) -> tuple[list[str], list[str]]:
    """Apply narrowly-scoped, idempotent migrations before normal rendering.

    The return values are applied migration IDs and conflicts. A conflict means no
    configuration or rendering should proceed, so a hand-edited managed block is
    never overwritten as a side effect of an APM update.
    """
    applied: list[str] = []
    conflicts: list[str] = []
    if version_key(from_version) < version_key("0.3.0"):
        conflicts.extend(ensure_feedback_router(root, dry_run))
        if not conflicts:
            applied.append(MIGRATION_020_TO_030)
    return applied, conflicts


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
    if hook.exists() and owns_marker(hook.read_text(encoding="utf-8", errors="ignore")):
        data = hook.read_text(encoding="utf-8", errors="ignore")
        updated = data
        for marker in LEGACY_OWNERSHIP_MARKERS:
            updated = updated.replace(marker, OWNERSHIP_MARKER + "\n# agent-army-package: " + PACKAGE_VERSION)
        if updated != data:
            write_text(hook, updated, dry_run)
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


def write_agents(root: Path, target: str, routing: dict[str, Any], dry_run: bool) -> None:
    if target in AGENT_TARGETS:
        for role in ROLES:
            path = root / f".apm/agents/agent-army-{role}.agent.md"
            if path.exists():
                reconcile_role_model(path, role, routing, dry_run)
            else:
                write_text(path, source_agent(role, target, routing), dry_run)
    if target == "gemini":
        # APM 0.19 does not yet deploy project Gemini agents. Keep the adapter
        # local and explicit until that primitive is supported upstream.
        for role in ROLES:
            write_new_text(root / f".gemini/agents/agent-army-{role}.md", source_agent(role, target, routing), dry_run)
    elif target == "windsurf":
        # Windsurf has no native subagent file; named skills retain roles without
        # pretending that it can delegate to native subagents.
        for role in ROLES:
            content = "---\nname: agent-army-" + role + "\ndescription: Agent Army fallback role for Windsurf.\n---\n\n" + source_agent(role, target, routing)
            write_new_text(root / f".windsurf/skills/agent-army-{role}/SKILL.md", content, dry_run)


def update_gitignore(root: Path, target: str, dry_run: bool) -> None:
    path = root / ".gitignore"
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    entries = [f"{skills_dir(target)}/", ".agent-army/state.json"]
    missing = [entry for entry in entries if entry not in existing.splitlines()]
    if missing:
        write_text(path, existing.rstrip() + "\n" + "\n".join(missing) + "\n", dry_run)


def run_apm(root: Path, target: str) -> int:
    apm = shutil.which("apm")
    if not apm:
        print("WARN: apm not found; generated sources are ready, run `apm install --frozen --target %s` later." % target, file=sys.stderr)
        return 0
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
            return 0
        if local_skills.exists():
            print("WARN: no apm.yml but .apm/skills already exists; refusing to guess ownership. Run `apm lock` and `apm install --frozen --target %s` yourself." % target, file=sys.stderr)
            return 0
        shutil.copytree(installed_skills, local_skills)
        write_text(manifest, "name: agent-army-profile\nversion: 0.3.0\ndescription: Local Agent Army bootstrap profile\nincludes: auto\ndependencies:\n  apm: []\n  mcp: []\n", False)
        lock = subprocess.run([apm, "lock"], cwd=root)
        if lock.returncode != 0:
            return lock.returncode
    command = [apm, "install", "--frozen", "--target", target]
    result = subprocess.run(command, cwd=root)
    return result.returncode


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
    if bootstrap_mode == "current":
        if not has_explicit_profile_change(args):
            print(f"Agent Army {PACKAGE_VERSION} profile is current; no incremental changes needed. Use --mode full to re-specialize.")
            return 0
        bootstrap_mode = "full"
        print("Agent Army package is current; applying explicitly requested profile configuration changes.")
    applied_migrations: list[str] = []
    if bootstrap_mode == "incremental":
        print(f"\nAgent Army incremental migration plan: {from_version} -> {PACKAGE_VERSION}")
        print("  apply: AGENTS.md managed feedback-router block; package metadata; owned marker refresh")
        print("  preserve: .apm/agents, model routing, quality policy and external controls")
        applied_migrations, conflicts = migrate_profile(ROOT, previous, from_version or "0.2.0", args.dry_run)
        if conflicts:
            print("ERROR: incremental migration needs a human decision:", file=sys.stderr)
            for conflict in conflicts:
                print(f"  - {conflict}", file=sys.stderr)
            return 2
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

    materialize_skills(ROOT, args.target, args.dry_run)
    write_agents(ROOT, args.target, routing, args.dry_run)
    routing["effective_roles"] = effective_role_models(ROOT, args.target)
    if "army" in selections.values():
        write_runtime_sources(ROOT, args.target, selections["runtime_hooks"] == "army", args.dry_run)
    git_mode, git_evidence = install_precommit(ROOT, selections["git_precommit"], found["git_precommit"], args.dry_run)
    ci_mode, ci_evidence = write_ci(ROOT, selections["ci"], found["ci"], args.dry_run)
    previous_package = previous.get("package") if isinstance(previous.get("package"), dict) else {}
    recorded_migrations = previous_package.get("applied_migrations") if isinstance(previous_package.get("applied_migrations"), list) else []
    migrations = [migration for migration in recorded_migrations if isinstance(migration, str)]
    for migration in applied_migrations:
        if migration not in migrations:
            migrations.append(migration)
    config = {
        "version": PROFILE_SCHEMA_VERSION,
        "target": args.target,
        "profile": "agent-army",
        "package": {
            "name": "agent-army",
            "version": PACKAGE_VERSION,
            "profile_schema_version": PROFILE_SCHEMA_VERSION,
            "applied_migrations": migrations,
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
    result = run_apm(ROOT, args.target)
    # APM may clean directories it does not integrate. Reassert the two
    # explicitly degraded adapters after its native pass.
    if result == 0 and args.target in {"gemini", "windsurf"}:
        write_agents(ROOT, args.target, routing, False)
    return result


if __name__ == "__main__":
    raise SystemExit(main())
