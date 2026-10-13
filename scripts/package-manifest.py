#!/usr/bin/env python3
"""Write the file digests of a released package, so later generators can recognise its unmodified copies.

Usage: scripts/package-manifest.py <version> <git-commit>
Writes .apm/skills/bootstrap/package-manifests/<version>.json from `git archive <commit> .apm/skills`.
Add the previous release's manifest before publishing a new version.
"""
import hashlib, io, json, pathlib, subprocess, sys, tarfile

root = pathlib.Path(__file__).resolve().parents[1]
version, commit = sys.argv[1], sys.argv[2]
archive = subprocess.run(["git", "-C", str(root), "archive", commit, ".apm/skills"], check=True, capture_output=True).stdout
files = {}
with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
    for member in tar.getmembers():
        if member.isfile() and "/package-manifests/" not in member.name:
            rel = member.name[len(".apm/skills/"):]
            files[rel] = hashlib.sha256(tar.extractfile(member).read()).hexdigest()
out = root / ".apm/skills/bootstrap/package-manifests" / f"{version}.json"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({"version": version, "commit": commit, "files": dict(sorted(files.items()))}, indent=1) + "\n")
print(f"{out.relative_to(root)}: {len(files)} files")
