#!/bin/bash

SCRIPT_NAME=$(basename "$0")
echo "Running $SCRIPT_NAME..."

if [ -n "$DEVCONTAINER_ENV" ]; then
  echo "$SCRIPT_NAME: This script is only for use in a devcontainer."
  exit 0
fi

sh ./.devcontainer/containers/main/download_strip.sh

echo "Exit $SCRIPT_NAME"
echo