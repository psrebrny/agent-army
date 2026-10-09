#!/usr/bin/env python3
"""advisor-eval harness: runs one advisor through the scenario fixtures and appends scorecard rows.

Mechanics only. The protocol, its isolation rules and the decision rule are described in SKILL.md
(next to this file) and in tests/fixtures/advisors/rubric.md. Quality is scored by a blind LLM judge,
never by this script; the script only scores `cost` and applies the decision rule.

Usage:
  run.py <advisor> [--scenario S1 ...] [--arms N,K] [--with-reference --reference-dir DIR]
         [--model MODEL] [--web scenario|on|off] [--plan-only] [--no-ledger]
"""
import argparse
import datetime
import hashlib
import json
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
FIXTURES = REPO / "tests" / "fixtures" / "advisors"
RUBRIC = FIXTURES / "rubric.md"
LEDGER = FIXTURES / "SCORECARDS.md"
SKILLS = REPO / ".apm" / "skills"
REFERENCE_COMMIT = "8607e3b"
SAFETY_STOP = 20  # user turns per session; a guard against loops, not a target
DONE_REPLY = re.compile(r"^\s*ok,?\s*thanks\b", re.I)
JUDGE_CRITERIA = ["false_facts", "fad_separability", "falsifiability", "smallest_next_step",
                  "resume", "decision_change", "not_assessed", "pace"]
ACTOR_TOOLS = "Read,Write,Edit,Glob,Grep"
WEB_TOOLS = "WebSearch,WebFetch"
# Variables that bind a child `claude -p` to the parent Claude session (its ID, transcript stream or
# messaging socket). Each eval process must be an independent session, so they are removed.
PARENT_SESSION_VARS = re.compile(r"SESSION|INGRESS|MESSAGING|^CLAUDECODE$|^CLAUDE_CODE_(REMOTE_SDK_URL|"
                                 r"TEE_SDK_STDOUT|REMOTE_SEND_KEEPALIVES|INCLUDE_PARTIAL_MESSAGES)$")
CHILD_ENV = {k: v for k, v in os.environ.items() if not PARENT_SESSION_VARS.search(k)}


def die(msg):
    sys.exit(f"advisor-eval: {msg}")


def claude(args, cwd, prompt):
    """One `claude -p` call; returns the parsed JSON result."""
    cmd = ["claude", "-p", "--output-format", "json", "--strict-mcp-config",
           "--setting-sources", "project", *args, prompt]
    out = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=CHILD_ENV,
                         stdin=subprocess.DEVNULL)
    try:
        res = json.loads(out.stdout)
    except json.JSONDecodeError:
        die(f"claude -p returned no JSON (exit {out.returncode}): {out.stderr.strip()[:400]}")
    if res.get("is_error"):
        die(f"claude -p error: {str(res.get('result'))[:400]}")
    return res


def find_scenarios(ids):
    all_dirs = sorted(p for p in FIXTURES.glob("S*") if p.is_dir())
    if not ids:
        return all_dirs
    picked = []
    for sid in ids:
        match = [p for p in all_dirs if p.name == sid or p.name.startswith(sid + "-")]
        if not match:
            die(f"no scenario {sid} in {FIXTURES}")
        picked += match
    return picked


def snapshot(root):
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob("*") if p.is_file() and not _ignored(p.relative_to(root))}


def _ignored(rel):
    return rel.parts[0] in (".git", ".claude")


def assemble(scenario, arm, advisor, reference_dir, base):
    scratch = Path(tempfile.mkdtemp(prefix=f"{scenario.name}-", dir=base))
    shutil.copytree(FIXTURES / "shared", scratch, dirs_exist_ok=True)
    if (scenario / "repo").is_dir():
        shutil.copytree(scenario / "repo", scratch, dirs_exist_ok=True)
    skills = scratch / ".claude" / "skills"
    if arm == "N":
        shutil.copytree(SKILLS / advisor, skills / advisor)
    elif arm == "P":
        shutil.copytree(reference_dir, skills, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns(".git"))
    subprocess.run(["git", "init", "-q"], cwd=scratch, check=True)
    leaked = [p for p in scratch.rglob("expected.md")] + [p for p in scratch.rglob("user.md")]
    if leaked:
        die(f"oracle or persona leaked into the actor scratch: {leaked}")
    return scratch


