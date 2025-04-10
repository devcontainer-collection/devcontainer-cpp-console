#!/bin/bash

set -e

SCRIPT_NAME=$(basename "$0")

trap 'echo "Exit $SCRIPT_NAME"' EXIT
echo "Running $SCRIPT_NAME..."

if [ ! -f "/.dockerenv" ]; then
  echo "$SCRIPT_NAME: This script is only for use in a devcontainer."
  exit 0
fi

# Usage:
# sh build.sh --basename <name> --arch <arch> [--vendor <vendor>] --os <os> [--abi <abi>] --build-type <debug|release>
# Example:
# sh build.sh --basename main --arch x86_64 --os linux --build-type release

# --- Parse named args ---
while [ $# -gt 0 ]; do
  case "$1" in
    --basename)
      BASENAME="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --vendor)
      VENDOR="$2"
      shift 2
      ;;
    --os)
      OS="$2"
      shift 2
      ;;
    --abi)
      ABI="$2"
      shift 2
      ;;
    --build-type)
      BUILD_TYPE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# --- Set defaults if needed ---
[ -z "$VENDOR" ] && VENDOR="unknown"
# [ -z "$ABI" ] && ABI="gnu"

# --- Validate ---
if [ -z "$BASENAME" ] || [ -z "$ARCH" ] || [ -z "$OS" ] || [ -z "$BUILD_TYPE" ]; then
  echo "Usage: $0 --basename <name> --arch <arch> [--vendor <vendor>] --os <os> [--abi <abi>] --build-type <debug|release>"
  exit 1
fi

# make target triple
if [ -z "$ABI" ]; then
  TARGET_TRIPLE="$ARCH-$VENDOR-$OS"
  # ex) x86_64-apple-darwin
else
  TARGET_TRIPLE="$ARCH-$VENDOR-$OS-$ABI"
  # ex) x86_64-unknown-linux-gnu
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/.."
cd "$APP_DIR" || exit 1
BUILDTYPE_TARGET_TRIPLE_PATH="build/${BUILD_TYPE}/${TARGET_TRIPLE}"
mkdir -p ${BUILDTYPE_TARGET_TRIPLE_PATH}

INCLUDES=$(find lib -type d -exec printf -- "-I%s " {} \;)

# Compose Zig target triple
ZIG_TARGET="$ARCH-$OS-$ABI"
EXT=""
[ "$OS" = "windows" ] && EXT=".exe"

# Determine the build mode
if [ "$BUILD_TYPE" = "release" ]; then
    OPTIMIZE="-O3"
    DEBUG_FLAG="-g0"
elif [ "$BUILD_TYPE" = "debug" ]; then
    OPTIMIZE="-O0"
    DEBUG_FLAG="-g -Og"
else
    echo "Unsupported build type: $BUILD_TYPE"
    exit 1
fi

OUTPUT="${BUILDTYPE_TARGET_TRIPLE_PATH}/${BASENAME}${EXT}"

# Compile with Zig(detect source files and include directories automatically)
zig c++ \
  -target "$ZIG_TARGET" \
  $(find src lib -name '*.cpp') \
  $INCLUDES \
  -std=c++20 \
  -o "$OUTPUT" \
  $DEBUG_FLAG $OPTIMIZE

echo "[build] Build complete: $OUTPUT"

# if release build, strip the binary
if [ "$BUILD_TYPE" = "release" ]; then
    echo "[build] Stripping binary..."
    echo "call strip with '${TARGET_TRIPLE}'"
    sh "$SCRIPT_DIR/strip.sh" --bin "$OUTPUT" --target-triple "${TARGET_TRIPLE}"
fi
