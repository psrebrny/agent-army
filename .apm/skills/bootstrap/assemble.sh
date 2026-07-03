#!/usr/bin/env bash
# assemble.sh <tool> [--dry-run] [--reconcile]
# assemble.sh --detect          # deterministic tool detection, no <tool> needed
#
# Deterministic tool-native team assembler. NO LLM, NO soft-ifs: everything that
# differs per tool is read from tools/<tool>.yml (see baseline/tools/README.md for the
# schema). Emits WHOLE, standalone agent files — never proxies/pointers back at
# core/. Never clobbers an existing (specialized) target file; git is the only
# rollback (no *.base backups are ever written).
#
# Order in the real pipeline: detect (--detect) -> assemble (this script, scaffold) ->
# bootstrap (LLM) specializes the materialized team in place -> verify. Re-running assemble
# skips existing agent files (reports "kept"); --reconcile refreshes ONLY packaging
# (frontmatter/paths) on existing files without touching their specialized body.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SELF_DIR/baseline"
TOOLS_DIR="$BASE_DIR/tools"
SOURCE_AGENTS_DIR="$BASE_DIR/core/agents"
HOOKS_SRC_DIR="$BASE_DIR/hooks"
ARMY_CONF_SRC="$BASE_DIR/army.conf"

usage() { echo "usage: assemble.sh <tool> [--dry-run] [--reconcile]  |  assemble.sh --detect" >&2; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
command -v python3 >/dev/null 2>&1 || { echo "FATAL: python3 required to parse tools/*.yml" >&2; exit 1; }

# --detect: which first-class tool is this repo already using? Purely mechanical (does a known
# config_root dir exist) — the only judgment left for the LLM is what to do with an ambiguous or
# empty result (ask the user), never re-deriving the directory-existence check itself.
if [ "${1:-}" = "--detect" ]; then
  MATCHES=""
  for f in "$TOOLS_DIR"/*.yml; do
    name="$(basename "$f" .yml)"
    [ "$name" = "_default" ] && continue
    cr="$(python3 - "$f" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
print((d.get('dirs') or {}).get('config_root') or '')
PY
)"
    [ -n "$cr" ] && [ -e "$ROOT/$cr" ] && MATCHES="$MATCHES $name"
  done
  MATCHES="${MATCHES# }"
  # shellcheck disable=SC2206
  MATCH_ARR=($MATCHES)
  case "${#MATCH_ARR[@]}" in
    1) echo "DETECTED=${MATCH_ARR[0]}" ;;
    0) echo "NONE=1" ;;
    *) echo "AMBIGUOUS=$MATCHES" ;;
  esac
  exit 0
fi

TOOL="${1:-}"
[ -n "$TOOL" ] || usage
shift || true
DRY_RUN=0
RECONCILE=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    --reconcile) RECONCILE=1 ;;
    *) echo "unknown flag: $a" >&2; usage ;;
  esac
done

DESC="$TOOLS_DIR/$TOOL.yml"
if [ ! -f "$DESC" ]; then
  echo "WARN: tool '$TOOL' not first-class — add tools/$TOOL.yml for native placement. Falling back to _default.yml (AGENTS.md + git/CI barrier only, neutral .agents/ dir, no guessed native dirs)." >&2
  DESC="$TOOLS_DIR/_default.yml"
fi
[ -f "$DESC" ] || { echo "FATAL: no descriptor found (not even _default.yml) under $TOOLS_DIR" >&2; exit 1; }
[ -d "$SOURCE_AGENTS_DIR" ] || { echo "FATAL: no source agents at $SOURCE_AGENTS_DIR" >&2; exit 1; }

yq() { # yq <dotted.path>  -> value, "" if null/missing
  python3 - "$DESC" "$1" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
path = sys.argv[2].split('.')
v = d
for k in path:
    v = v.get(k) if isinstance(v, dict) else None
print('' if v is None else v)
PY
}
truthy() { [ "$1" = "True" ] || [ "$1" = "true" ]; }

# assert_safe_relpath <label> <value>: every dirs.* value from tools/<tool>.yml ends up either
# (a) inside a sed s#...#...#g template applied to materialized agent files, or (b) embedded in
# the CONTENT of an auto-executing git pre-commit hook (see wire_git_barrier below). A value
# containing shell metacharacters (`$(...)`, `;`, quotes, ..) would be a code-injection landmine
# the moment it's wrong or attacker-controlled — descriptors are first-party today, but this is
# cheap insurance against a careless PR or a future feature that reads a target repo's own
# descriptor. Empty is allowed (some fields are legitimately unset, e.g. dirs.agents when
# capabilities.subagents=false); non-empty must be a plain repo-relative path.
assert_safe_relpath() {
  local label="$1" val="$2"
  [ -z "$val" ] && return 0
  case "$val" in
    /*) echo "FATAL: descriptor field '$label' must be repo-relative, got an absolute path: '$val'" >&2; exit 1 ;;
  esac
  case "$val" in
    *..*) echo "FATAL: descriptor field '$label' must not contain '..': '$val'" >&2; exit 1 ;;
  esac
  case "$val" in
    *[!A-Za-z0-9._/-]*) echo "FATAL: descriptor field '$label' contains disallowed characters: '$val'" >&2; exit 1 ;;
  esac
}

AGENTS_DIR_REL="$(yq dirs.agents)";      assert_safe_relpath "dirs.agents" "$AGENTS_DIR_REL"
AGENT_FILE_SUFFIX="$(yq dirs.agent_file_suffix)"
[ -z "$AGENT_FILE_SUFFIX" ] && AGENT_FILE_SUFFIX=".md"
case "$AGENT_FILE_SUFFIX" in
  .[A-Za-z0-9.]*) : ;;
  *) echo "FATAL: descriptor field 'dirs.agent_file_suffix' is unsafe: '$AGENT_FILE_SUFFIX'" >&2; exit 1 ;;
esac
SKILLS_DIR_REL="$(yq dirs.skills)";      assert_safe_relpath "dirs.skills" "$SKILLS_DIR_REL"
HOOKS_DIR_REL="$(yq dirs.hooks)";        assert_safe_relpath "dirs.hooks" "$HOOKS_DIR_REL"
CONFIG_ROOT_REL="$(yq dirs.config_root)"; assert_safe_relpath "dirs.config_root" "$CONFIG_ROOT_REL"
ACCEPTS_TOOLS="$(yq frontmatter.accepts_tools_field)"
SUBAGENTS="$(yq capabilities.subagents)"
HOOK_MECHANISM="$(yq capabilities.hook_mechanism)"

echo "== assemble $TOOL  (descriptor: $(basename "$DESC"))$( [ "$DRY_RUN" = 1 ] && echo '  [dry-run]' )$( [ "$RECONCILE" = 1 ] && echo '  [reconcile]' ) =="

plan() { printf '  plan: %s\n' "$1"; }
land() { printf '  \033[32m+ %s\033[0m\n' "$1"; }
keep() { printf '  \033[33mkept %s\033[0m\n' "$1"; }
note() { printf -- '-- %s\n' "$1"; }

# materialize <src-file> <dest-file>: resolve <SKILLS_DIR>/<AGENTS_DIR>/<TOOL_DIR>
# placeholders and apply the frontmatter tools: rule. Always via a tmp file + mv —
# never in-place -i (portable across BSD/GNU sed, and works when src == dest).
materialize() {
  local src="$1" dest="$2" tmp
  tmp="$(mktemp)"
  sed -e "s#<SKILLS_DIR>#$SKILLS_DIR_REL#g" \
      -e "s#<AGENTS_DIR>#$AGENTS_DIR_REL#g" \
      -e "s#<TOOL_DIR>#$CONFIG_ROOT_REL#g" \
      "$src" > "$tmp"
  if ! truthy "$ACCEPTS_TOOLS"; then
    grep -v '^tools: *[A-Za-z]' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
}

# --- 1. Agents ---------------------------------------------------------------
if ! truthy "$SUBAGENTS"; then
  note "capabilities.subagents=false for $TOOL — no agent files materialized; degrading to AGENTS.md instructions + git/CI barrier only"
else
  AGENTS_DIR="$ROOT/$AGENTS_DIR_REL"
  n="$(ls "$SOURCE_AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$DRY_RUN" = 1 ]; then
    plan "agents -> $AGENTS_DIR_REL/ ($((n - 1)) loadable agents)"
    plan "_STANDARD.md -> $CONFIG_ROOT_REL/_STANDARD.md (authoring reference — kept OUT of the agent-load dir)"
  else
    mkdir -p "$AGENTS_DIR"
    for f in "$SOURCE_AGENTS_DIR"/*.md; do
      name="$(basename "$f")"
      # _STANDARD.md is authoring reference, not a loadable agent — never put it where
      # a tool might try to load it as a subagent.
      if [ "$name" = "_STANDARD.md" ]; then
        target="$ROOT/$CONFIG_ROOT_REL/_STANDARD.md"
        rel="$CONFIG_ROOT_REL/_STANDARD.md"
      else
        # apply the tool's agent-file suffix (e.g. Copilot requires *.agent.md, not bare *.md)
        outname="${name%.md}${AGENT_FILE_SUFFIX}"
        target="$AGENTS_DIR/$outname"
        rel="$AGENTS_DIR_REL/$outname"
      fi
      if [ -f "$target" ]; then
        if [ "$RECONCILE" = 1 ]; then
          materialize "$target" "$target"
          land "$rel (reconciled: packaging only, body untouched)"
        else
          keep "$rel"
        fi
        continue
      fi
      materialize "$f" "$target"
      land "$rel"
    done
  fi
fi

# --- 2. Hooks (only what hooks_live lists — inert ones are never copied) -----
# Portable (no mapfile/readarray — macOS ships bash 3.2, which lacks both).
HOOK_LIST=()
while IFS= read -r h; do
  [ -z "$h" ] && continue
  # hooks_live entries must be bare filenames (no '/', no '..') — they get embedded verbatim
  # into the CONTENT of an auto-executing git pre-commit hook below (wire_git_barrier), so an
  # unsafe entry here is a code-injection landmine, same reasoning as assert_safe_relpath above.
  case "$h" in
    *[!A-Za-z0-9._-]*) echo "FATAL: hooks_live entry is unsafe: '$h'" >&2; exit 1 ;;
  esac
  HOOK_LIST+=("$h")
done < <(python3 - "$DESC" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
for h in (d.get('hooks_live') or []):
    print(h)
PY
)
if [ "$DRY_RUN" = 1 ]; then
  plan "hooks -> $HOOKS_DIR_REL/ (${HOOK_LIST[*]:-none})"
else
  HOOKS_DIR="$ROOT/$HOOKS_DIR_REL"
  mkdir -p "$HOOKS_DIR"
  for h in "${HOOK_LIST[@]}"; do
    src="$HOOKS_SRC_DIR/$h"
    [ -f "$src" ] || { echo "FATAL: hooks_live references missing $src" >&2; exit 1; }
    dest="$HOOKS_DIR/$h"
    cp "$src" "$dest"
    chmod +x "$dest"
    land "$HOOKS_DIR_REL/$h"
  done
fi

# --- 3. settings.json — only when the tool actually reads it ----------------
if [ "$HOOK_MECHANISM" = "claude-settings" ]; then
  dest="$ROOT/$CONFIG_ROOT_REL/settings.json"
  if [ "$DRY_RUN" = 1 ]; then
    plan "settings.json -> $CONFIG_ROOT_REL/settings.json"
  elif [ -f "$dest" ] && [ "$RECONCILE" != 1 ]; then
    keep "$CONFIG_ROOT_REL/settings.json"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$BASE_DIR/settings.json" "$dest"
    land "$CONFIG_ROOT_REL/settings.json"
  fi
else
  note "capabilities.hook_mechanism=$HOOK_MECHANISM — no settings.json (lifecycle hooks are inert for $TOOL)"
fi

# --- 4. army.conf (non-clobber — bootstrap fills in real commands later) ----
dest="$ROOT/$CONFIG_ROOT_REL/army.conf"
if [ "$DRY_RUN" = 1 ]; then
  plan "army.conf -> $CONFIG_ROOT_REL/army.conf"
elif [ -f "$dest" ] && [ "$RECONCILE" != 1 ]; then
  keep "$CONFIG_ROOT_REL/army.conf"
else
  mkdir -p "$(dirname "$dest")"
  cp "$ARMY_CONF_SRC" "$dest"
  land "$CONFIG_ROOT_REL/army.conf"
fi

# --- 5. Git commit barrier — husky-aware, idempotent, never clobbers --------
# Lifted verbatim (as logic) from the old SKILL.md Step 0 prose.
wire_git_barrier() {
  if [ ! -e "$ROOT/.git" ]; then
    note "no .git — skipping commit barrier wiring"
    return
  fi
  local barrier_rel="$HOOKS_DIR_REL/git-pre-commit.sh"
  local barrier_line="sh \"\$(git rev-parse --show-toplevel)/$barrier_rel\" || exit 1"
  local hooks_path
  hooks_path="$(git -C "$ROOT" config core.hooksPath 2>/dev/null || true)"

  if [ -n "$hooks_path" ]; then
    # A hook manager (husky/lefthook) already owns commits — append, never touch .git/hooks.
    local mgr_file="$ROOT/$hooks_path/pre-commit"
    if [ "$DRY_RUN" = 1 ]; then
      plan "git barrier -> append one idempotent line to $hooks_path/pre-commit (husky/lefthook-managed)"
      return
    fi
    mkdir -p "$(dirname "$mgr_file")"
    touch "$mgr_file"
    if grep -qF "$barrier_rel" "$mgr_file" 2>/dev/null; then
      keep "$hooks_path/pre-commit (barrier already wired)"
    else
      printf '\n%s\n' "$barrier_line" >> "$mgr_file"
      chmod +x "$mgr_file"
      land "$hooks_path/pre-commit (barrier appended)"
    fi
    return
  fi

  local plain_hook="$ROOT/.git/hooks/pre-commit"
  if [ -f "$plain_hook" ]; then
    if grep -qF "$barrier_rel" "$plain_hook" 2>/dev/null; then
      keep ".git/hooks/pre-commit (barrier already wired)"
    else
      echo "  ⚠ .git/hooks/pre-commit already exists (hand-written, no manager) — add this line yourself:"
      echo "    $barrier_line"
    fi
    return
  fi

  if [ "$DRY_RUN" = 1 ]; then
    plan "git barrier -> new shim at .git/hooks/pre-commit"
    return
  fi
  mkdir -p "$ROOT/.git/hooks"
  {
    echo '#!/usr/bin/env bash'
    echo "$barrier_line"
  } > "$plain_hook"
  chmod +x "$plain_hook"
  land ".git/hooks/pre-commit (shim created)"
}
wire_git_barrier

# --- 6. .gitignore — skills dir (apm-restored, like node_modules) + local state
update_gitignore() {
  local gi="$ROOT/.gitignore"
  local entries=("$SKILLS_DIR_REL/")
  [ "$HOOK_MECHANISM" = "claude-settings" ] && entries+=("$CONFIG_ROOT_REL/settings.local.json")
  if [ "$DRY_RUN" = 1 ]; then
    plan "gitignore -> ensure entries present: ${entries[*]}"
    return
  fi
  touch "$gi"
  local added=0
  for e in "${entries[@]}"; do
    if ! grep -qxF "$e" "$gi" 2>/dev/null; then
      echo "$e" >> "$gi"
      added=1
    fi
  done
  if [ "$added" = 1 ]; then land ".gitignore (updated)"; else keep ".gitignore (already covers it)"; fi
}
update_gitignore

# --- 7. design-docs/ skeleton — tool-independent, purely mechanical (mkdir + a pointer file).
# Never touches an existing design-docs/ (a repo that already has blueprints owns its content).
create_design_docs_skeleton() {
  local dd="$ROOT/design-docs"
  if [ -e "$dd" ]; then
    keep "design-docs/ (already exists)"
    return
  fi
  if [ "$DRY_RUN" = 1 ]; then
    plan "design-docs/README.md -> new skeleton (architect writes design-docs/<Task-ID>/ under it)"
    return
  fi
  mkdir -p "$dd"
  cat > "$dd/README.md" <<'EOF'
# design-docs/

Blueprints written by the `architect` agent, one directory per Task-ID:

```
design-docs/<Task-ID>/00_CORE_MANIFEST.md
design-docs/<Task-ID>/01_PR_1_<Layer>.md
design-docs/<Task-ID>/0N_PR_N_<Layer>.md
```

See the `architect` agent's definition (or `AGENTS.md`) for the exact skeleton each file follows.
EOF
  land "design-docs/README.md (skeleton created)"
}
create_design_docs_skeleton

echo "== done =="
