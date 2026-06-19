#!/usr/bin/env bash
# install-latest.sh — download latest Agent Army release and run the installer
#
# Global install (run once, then use 'army' from any repo):
#   curl -fsSL <url> | bash -s -- --global          # public repo
#   gh repo clone ... / see README for private repo
#
# Per-repo install into current directory:
#   bash <(curl -fsSL <url>) --tool claude
#
# Per-repo install into a specific path:
#   bash <(curl -fsSL <url>) ~/my-repo --tool claude

set -euo pipefail

REPO="pawel-srebrny/agent-army"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

download_via_gh() {
  echo "Using gh CLI (authenticated)..."
  gh release download --repo "$REPO" --pattern "*.tar.gz" --dir "$TMPDIR"
  cd "$TMPDIR"
  tar xzf ./*.tar.gz
}

download_via_curl() {
  echo "Fetching latest Agent Army release..."
  RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")
  DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url":"[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)
  VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)

  if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find a .tar.gz release." >&2
    echo "  - If this is a private repo, install gh CLI and run: gh auth login" >&2
    echo "  - Then re-run this script." >&2
    exit 1
  fi

  echo "Downloading $VERSION..."
  cd "$TMPDIR"
  curl -fsSL "$DOWNLOAD_URL" | tar xz
}

# Prefer gh CLI (handles private repos); fall back to curl (public repos)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  download_via_gh
else
  download_via_curl
fi

echo "Running installer..."
cd "$TMPDIR/agent-army"
./install.sh "$@"
