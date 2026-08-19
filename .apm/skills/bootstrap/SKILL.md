---
name: bootstrap
description: One-time, evidence-led setup of a tailored Agent Army v0.2. It preserves existing user controls, creates target-native agents through APM, and does not accept generic localization as specialization.
---
# /bootstrap — own controls, then author a real team

`apm install` delivered this skill and templates only. It did not install live
agents, hooks or CI. `/bootstrap` has two distinct jobs:

1. deterministically create the selected target profile without taking over
   controls that belong to the repository owner;
2. author a team that knows this repository's evidence, laws and test idioms.

Do not let the first mechanical job displace the second. A target-native team
with generic prompts is not a successful bootstrap.

## Step 0 — target and ownership (mechanical, explicit)

Run the detector; do not infer the active tool from a directory listing:

```bash
bash .agents/skills/bootstrap/assemble.sh --detect
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
python3 .agents/skills/bootstrap/bootstrap.py <target> \
  --runtime-hooks <army|external|disabled> \
  --git-precommit <army|external|disabled> \
  --ci <army|external|disabled>
```

It creates local APM agent sources in `.apm/agents`, optional hook primitives
in `.apm/hooks`, `.agent-army/config.json`, and then asks APM to render the
native format. Codex therefore receives TOML through APM, not guessed TOML.
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
ownership choices are preserved. Edit those local source agents, not only the
native APM output, then re-run `apm install --frozen --target <target>` after
specialization.

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

In supervised mode, show the report and the full nested-standards list. Ask
the user to confirm the extracted laws and identify never-touch zones before
writing. In auto mode, print the report and record assumptions, then continue.

## Step 2 — ask only for genuine gaps

Group a short question set only around missing business context, architecture
intent, NFR/compliance, task/branch conventions, test rigor, and model-tier
availability. Do not ask for facts already proved by recon.

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

- `architect`: layers, public contracts, real manifest defaults and blueprint
  skeletons consistent with its examples.
- `tester`: real RED→GREEN idioms, fixtures and all relevant stack commands.
- `code-reviewer`: an explicit checklist made from the repository's laws.
- `security-auditor` and `perf-auditor`: stack-specific sinks and bottlenecks.
- `docs-writer` and `coder`: actual documentation ownership and module limits.

Write or refresh root `AGENTS.md` first: stacks, commands, laws, reusable
assets, policy, roster and the ownership status of controls. Claude alone gets
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

In supervised mode, present a per-agent summary of laws and example scenarios
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
