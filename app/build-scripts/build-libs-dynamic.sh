#!/bin/sh

set -e

SCRIPT_NAME=$(basename "$0")
echo "Running $SCRIPT_NAME..."

if [ ! -f "/.dockerenv" ]; then
  echo "$SCRIPT_NAME: This script is only for use in a devcontainer."
  exit 0
fi

# Parse named args
while [ $# -gt 0 ]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2;;
    --vendor) VENDOR="$2"; shift 2;;
    --os) OS="$2"; shift 2;;
    --abi) ABI="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

# Set defaults
[ -z "$VENDOR" ] && VENDOR="unknown"
[ "$OS" = "macos" ] && [ -z "$ABI" ] && ABI="none"

if [ -z "$ARCH" ] || [ -z "$OS" ]; then
  echo "Usage: $0 --arch <arch> --os <os> [--vendor <vendor>] [--abi <abi>]"
  exit 1
fi

# Target triple
if [ -z "$ABI" ]; then
  TARGET_TRIPLE="$ARCH-$VENDOR-$OS"
else
  TARGET_TRIPLE="$ARCH-$VENDOR-$OS-$ABI"
fi
ZIG_TARGET="$ARCH-$OS-$ABI"

# Determine extension
case "$OS" in
  linux) EXT="so" ;;
  macos|osx) EXT="dylib" ;;
  windows) EXT="dll" ;;
  *) echo "[build] OS '$OS' is not supported" && exit 1 ;;
esac

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/.."
LIB_DIR="$APP_DIR/lib"
PACKAGE_DIR="$APP_DIR/build/shared/package"
mkdir -p "$PACKAGE_DIR"

echo "[build_libs_dynamic] Target: $ZIG_TARGET"

# Track built libraries
BUILT_LIBS=""

# Loop over libraries
for dir in "$LIB_DIR"/*/; do
  NAME=$(basename "$dir")
  CPP="${dir}${NAME}.cpp"
  C_WRAPPER="${dir}${NAME}_c.cpp"
  C_HEADER="${dir}${NAME}_c.h"

  if [ "$OS" != "windows" ]; then
    LIB_PREFIX="lib"
  else
    LIB_PREFIX=""
  fi

  if [ -f "$CPP" ] && [ -f "$C_WRAPPER" ]; then
    echo "[build_libs_dynamic] ▶️  Building $NAME..."

    BASE_OUTDIR="$APP_DIR/build/shared/${TARGET_TRIPLE}/${NAME}"
    LIB_OUTDIR="${BASE_OUTDIR}/lib"
    INCLUDE_OUTDIR="${BASE_OUTDIR}/include"
    mkdir -p "$LIB_OUTDIR" "$INCLUDE_OUTDIR"

    zig c++ \
      -target "$ZIG_TARGET" \
      -fPIC \
      -shared \
      "$CPP" \
      "$C_WRAPPER" \
      -I"$dir" \
      -std=c++20 \
      -o "${LIB_OUTDIR}/${LIB_PREFIX}${NAME}.${EXT}"

    echo "[build_libs_dynamic] ✅ Built: ${LIB_OUTDIR}/lib${NAME}.${EXT}"

    if [ -f "$C_HEADER" ]; then
      cp "$C_HEADER" "${INCLUDE_OUTDIR}/${NAME}.h"
      echo "[build_libs_dynamic] 📄 Copied: ${INCLUDE_OUTDIR}/${NAME}.h"
    else
      echo "[build_libs_dynamic] ⚠️  No header file found for $NAME"
    fi

    BUILT_LIBS="$BUILT_LIBS $NAME"
  else
    echo "[build_libs_dynamic] ⚠️ Skipped $NAME (missing ${NAME}.cpp or ${NAME}_c.cpp)"
  fi
done

# Packaging step: one archive for all built libs
if [ -n "$BUILT_LIBS" ]; then
  echo "[packaging] 📦 Packaging all built libraries into one archive..."

  TEMP_TAR_LIST=""
  for LIB in $BUILT_LIBS; do
    TEMP_TAR_LIST="$TEMP_TAR_LIST ${LIB}"
  done

  ARCHIVE_NAME="libs-dynamic-${TARGET_TRIPLE}.tar.gz"
  ARCHIVE_PATH="$PACKAGE_DIR/${ARCHIVE_NAME}"

  # 이동 기준 디렉토리: build/shared/<triple>
  SHARED_BASE="$APP_DIR/build/shared/${TARGET_TRIPLE}"
  tar -czf "$ARCHIVE_PATH" -C "$SHARED_BASE" $TEMP_TAR_LIST

  echo "[packaging] ✅ Done: $ARCHIVE_PATH"
else
  echo "[packaging] ⚠️ No libraries built, skipping packaging."
fi


echo "[build_libs_dynamic] ✅ All done."
echo "Exit $SCRIPT_NAME"
echo
