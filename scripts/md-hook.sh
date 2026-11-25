#!/usr/bin/env bash
# Pre-commit Markdown step: fix structure in staged .md files (markdownlint --fix, re-staged),
# then reject staged lines over 120 columns that the commit adds. Called from .git/hooks/pre-commit.
#   scripts/md-hook.sh          # staged files
#   scripts/md-hook.sh --all    # lint every tracked .md (structure only), no fixes
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
LINT=(npx --yes markdownlint-cli2@0.13.0)
WIDTH=120

if [ "${1:-}" = "--all" ]; then
  exec "${LINT[@]}" "**/*.md"
fi

files=()
while IFS= read -r f; do files+=("$f"); done < <(
  git diff --cached --name-only --diff-filter=ACMR -- '*.md' ':!tests/fixtures/**' ':!build/**')
[ ${#files[@]} -eq 0 ] && exit 0

# Fix only files staged as a whole; fixing a partly staged file would stage its unstaged hunks too.
whole=()
for f in "${files[@]}"; do git diff --quiet -- "$f" && whole+=("$f"); done
if [ ${#whole[@]} -gt 0 ]; then
  "${LINT[@]}" --fix "${whole[@]}" >/dev/null 2>&1 || true
  git add -- "${whole[@]}"
fi

status=0
if ! out=$("${LINT[@]}" "${files[@]}" 2>&1); then echo "$out" >&2; status=1; fi

# Added lines over WIDTH, outside frontmatter, code fences and tables.
python3 - "$WIDTH" "${files[@]}" <<'PY' || status=1
import re, subprocess, sys
width, files = int(sys.argv[1]), sys.argv[2:]
# One staged diff with rename detection, so a moved file reports only its changed lines.
full = subprocess.run(['git', 'diff', '--cached', '-M', '-U0'], capture_output=True, text=True).stdout
diffs, cur = {}, None
for line in full.splitlines():
    if line.startswith('+++ '):
        cur = line[6:] if line.startswith('+++ b/') else None
        diffs.setdefault(cur, [])
    elif cur is not None and not line.startswith('diff --git'):
        diffs[cur].append(line)
bad = []
for f in files:
    text = subprocess.run(['git', 'show', f':{f}'], capture_output=True, text=True).stdout.splitlines()
    skip, fence, front = set(), False, bool(text) and text[0] == '---'
    for n, line in enumerate(text, 1):
        if front:
            skip.add(n)
            if n > 1 and line == '---':
                front = False
            continue
        if line.lstrip().startswith(('```', '~~~')):
            fence = not fence
            skip.add(n)
        elif fence or line.lstrip().startswith('|'):
            skip.add(n)
    n = 0
    for line in diffs.get(f, []):
        hunk = re.match(r'@@ -\S+ \+(\d+)', line)
        if hunk:
            n = int(hunk.group(1))
        elif line.startswith('+') and not line.startswith('+++'):
            if n not in skip and len(line) - 1 > width and not re.fullmatch(r'\s*\S+', line[1:]):
                bad.append(f'{f}:{n}: {len(line) - 1} > {width} columns')
            n += 1
if bad:
    print('md-hook: wrap these added lines at a sentence or clause boundary:', *bad, sep='\n  ', file=sys.stderr)
    sys.exit(1)
PY

[ $status -eq 0 ] || echo "md-hook: Markdown check failed; fix the lines above and stage again." >&2
exit $status
