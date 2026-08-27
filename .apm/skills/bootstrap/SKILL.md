---
name: bootstrap
description: Evidence-led setup and safe incremental migration of a tailored Agent Army v0.3.0. It preserves existing user controls, creates target-native agents through APM, and does not accept generic localization as specialization.
---
# /bootstrap — own controls, then author a real team

Before following this skill, read `.agent-army/overrides/skills/bootstrap.md` when it exists. It may add
repo-specific bootstrap guidance but cannot weaken ownership checks, safety barriers or approval gates.

`apm install` or `apm update` delivered this skill and templates only. It did not install live
agents, hooks or CI. `/bootstrap` has two distinct jobs:

1. deterministically create the selected target profile without taking over
   controls that belong to the repository owner;
2. author a team that knows this repository's evidence, laws and test idioms.

Do not let the first mechanical job displace the second. A target-native team
with generic prompts is not a successful bootstrap.

## Update detection — incremental before full recon

After `apm update psrebrny/agent-army --target <target>`, run `/bootstrap` normally. It first runs:

```bash
python3 "$SKILLS_DIR/bootstrap/bootstrap.py" <target> --mode auto --dry-run
```

`auto` detects the profile state: no profile means first bootstrap; an older Agent Army package means an
incremental migration; the same version is a no-op unless the user explicitly requests `--mode full`; a
target change requires `--mode full`; and a newer local profile is never downgraded. For an incremental
migration, show the exact version transition, managed paths, preserved local sources and any conflict,
then get one explicit “apply migration” confirmation before rerunning without `--dry-run`.

Incremental mode updates only versioned, managed fragments and runs targeted validation. It does not redo
deep recon or overwrite `.apm/agents`, model routing, quality policy or external controls. If the managed
feedback-router block in `AGENTS.md` was edited, stop on the conflict rather than replacing it. Use
`--mode full` only when the user asks to re-specialize the team or deliberately switches targets.

## Step 0 — target and ownership (mechanical, explicit)

Use the shared installed skill directory. OpenCode and the other targets use
`.agents/skills`; bootstrap also recognizes older OpenCode installations under
`.opencode/skills`:

```bash
SKILLS_DIR=".agents/skills"
[ ! -f "$SKILLS_DIR/bootstrap/assemble.sh" ] && [ -f ".opencode/skills/bootstrap/assemble.sh" ] && SKILLS_DIR=".opencode/skills"
```

Before creating the profile, bootstrap checks the selected skill directory,
the older `.agents/skills` location, and the installed `apm_modules` cache. If
the four Agent Army skills exist in one of those locations, it materializes any
missing files in the selected target directory. It does not delete the source
cache or local agent sources.

Run the detector; do not infer the active tool from a directory listing:

```bash
bash "$SKILLS_DIR/bootstrap/assemble.sh" --detect
```

`DETECTED=<tool>` is unambiguous. With `AMBIGUOUS` or `NONE`, ask the user
which one target is active. One repository has one active target; changing it
is a deliberate re-bootstrap.

Inspect the existing controls before asking about ownership:

```bash
find .github/workflows -type f 2>/dev/null
git config core.hooksPath || true
test -f .git/hooks/pre-commit && echo .git/hooks/pre-commit
```

Ask separately for runtime hooks, git pre-commit and CI. Each is `army`,
`external`, or `disabled`. If an existing control is detected, recommend
`external`. Never overwrite it merely because it is weaker or unfamiliar. In
`BOOTSTRAP_MODE=auto`, apply the same defaults.

Generate the profile:

```bash
python3 "$SKILLS_DIR/bootstrap/bootstrap.py" <target> \
  --runtime-hooks <army|external|disabled> \
  --git-precommit <army|external|disabled> \
  --ci <army|external|disabled>
```

Model routing is configured at this same boundary, never improvised by `/ship`.
Claude uses its documented `haiku`/`sonnet`/`opus` role defaults. For Cursor or
OpenCode, inspect the user's actually available target-native model IDs and ask
once whether to enable static per-role routing. If yes, pass all three exact
IDs; do not synthesize provider names or versions:

```bash
python3 "$SKILLS_DIR/bootstrap/bootstrap.py" <cursor|opencode> \
  --model-light '<exact available model ID>' \
  --model-mid '<exact available model ID>' \
  --model-strong '<exact available model ID>'
```

