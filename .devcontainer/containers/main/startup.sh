#!/bin/bash

set -e

SCRIPT_NAME=$(basename "$0")

trap 'echo "Exit $SCRIPT_NAME"' EXIT
echo "Running $SCRIPT_NAME..."

if [ ! -f "/.dockerenv" ]; then
  echo "$SCRIPT_NAME: This script is only for use in a devcontainer."
  exit 0
fi

sh ./.devcontainer/containers/main/download_strip.sh
