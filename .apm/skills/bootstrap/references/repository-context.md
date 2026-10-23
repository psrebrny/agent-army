# Git checkout and scoped Army

Installed skills and project state are independent. Locate `army.py` relative to the loaded bootstrap
skill, never by assuming it was installed in the task repository. Capture the task working directory
before calling the helper:

```bash
python3 "<installed-bootstrap-directory>/army.py" locate --cwd "<task-working-directory>" --tool <tool>
```

## Select one team, not one team per Git checkout

Discovery walks only from the task directory upwards to its Git root. The nearest existing
`.agent-army/` wins, including a package-local profile such as `plugins/vento/.agent-army/`.
It never searches descendants, siblings, user-global agents or the installed package for project state.
It never combines a nested team's roles, metadata, stores or model routing with a parent team's.
Missing roles use the reported package baseline; disclose that source rather than claiming specialization.
Missing, invalid or unsupported metadata produces `metadata_diagnostic`; it does not hide local contracts
or authorize defaulting test policy to `none`. Establish policy and verified commands from repository
evidence or ask before execution. Both `.agent` and legacy `.agent.md` contracts are readable; duplicate
definitions of a role stop discovery rather than choosing silently. Discovery never migrates these files.

When the task starts at the monorepo root but names a package's Army, select it explicitly:

```bash
python3 "<installed-bootstrap-directory>/army.py" locate --cwd "<git-root>" --army-root plugins/vento
python3 "<installed-bootstrap-directory>/army.py" role tester --cwd "<git-root>" --army-root plugins/vento
```

`--army-root` accepts the owning directory or its `.agent-army` directory, relative to `--cwd` (or absolute).
The profile must exist inside the same Git checkout. Out-of-checkout selection and escaping profile/role
symlinks fail. If the intended team is unclear, ask; do not select by recency or recursively scan profiles.
Reuse the same selection for every role and resumed stage; never switch teams midway without a decision.
Outside Git, stop rather than substituting the skill installation or the user's home.

## Keep scope and path bases explicit

- `repo_root` is always the Git root. Existing repository-relative blueprint paths (`design-docs/`),
  source paths and quality command `cwd` values keep that base; do not silently rebase saved commands
  or move existing plans just because a package-local Army was selected.
- `army_root` owns the selected `.agent-army/`; `profile_dir` is its absolute path (null for baseline).
  Local roles, config, operational state and store bindings belong there, not in the root team's profile.
- Read root **and** applicable nested `AGENTS.md`/`CLAUDE.md`. `agents_md` is only the root pointer, not
  an exhaustive instruction inventory. A scoped team never waives root instructions or quality controls.
- Default writes stay in the selected package/task scope. Root/shared files, including blueprints
  outside that scope, need the normal explicit write-scope approval. Existing accepted paths stay put.
  Profile selection is not permission to change sibling packages or install/migrate controls.
- Use each reported `contract_path` directly. With `army.py role`, preserve `--cwd` and `--army-root`;
  resolve relative role placeholders such as `.agent-army/agents` against `army_root`.
  Edit an existing specialized role at that exact path, preserving its suffix; do not create a second
  `.agent` definition when upgrading a legacy `.agent.md` contract.
- Run verified structured quality commands from the selected metadata with their established Git-root
  base. Do not use another team's runtime/config as a substitute. This package's Git-root-only
  `runtime.py` does not select nested profiles: invoking it is not proof that the nested team's commands
  ran. Existing repository-wide controls still apply independently.

Scope: engineering workflows (`/ship`, `/adapt-army`, `/new-agent`). Product skills keep their records
and `.agent-army/stores.json` at the Git root. `profile_newer: true` means the profile was written by a newer
package than the installed one: use it read-only and do not run `bootstrap.py` against it.

This is read-only discovery of **existing** profiles, not scoped installation. `bootstrap.py` still
creates/migrates the Git-root profile and its controls. Do not run it to update a selected nested Army:
explain that limitation and obtain a separately reviewed migration if needed. Do not modify installed
skill caches or relocate a working team as a workaround.

Maintainer regression check (offline, scratch Git checkouts):
`python3 .apm/skills/bootstrap/tests/test_army.py` from the source repository root.