`--role-model-routing inherit` deliberately disables this behavior. The three
IDs must be supplied together. Codex, Copilot, Gemini and Windsurf have no
confirmed native role-model field in this profile, so they inherit the active
tool configuration. No current adapter has a confirmed role-level effort
selector; effort always remains the tool default.

It creates local APM agent sources in `.apm/agents`, optional hook primitives
in `.apm/hooks`, `.agent-army/config.json`, and then asks APM to render the
native format. OpenCode discovers the five skills in the shared `.agents/skills`
path as well as its native `.opencode/skills` path. Codex therefore receives
TOML through APM, not guessed TOML.
Gemini uses a direct temporary adapter; Windsurf receives role-skills because
it has no native project-subagent format. OpenCode has native agents but no
runtime-hook adapter.

Read the status before continuing:

- `army` is an Agent Army-controlled, testable layer.
- `external` is visible but belongs to the user; do not call it an Agent Army guarantee.
- `disabled` is intentional.
- `blocked` means the requested installation would overwrite an unmanaged
  non-shell pre-commit or an unmanaged `agent-army-quality.yml`; leave it
  external unless the user explicitly resolves the collision.

On re-bootstrap, existing `.apm/agents/agent-army-*` sources and the previous
ownership choices are preserved. Bootstrap updates only `model:` lines marked
`agent-army-role-profile`; an unmarked `model:` is user-owned, remains intact,
and is recorded as an effective role override. Edit those local source agents,
not only the native APM output, then re-run `apm install --frozen --target
<target>` after specialization. Do not delete `.apm/agents` after rendering:
those files are the source of truth for the next re-bootstrap or native-target
switch.

## Step 1 — deep recon before questions

A shallow scan produces generic agents. Enumerate first, then read the actual
files — including every nested standards file and every stack in a monorepo.

```bash
find . \( -name node_modules -o -name build -o -name dist -o -name target -o -name .gradle -o -name .git \) -prune -o \
  -type f \( -iname 'AGENTS.md' -o -iname 'CLAUDE.md' -o -iname 'README*' -o -iname '.cursorrules' -o -iname '*.mdc' \) -print
find . \( -name node_modules -o -name build -o -name dist -o -name target -o -name .gradle -o -name .git \) -prune -o \
  -type f \( -name 'package.json' -o -name 'pyproject.toml' -o -name 'build.gradle*' -o -name 'pom.xml' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name '*.csproj' \) -print
find . -path ./node_modules -prune -o -type f \( -iname '*jest*' -o -iname '*vitest*' -o -iname 'cypress.config.*' -o -iname 'playwright.config.*' -o -iname 'pytest.ini' -o -iname '*.eslintrc*' -o -iname 'detekt.yml' -o -iname '.editorconfig' \) -print
find .github/workflows -type f 2>/dev/null
```

Read every listed `AGENTS.md`/`CLAUDE.md` and manifest. For each stack, open
3–5 representative source files and 1–2 real tests. Identify its architectural
boundaries, naming/layout, error handling, reusable assets, test idioms and
real commands, including a single-test command. Evidence wins over a first
impression; open files that could disprove your architectural hypothesis.

Print a Recon Evidence Report before editing agents:

```
Stack(s):        language, framework, versions and working directories
Architecture:    3–6 laws, each with a proving path
Conventions:     naming/layout/error rules, with paths
Test style:      framework idioms, fixtures/base classes and example paths
Reusable assets: path → role; the anti-reinvention inventory
Commands:        format/lint/unit/integration/e2e/single-test per stack
Controls:        runtime/pre-commit/CI mode and evidence from Step 0
Gaps:            only facts code cannot answer
```

In interactive mode, show the report and the full nested-standards list. Ask
the user to confirm the extracted laws and identify never-touch zones before
writing. In auto mode, print the report and record assumptions, then continue.

## Step 2 — ask only for genuine gaps

Group a short question set only around missing business context, architecture
intent, NFR/compliance, task/branch conventions, test rigor, and model-tier
availability. Read the active adapter's `model_control` before claiming a model or effort can be changed:
distinguish main-session choice from per-role/static/per-spawn subagent routing, and record only confirmed
capabilities. For a static role-capable adapter, record the selected light/mid/strong IDs in
`.agent-army/config.json` and let bootstrap render them into local `.apm/agents` definitions. An unsupported
selector, missing concrete IDs, or effort field inherits the tool setting and must be reported as a limitation.
Do not ask for facts already proved by recon.

