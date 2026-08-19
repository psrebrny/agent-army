#!/usr/bin/env python3
"""Create an Agent Army v0.2 profile in the current repository.

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
RUNTIME_TARGETS = {"claude", "codex", "cursor", "copilot", "gemini", "windsurf"}
AGENT_TARGETS = {"claude", "codex", "cursor", "copilot", "opencode", "gemini"}
ALL_TARGETS = AGENT_TARGETS | {"windsurf"}
MARKER = "# agent-army-v0.2"


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


def source_agent(role: str) -> str:
    text = (BASE / "core/agents" / f"{role}.md").read_text(encoding="utf-8")
    # APM owns native conversion.  These are only the local cross-target source.
    return text.replace("<SKILLS_DIR>", ".agents/skills").replace("<AGENTS_DIR>", ".apm/agents").replace("<TOOL_DIR>", ".agent-army")


def existing_profile(root: Path) -> dict[str, Any]:
    try:
        profile = json.loads((root / ".agent-army/config.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return profile if profile.get("version") == 2 else {}


def hook_document(event: str, action: str) -> str:
    # APM hook primitives use event-name -> list.  The nested shape is the
    # Claude-compatible representation that APM can translate for targets
    # which expose a corresponding lifecycle event.
    return json.dumps({event: [{"matcher": ".*", "hooks": [{"type": "command", "command": f"python3 .agent-army/runtime.py {action}"}]}]}, indent=2) + "\n"


def precommit_shim() -> str:
    return "#!/usr/bin/env bash\n" + MARKER + "\nexec python3 \"$(git rev-parse --show-toplevel)/.agent-army/runtime.py\" precommit\n"


def install_precommit(root: Path, mode: str, evidence: list[str], dry_run: bool) -> tuple[str, list[str]]:
    if mode != "army":
        return mode, evidence
    hooks_path = subprocess.run(["git", "config", "core.hooksPath"], cwd=root, text=True, capture_output=True).stdout.strip()
    hook = root / (hooks_path if hooks_path else ".git/hooks") / "pre-commit"
    if hook.exists() and MARKER not in hook.read_text(encoding="utf-8", errors="ignore"):
        # A shell hook can be safely appended. Anything else remains user-owned.
        data = hook.read_text(encoding="utf-8", errors="ignore")
        if not data.startswith("#!") or not re.search(r"^#!.*(?:ba)?sh", data):
            return "blocked", [str(hook.relative_to(root))]
        addition = f"\n{MARKER}\npython3 \"$(git rev-parse --show-toplevel)/.agent-army/runtime.py\" precommit || exit 1\n"
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
    if path.exists() and "agent-army-v0.2" not in path.read_text(encoding="utf-8", errors="ignore"):
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


def write_agents(root: Path, target: str, dry_run: bool) -> None:
    if target in AGENT_TARGETS:
        for role in ROLES:
            write_new_text(root / f".apm/agents/agent-army-{role}.agent.md", source_agent(role), dry_run)
    if target == "gemini":
        # APM 0.19 does not yet deploy project Gemini agents. Keep the adapter
        # local and explicit until that primitive is supported upstream.
        for role in ROLES:
            write_new_text(root / f".gemini/agents/agent-army-{role}.md", source_agent(role), dry_run)
    elif target == "windsurf":
        # Windsurf has no native subagent file; named skills retain roles without
            # pretending that it can delegate to native subagents.
        for role in ROLES:
            content = "---\nname: agent-army-" + role + "\ndescription: Agent Army fallback role for Windsurf.\n---\n\n" + source_agent(role)
            write_new_text(root / f".windsurf/skills/agent-army-{role}/SKILL.md", content, dry_run)


def update_gitignore(root: Path, dry_run: bool) -> None:
    path = root / ".gitignore"
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    entries = [".agents/skills/", ".agent-army/state.json"]
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
        installed_skills = root / ".agents/skills"
        local_skills = root / ".apm/skills"
        if not installed_skills.is_dir():
            print("WARN: no apm.yml and no installed .agents/skills; local agent sources were generated but cannot be rendered by APM.", file=sys.stderr)
            return 0
        if local_skills.exists():
            print("WARN: no apm.yml but .apm/skills already exists; refusing to guess ownership. Run `apm lock` and `apm install --frozen --target %s` yourself." % target, file=sys.stderr)
            return 0
        shutil.copytree(installed_skills, local_skills)
        write_text(manifest, "name: agent-army-profile\nversion: 0.2.0\ndescription: Local Agent Army bootstrap profile\nincludes: auto\ndependencies:\n  apm: []\n  mcp: []\n", False)
        lock = subprocess.run([apm, "lock"], cwd=root)
        if lock.returncode != 0:
            return lock.returncode
    result = subprocess.run([apm, "install", "--frozen", "--target", target], cwd=root)
    return result.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=sorted(ALL_TARGETS))
    parser.add_argument("--runtime-hooks", choices=("army", "external", "disabled"))
    parser.add_argument("--git-precommit", choices=("army", "external", "disabled"))
    parser.add_argument("--ci", choices=("army", "external", "disabled"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-apm", action="store_true", help="test-only: do not run apm install")
    args = parser.parse_args()

    global ROOT
    ROOT = repo_root()
    previous = existing_profile(ROOT)
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

    write_agents(ROOT, args.target, args.dry_run)
    if "army" in selections.values():
        write_runtime_sources(ROOT, args.target, selections["runtime_hooks"] == "army", args.dry_run)
    git_mode, git_evidence = install_precommit(ROOT, selections["git_precommit"], found["git_precommit"], args.dry_run)
    ci_mode, ci_evidence = write_ci(ROOT, selections["ci"], found["ci"], args.dry_run)
    config = {
        "version": 2,
        "target": args.target,
        "profile": "agent-army",
        "quality": previous.get("quality") if isinstance(previous.get("quality"), dict) else default_quality(ROOT),
        "policy": previous.get("policy") if isinstance(previous.get("policy"), dict) else {},
        "enforcement": {
            "runtime_hooks": {"mode": selections["runtime_hooks"], "evidence": found["runtime_hooks"]},
            "git_precommit": {"mode": git_mode, "evidence": git_evidence},
            "ci": {"mode": ci_mode, "evidence": ci_evidence},
        },
    }
    write_text(ROOT / ".agent-army/config.json", json.dumps(config, indent=2) + "\n", args.dry_run)
    update_gitignore(ROOT, args.dry_run)
    print("\nAgent Army v2 status:")
    for layer, value in config["enforcement"].items():
        print(f"  {layer}: {value['mode']}" + (f" ({', '.join(value['evidence'])})" if value["evidence"] else ""))
    if args.dry_run or args.skip_apm:
        return 0
    result = run_apm(ROOT, args.target)
    # APM may clean directories it does not integrate. Reassert the two
    # explicitly degraded adapters after its native pass.
    if result == 0 and args.target in {"gemini", "windsurf"}:
        write_agents(ROOT, args.target, False)
    return result


if __name__ == "__main__":
    raise SystemExit(main())
