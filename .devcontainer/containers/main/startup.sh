#!/bin/bash

SCRIPT_NAME=$(basename "$0")
echo "Running $SCRIPT_NAME..."

if [ ! -f "/.dockerenv" ]; then
  echo "$SCRIPT_NAME: This script is only for use in a devcontainer."
  exit 0
fi

set -e

sh ./.devcontainer/containers/main/download_strip.sh

echo "Exit $SCRIPT_NAME"
echo