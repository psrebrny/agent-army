---
name: bootstrap
description: Evidence-led setup and safe incremental migration of a tailored Agent Army v0.6.0. One tool-neutral profile in .agent-army serves every tool; it preserves existing user controls and never renders native agent copies.
---
# /bootstrap — own controls, then author a real team

The package (installed globally or in this repo) delivered this skill and templates only. It did not
install live agents, hooks or CI. `/bootstrap` has two distinct jobs:

1. deterministically create the repository's one profile in `.agent-army/` without taking over
   controls that belong to the repository owner;
2. author a team that knows this repository's evidence, laws and test idioms.

Do not let the first mechanical job displace the second. A profile with generic prompts is not a
successful bootstrap.

The profile has no target tool. Role contracts live only in `.agent-army/agents`; every skill reads
them from the git root it was invoked in (or via `army.py locate`) and runs them as a subagent or in the main
thread, whichever the running tool supports. Bootstrap never writes `.claude/agents`, `.codex/agents`
or any other native copy.

## Update detection — incremental before full recon

After a package update, run `/bootstrap` normally. It first runs:

```bash
python3 "$BOOTSTRAP_DIR/bootstrap.py" --mode auto --dry-run   # BOOTSTRAP_DIR: Step 0
```

`auto` detects the profile state: no profile means first bootstrap; an older Agent Army package means an
incremental migration; the same version is a no-op unless the user explicitly requests `--mode full`; and a
newer local profile is never downgraded. Using the profile from another tool needs no re-bootstrap.

Migrating a 0.3.x/0.4.x profile to 0.5 also removes the native role copies those versions rendered
(`.claude/agents/agent-army-*.md`, `.cursor/agents/…`, `.github/agents/…`, `.codex/agents/…`,
`.gemini/agents/…`, `.windsurf/skills/agent-army-*`, `.apm/agents` staging) — only where a copy is identical
to its `.agent-army/agents` contract — and moves the generated `model:` lines out of the contracts into the
profile's per-tool `model_routing`. A copy that differs is kept and listed as a conflict on the card: merge
its change into the contract, then delete the copy. For an incremental
migration, show the exact version transition, managed paths, preserved local sources and any conflict,
then get one explicit “apply migration” confirmation before rerunning without `--dry-run`.

Incremental mode first shows an **Incremental Upgrade Review**. Read the live package skills next to
`$BOOTSTRAP_DIR` (Step 0), the current root `AGENTS.md`, and local `.agent-army/agents`; use the deterministic package
inventory as the delta, then recommend only concrete local improvements. The card
lists new package capabilities, possibly affected local paths, a recommended diff, reason, test and the
choices `apply selected`, `apply all`, `show details` or `skip`. Do not modify local specialization until
the user chooses. After applying selected/all local diffs, rerun the generator without `--dry-run` with
`--upgrade-review-outcome applied`; after `skip`, rerun it with `--upgrade-review-outcome skipped`. The
mechanical migration then updates only versioned, managed fragments and runs targeted validation. New shared
role contracts appear in the inventory delta: `apply` adds missing role files while preserving every existing
specialization; `skip` preserves the current local roster and role contracts. New product skills (from 0.4.0:
`/product` and the thirteen product advisors) are capabilities only: list them under new capabilities, as
optional and callable on their own; they need no local file, role contract or native agent. Each generator line
`recommended local diff: <template> -> <local contract>` names a changed baseline role template (for 0.4.0, the
`docs-writer` ADR rules): show the package change applied to that local specialized contract, merged into the
specialization so its repository-specific rules stay, never a replacement of the file. A local file colliding with a newly
introduced role name stops the upgrade before writes and requires the user to resolve the exact path. The update
does not redo deep recon or overwrite `.agent-army/agents`, `.agent-army/stores.json`, user-owned model routing,
quality policy or external controls. If the managed feedback-router block in `AGENTS.md` was edited, stop on the conflict rather than
replacing it. Use `--mode full` only when the user asks to re-specialize the team.

Use this exact user-facing card after the dry-run and live-material review:

```md
## Incremental Upgrade Review
- New package capabilities: [from new/changed items in the deterministic inventory]
- Local artifacts inspected: [live skills, AGENTS.md, .agent-army/agents paths]
- Recommended diff: [selected paths only, or none]
- Why: [concrete impact on this repository]
- Verification: [render/checks/tests]
- Question: [apply selected | apply all | show details | skip]
```

Keep the card and the generator's metadata separate from task blueprints: deleting `design-docs/` must
never erase feedback or upgrade state.

## Step 0 — visibility and ownership (mechanical, explicit)

```bash
BOOTSTRAP_DIR="<directory of the SKILL.md you are following, e.g. ~/.claude/skills/bootstrap>"
```