def converse(scratch, opening, persona, actor_args, persona_dir, label):
    """One multi-turn session: actor and simulated user alternate until the actor is done."""
    actor_sid, persona_sid = str(uuid.uuid4()), str(uuid.uuid4())
    turns, totals = [], {"num_turns": 0, "total_cost_usd": 0.0, "duration_ms": 0}
    persona_cost = 0.0
    message, stopped = opening, False
    for i in range(SAFETY_STOP + 1):
        sid_args = ["--session-id", actor_sid] if i == 0 else ["--resume", actor_sid]
        res = claude([*actor_args, *sid_args], scratch, message)
        for k in totals:
            totals[k] += res.get(k) or 0
        reply = res.get("result", "")
        turns.append({"user": message, "advisor": reply, "seconds": round((res.get("duration_ms") or 0) / 1000)})
        p_sid = ["--session-id", persona_sid] if i == 0 else ["--resume", persona_sid]
        p_res = claude(["--system-prompt", persona, "--tools", "", *p_sid], persona_dir,
                       f"The advisor says:\n\n{reply}")
        persona_cost += p_res.get("total_cost_usd") or 0
        answer = p_res.get("result", "").strip()
        if DONE_REPLY.match(answer):
            break
        message = answer
    else:
        stopped = True
    print(f"  {label}: {len(turns)} advisor turns{' (safety stop hit)' if stopped else ''}")
    return turns, totals, stopped, persona_cost


def transcript(turns):
    out = []
    for n, t in enumerate(turns, 1):
        out.append(f"### User\n\n{t['user']}\n\n### Advisor (turn {n}, {t['seconds']} s)\n\n{t['advisor']}\n")
    return "\n".join(out)


def cost_score(t):
    def band(v, two, one):
        return 2 if v <= two else 1 if v <= one else 0
    return min(band(t["num_turns"], 30, 60), band(t["total_cost_usd"], 1.50, 3.00),
               band(t["duration_ms"] / 60000, 10, 20))


def judge(scenario, bundles, base, model_args):
    jdir = Path(tempfile.mkdtemp(prefix="judge-", dir=base))
    (jdir / "scenario").mkdir()
    for f in ("request.md", "resume.md", "expected.md"):
        shutil.copy(scenario / f, jdir / "scenario" / f)
    rubric = RUBRIC.read_text().split("<!-- harness-only -->")[0]
    rubric = rubric.rsplit("<!-- The section below is for the harness", 1)[0]
    (jdir / "rubric.md").write_text(rubric)
    for bid, src in bundles.items():
        shutil.copytree(src, jdir / "bundles" / bid)
    labels = re.compile(r"\barm [NKP]\b|advisor-eval|control arm|reference arm|pm-skills", re.I)
    for p in jdir.rglob("*"):
        if p.is_file() and p.name != "rubric.md" and labels.search(p.read_text(errors="ignore")):
            print(f"  warning: possible arm hint in judge input {p.relative_to(jdir)}")
    res = claude([*model_args, "--tools", "Read,Glob,Grep", "--append-system-prompt", rubric],
                 jdir, "Score every bundle in bundles/ now. Reply with the JSON object only.")
    text = res.get("result", "")
    m = re.search(r"\{.*\}", text, re.S)
    if not m:
        die(f"judge returned no JSON; judge dir kept at {jdir}")
    return json.loads(m.group(0)), jdir, res.get("total_cost_usd") or 0


