#!/bin/bash

set -e

SCRIPT_NAME=$(basename "$0")

trap 'echo "Exit $SCRIPT_NAME"' EXIT
echo "Running $SCRIPT_NAME..."

if [ ! -f "/.dockerenv" ]; then
  echo "$SCRIPT_NAME: This script is only for use in a devcontainer."
  exit 0
fi

DEST_DIR="/workspace/app/build-scripts"
VERSION_FILE="$DEST_DIR/strip-tag.txt"
DEFAULT_TAG="strip/v0.1.0"

echo "[strip] Reading strip version from $VERSION_FILE..."

# read strip version from strip-tag.txt
if [ -f "$VERSION_FILE" ]; then
  STRIP_TOOLS_TAG=$(cat "$VERSION_FILE" | tr -d '\r\n')
else
  echo "[strip] No version file found, using default: $DEFAULT_TAG"
  STRIP_TOOLS_TAG="$DEFAULT_TAG"
fi

FILENAME="strip.tar.gz"
TMPDIR="/tmp/strip-download"

echo "[strip] ⬇️ Downloading $STRIP_TOOLS_TAG..."

mkdir -p "$TMPDIR"
curl -sSL "https://github.com/devcontainer-collection/devcontainer-tools/archive/refs/tags/${STRIP_TOOLS_TAG}.tar.gz" \
  -o "$TMPDIR/$FILENAME"

echo "[strip] 📦 Extracting..."
tar -xzf "$TMPDIR/$FILENAME" --strip-components=1 -C "$DEST_DIR"

echo "[strip] strip.sh is updated in $DEST_DIR"
# rm .gitignore
rm -rf "$DEST_DIR/.gitignore"
rm -rf "$TMPDIR"

