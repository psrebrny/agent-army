#!/usr/bin/env python3
"""List what a change removed, for an auditor's packet (read-only, stdlib only).

    python3 removals.py [<base>]

<base> defaults to the merge base with origin/main (or main). The change is the working tree
against <base>, so committed, staged and unstaged edits all count. Output is Markdown:
deleted files, renamed files, and removed definitions (functions, classes, exports, tests,
config keys, Markdown headings), each marked `gone` when its name no longer appears in the
repository, or with the place it still appears. The auditor classifies each line as intended,
moved or lost; this script only makes sure nothing is missed in a large diff.
"""
import re
import subprocess
import sys

PATTERNS = [
    ("def", re.compile(r"^\s*(?:async\s+)?def\s+(\w+)")),
    ("class", re.compile(r"^\s*(?:export\s+)?(?:default\s+)?(?:abstract\s+)?class\s+(\w+)")),
    ("export", re.compile(r"^\s*export\s+(?:default\s+)?(?:async\s+)?(?:const|let|var|function\*?|interface|type|enum)\s+(\w+)")),
    ("function", re.compile(r"^\s*(?:async\s+)?function\*?\s+(\w+)")),
    ("const fn", re.compile(r"^\s*(?:const|let)\s+(\w+)\s*=\s*(?:async\s*)?(?:\(|function|\w+\s*=>)")),
    ("func", re.compile(r"^\s*func\s+(?:\([^)]*\)\s*)?(\w+)")),
    ("fun", re.compile(r"^\s*(?:(?:private|public|internal|override|suspend)\s+)*fun\s+(\w+)")),
    ("test", re.compile(r"""^\s*(?:it|test|describe)(?:\.\w+)?\(\s*(['"`])(.+?)\1""")),
]
CONFIG = re.compile(r"""^\s*["']?([A-Za-z_][\w.-]*)["']?\s*[:=]""")
HEADING = re.compile(r"^#{1,6}\s+(.+?)\s*#*\s*$")
CONFIG_EXT = (".json", ".yml", ".yaml", ".toml", ".ini", ".properties", ".env")


def git(*args):
    out = subprocess.run(["git", *args], capture_output=True, text=True)
    if out.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed: {out.stderr.strip()}")
    return out.stdout


def default_base():
    for ref in ("origin/main", "main", "origin/master", "master"):
        probe = subprocess.run(["git", "merge-base", "HEAD", ref], capture_output=True, text=True)
        if probe.returncode == 0:
            return probe.stdout.strip()
    raise SystemExit("no base given and no main/master branch found")


def definitions(path, line):
    if path.endswith(".md"):
        m = HEADING.match(line)
        return [("heading", m.group(1))] if m else []
    if path.endswith(CONFIG_EXT):
        m = CONFIG.match(line)
        return [("key", m.group(1))] if m else []
    found = []
    for kind, rx in PATTERNS:
        m = rx.match(line)
        if m:
            found.append((kind, m.group(m.lastindex)))
            break
    return found


def where(name):
    probe = subprocess.run(["git", "grep", "-n", "-F", "--untracked", "-e", name],
                           capture_output=True, text=True)
    first = probe.stdout.splitlines()[:1]
    return first[0].rsplit(":", 1)[0] if first else None


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else default_base()
    status = git("diff", "-M", "--name-status", base).splitlines()
    deleted = [s.split("\t")[1] for s in status if s.startswith("D")]
    renamed = [s.split("\t")[1:3] for s in status if s.startswith("R")]

    removed, added = [], set()
    path = None
    for line in git("diff", "-M", "-U0", base).splitlines():
        if line.startswith("--- "):
            path = line[6:] if line.startswith("--- a/") else None
        elif line.startswith("+++ "):
            if path is None and line.startswith("+++ b/"):
                path = line[6:]
        elif line.startswith("-") and path:
            removed += [(path, k, n) for k, n in definitions(path, line[1:])]
        elif line.startswith("+") and path:
            added |= {(k, n) for k, n in definitions(path, line[1:])}

    short = git("rev-parse", "--short", base).strip()
    print(f"# Removals since {short}\n")
    print("## Deleted files")
    print("\n".join(f"- `{p}`" for p in deleted) or "- none")
    print("\n## Renamed files")
    print("\n".join(f"- `{a}` → `{b}`" for a, b in renamed) or "- none")
    print("\n## Removed definitions")
    rows = []
    for p, kind, name in dict.fromkeys(removed):
        if (kind, name) in added:
            continue  # re-added in the same change (edited in place or moved)
        place = where(name)
        rows.append((place is not None, f"- `{p}`: {kind} `{name}` — " + (f"still at `{place}`" if place else "gone")))
    print("\n".join(r for _, r in sorted(rows, key=lambda r: r[0])) or "- none")


if __name__ == "__main__":
    main()