def verdict(rows):
    if "N" not in rows:
        return "baseline"
    n = rows["N"]
    if n["ff"] > 0:
        return "fix-contract"
    if "K" in rows and n["sum"] - rows["K"]["sum"] <= 2:
        return "rethink"
    if "P" in rows and sum(p >= q for p, q in zip(rows["P"]["scores"], n["scores"])) >= 5:
        return "consider-absorb"
    return "pass"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("advisor")
    ap.add_argument("--scenario", nargs="*", default=[])
    ap.add_argument("--arms", default="N,K")
    ap.add_argument("--with-reference", action="store_true")
    ap.add_argument("--reference-dir", type=Path)
    ap.add_argument("--model")
    ap.add_argument("--web", choices=["scenario", "on", "off"], default="scenario",
                    help="web tools for the actor: as the scenario's `web-on` file says, or forced")
    ap.add_argument("--plan-only", action="store_true", help="assemble and check isolation, run no model")
    ap.add_argument("--no-ledger", action="store_true")
    a = ap.parse_args()

    arms = [x.strip().upper() for x in a.arms.split(",") if x.strip()]
    if a.with_reference:
        arms.append("P")
        if not a.reference_dir or not a.reference_dir.is_dir():
            die("--with-reference needs --reference-dir pointing at a pm-skills checkout")
        head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=a.reference_dir,
                              capture_output=True, text=True).stdout.strip()
        if not head.startswith(REFERENCE_COMMIT):
            die(f"reference checkout is at {head[:12]}, expected {REFERENCE_COMMIT}")
    skill_md = SKILLS / a.advisor / "SKILL.md"
    if "N" in arms and not skill_md.is_file():
        die(f"arm N needs {skill_md.relative_to(REPO)}")
    sha = hashlib.sha256(skill_md.read_bytes()).hexdigest()[:12] if skill_md.is_file() else "-"
    tag = "-"
    if skill_md.is_file():
        m = re.search(r"<!-- (advisor-contract:v\d+) -->", skill_md.read_text())
        tag = m.group(1) if m else "-"

    base = Path(tempfile.mkdtemp(prefix="advisor-eval-"))
    if REPO in base.parents:
        die("scratch must be outside the source repo")
    model_args = ["--model", a.model] if a.model else []
    print(f"advisor-eval: {a.advisor}, arms {','.join(arms)}; scratch {base}")

    for scenario in find_scenarios(a.scenario):
        sid = scenario.name.split("-")[0]
        persona = (scenario / "user.md").read_text()
        web = (scenario / "web-on").exists() if a.web == "scenario" else a.web == "on"
        actor_args = [*model_args, "--tools", ACTOR_TOOLS + ("," + WEB_TOOLS if web else ""),
                      "--permission-mode", "acceptEdits"]
        bundles, ids, costs, notes, overhead = {}, {}, {}, [], 0.0
        for arm in arms:
            scratch = assemble(scenario, arm, a.advisor, a.reference_dir, base)
            if a.plan_only:
                print(f"  {sid} arm {arm}: scratch {scratch} (isolation checks passed)")
                continue
            persona_dir = Path(tempfile.mkdtemp(prefix="persona-", dir=base))
            before = snapshot(scratch)
            invoke = f"/{a.advisor} " if arm == "N" else ""
            t1, c1, s1, pc1 = converse(scratch, invoke + (scenario / "request.md").read_text(),
                                  persona, actor_args, persona_dir, f"{sid} {arm} session 1")
            t2, c2, s2, pc2 = converse(scratch, invoke + (scenario / "resume.md").read_text(),
                                  persona, actor_args, persona_dir, f"{sid} {arm} session 2")
            bid = "%06x" % random.getrandbits(24)
            bundle = base / "bundles" / bid
            (bundle / "files").mkdir(parents=True)
            (bundle / "session-1.md").write_text(transcript(t1))
            (bundle / "session-2.md").write_text(transcript(t2))
            after = snapshot(scratch)
            for rel, h in after.items():
                if before.get(rel) != h:
                    dst = bundle / "files" / rel
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy(scratch / rel, dst)
            bundles[bid], ids[arm] = bundle, bid
            costs[arm] = {k: c1[k] + c2[k] for k in c1}
            overhead += pc1 + pc2
            if s1 or s2:
                notes.append(f"{arm} hit safety stop")
        if a.plan_only:
            continue

        result, jdir, judge_cost = judge(scenario, bundles, base, model_args)
        overhead += judge_cost
        by_id = {b["id"]: b for b in result.get("bundles", [])}
        rows = {}
        for arm, bid in ids.items():
            b = by_id.get(bid)
            if not b:
                die(f"judge skipped bundle {bid}; judge dir kept at {jdir}")
            scores = [int(b["scores"][c]) for c in JUDGE_CRITERIA] + [cost_score(costs[arm])]
            rows[arm] = {"scores": scores, "sum": sum(scores), "ff": int(b.get("false_fact_count", 0)),
                         "note": b.get("note", "")}
            c = costs[arm]
            notes.append(f"{arm}: {c['num_turns']} turns, ${c['total_cost_usd']:.2f}, "
                         f"{c['duration_ms'] / 60000:.1f} min; {rows[arm]['note']}")
        notes.append(f"harness overhead ${overhead:.2f} (persona + judge; not scored)")
        v = verdict(rows)
        cells = "; ".join(f"{arm} {'/'.join(map(str, r['scores']))} Σ{r['sum']} ff{r['ff']}"
                          for arm, r in rows.items())
        note = " | ".join(notes).replace("|", "/").replace("\n", " ")
        sid_label = sid + (" web" if web else "") if (scenario / "web-on").exists() or a.web != "scenario" else sid
        row = (f"| {datetime.date.today()} | {a.advisor} | {tag} | {sha} | {','.join(rows)} | {sid_label} | "
               f"{cells} | {v} | {note} |")
        print(row)
        if not a.no_ledger:
            with LEDGER.open("a") as f:
                f.write(row + "\n")
    print(f"advisor-eval: transcripts stay in {base}")


if __name__ == "__main__":
    main()
