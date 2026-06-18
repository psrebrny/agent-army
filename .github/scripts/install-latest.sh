#!/usr/bin/env bash
# install-latest.sh — download latest Agent Army release and run the installer
# Usage: curl -fsSL https://raw.githubusercontent.com/pawel-srebrny/agent-army/main/.github/scripts/install-latest.sh | bash -s -- ~/my-repo --tool claude

set -euo pipefail

REPO="pawel-srebrny/agent-army"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Fetching latest Agent Army release..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url":"[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)
VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Could not find a .tar.gz release. Check https://github.com/$REPO/releases" >&2
  exit 1
fi

echo "Downloading $VERSION from $DOWNLOAD_URL..."
cd "$TMPDIR"
curl -fsSL "$DOWNLOAD_URL" | tar xz

echo "Running installer..."
cd agent-army
# Pass all arguments to install.sh (target repo, --tool, etc.)
./install.sh "$@"

echo "✓ Agent Army $VERSION installed successfully!"