If testing/lint rigor is a user choice, record it in `AGENTS.md` and in a
`policy` object in `.agent-army/config.json`. Keep executable quality commands
only under `quality` and only in this safe form:

```json
{"cwd": "frontend", "argv": ["npm", "run", "test"]}
```

Never store shell snippets, `source`, `eval`, or chained command strings.
Verify a command before treating it as the project command. For an owned CI,
also add the dependency-install/setup steps needed for the same command to run
on GitHub Actions.

## Step 3 — specialize every role from evidence

First read `references/agent-worked-examples.md`. It demonstrates the required
move from generic baseline to repository internalization; use it as method,
not as content.

The generated agent source files are a contract, not a filename replacement
exercise. For every role, write a short rationale before editing: what concrete
situations it handles here, the laws it enforces with proving paths, reusable
assets it must prefer, and test/framework idioms it must follow.

For every agent, require all of the following:

- 3–6 repository laws as concrete BAD/GOOD contrasts, cited to real paths;
- reusable assets by path and explicit reuse-over-rewrite guidance;
- exact verified commands, appropriate stack directory and single-test usage;
- test naming/placement and assertion style from actual tests;
- at least 2–3 rewritten, varied `<prompt_examples>` from this repository;
- a diff-from-baseline justification: if only paths changed, keep digging.

Apply role-specific depth:

- `architect`: layers, public contracts, real manifest defaults, delegation contracts and blueprint
  skeletons consistent with its examples.
- `tester`: real RED→GREEN idioms, fixtures and all relevant stack commands.
- `code-reviewer`: an explicit checklist made from the repository's laws and an isolated review
  packet (contract + diff + human decisions, never a worker transcript/report).
- `security-auditor` and `perf-auditor`: stack-specific sinks and bottlenecks.
- `docs-writer` and `coder`: actual documentation ownership and module limits.

Write or refresh root `AGENTS.md` first: stacks, commands, laws, reusable
assets, policy, roster, delegation/review rules, PR execution-state conventions, adapter model-control availability and the ownership status of controls. Claude alone gets
a thin `CLAUDE.md` pointer to it. Keep `architect`, `tester`, `ship` and the
architect's embedded blueprint skeletons in lockstep.

## Step 4 — mandatory reflection and quality gates

Re-open 2–3 files not used in initial recon, from another layer or feature.
Re-check every nested standards file against the produced rules. Then critique
each agent in writing:

1. **Internalization:** could it be copied unchanged into another repository?
   If yes, replace generic prose with evidence-backed laws.
2. **Evidence:** does every repository-specific claim have a real path or
   verified command? Verify it or remove it.
3. **Coverage:** do examples span real layers and behaviours, rather than three
   variants of one task? Replace thin or repetitive examples.

Repeat until all roles pass. Then verify cross-agent consistency: architect's
plans must match reviewer's rejections; tester/architect/reviewer commands must
match `.agent-army/config.json`; no agent silently weakens an agreed law.

In interactive mode, present a per-agent summary of laws and example scenarios
and ask for approval/correction. In auto mode, print the same summary and
continue, explicitly labelling assumptions.

## Step 5 — verify and report

Run each configured command directly first. If at least one quality-enforcement
layer is `army`, also run:

```bash
python3 .agent-army/runtime.py verify
```

If all such layers are external or disabled, do not invoke a nonexistent
runtime; report that those controls are outside Agent Army's guarantee.

After editing local agent sources, render them again:

```bash
apm install --frozen --target <target>
```

Report: target and native/degraded capability; full control ownership table;
recon laws with proving paths; every specialized role; verified commands;
reflection changes; assumptions; and any external/disabled/blocked guarantee.
Suggest `/ship "<first task>"` only after this report.

## Non-negotiable quality bar

Each specialized agent must still conform to
`baseline/core/agents/_STANDARD.md` and retain its output skeleton. It fails
bootstrap if either condition holds:

- **Evidence failure:** a repository claim lacks a real proving path or a
  verified command.
- **Internalization failure:** the file contains generic baseline prose with
  only local paths substituted.

Never replace user-owned controls, weaken tests/security to make a command
pass, invent commands, or commit without explicit human approval.