Run the program next to the SKILL.md the tool loaded (`$BOOTSTRAP_DIR`), wherever the package is installed
(globally or in the repo). It works on the git root of the current directory. There is no target to detect:
one profile serves every tool. Do not read `.opencode/skills` or `apm_modules` as instructions.

**Visibility.** Ask where the profile (`.agent-army/`) should live in git:

- `committed` (recommended for teams): the profile is shared and reviewed like code; only
  `.agent-army/state.json` is ignored.
- `gitignore`: `.agent-army/` is added to `.gitignore` — kept out of the repo, the rule itself is shared.
- `exclude`: `.agent-army/` is added to `.git/info/exclude` — private to this clone, nothing in the repo changes.

With `gitignore` or `exclude`, an Agent Army-owned CI cannot work (a clean checkout has no
`.agent-army/runtime.py`): bootstrap reports `ci: blocked` for `--ci army`. Say so before asking.

Inspect the existing controls before asking about ownership:

```bash
find .github/workflows -type f 2>/dev/null
git config core.hooksPath || true
test -f .git/hooks/pre-commit && echo .git/hooks/pre-commit
```

Ask separately for runtime hooks, git pre-commit and CI. Each is `army`,
`external`, or `disabled`. If an existing control is detected, recommend
`external`. Never overwrite it merely because it is weaker or unfamiliar. In
`BOOTSTRAP_MODE=auto`, apply the same defaults (and `committed`).

Generate the profile:

```bash
python3 "$BOOTSTRAP_DIR/bootstrap.py" \
  --visibility <committed|gitignore|exclude> \
  --runtime-hooks <army|external|disabled> \
  --git-precommit <army|external|disabled> \
  --ci <army|external|disabled> \
  [--tool <the tool you are running in>]   # only needed to render army runtime hooks
```

Runtime hooks are the one tool-specific layer: with `--runtime-hooks army` the program writes hook
primitives to `.apm/hooks` and, given `--tool`, renders them for that tool through APM
(`apm install --frozen --target <tool>`). Without `--tool` it only writes the primitives.

Model routing is configured at this same boundary, never improvised by `/ship`. It is stored per tool in
`.agent-army/config.json` → `model_routing.tools` and applied by the skills at dispatch time; the role
contracts carry no generated `model:` line. Claude gets its documented `haiku`/`sonnet`/`opus` tiers by
default. Another tool whose descriptor has `dispatch: subagent-with-prompt` can get exact model IDs:

```bash
python3 "$BOOTSTRAP_DIR/bootstrap.py" --tool <tool> \
  --model-light '<exact available model ID>' \
  --model-mid '<exact available model ID>' \
  --model-strong '<exact available model ID>'
```

`--role-model-routing inherit` deliberately disables this behavior. The three IDs must be supplied
together. Tools with `dispatch: main-thread` run roles in the main session, so the session model applies.
No current tool has a confirmed role-level effort selector; effort always remains the tool default.

It creates one role-contract set in `.agent-army/agents/*.agent`, `.agent-army/config.json`, optional
`.agent-army/runtime.py` and hook primitives, and the visibility entry. Nothing else.

Read the status before continuing:

- `army` is an Agent Army-controlled, testable layer.
- `external` is visible but belongs to the user; do not call it an Agent Army guarantee.
- `disabled` is intentional.
- `blocked` means the requested installation would overwrite an unmanaged
  non-shell pre-commit or an unmanaged `agent-army-quality.yml`; leave it
  external unless the user explicitly resolves the collision.

On re-bootstrap, existing `.agent-army/agents/agent-army-*.agent` sources and the previous
ownership and visibility choices are preserved. A `model:` line a user writes into a contract is a
user-owned override that wins over the profile's tiers in every tool; bootstrap records it in
`model_routing.effective_roles` and never changes it. Edits to the contracts take effect on the next
skill run — there is nothing to render.

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
availability. Read the tool descriptor's `dispatch` and `model_control` before claiming a model or effort can be
changed: distinguish main-session choice from per-role subagent routing, and record only confirmed
capabilities. For a tool with `dispatch: subagent-with-prompt`, record the selected light/mid/strong IDs
with `--tool <tool> --model-…`. Tools with `dispatch: main-thread` run roles in the main session, so
roles inherit the main-session model. An unsupported selector, missing concrete IDs, or effort
field inherits the tool setting and must be reported as a limitation.
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

Write or refresh root `AGENTS.md` first (keep the generator's `agent-army:feedback-router` block in it unchanged): stacks, commands, laws, reusable
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

Check that the skills resolve the new profile (no render step exists):

```bash
python3 "$BOOTSTRAP_DIR/army.py" locate
```

Report: visibility and per-tool dispatch/model routing; full control ownership table;
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
