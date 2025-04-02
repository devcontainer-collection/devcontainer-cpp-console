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
    --type) BUILD_TYPE="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

# Validate
if [ -z "$BUILD_TYPE" ]; then
  echo "[build] Build type not specified. Please use --type <dynamic|static>"
  exit 1
fi

[ -z "$VENDOR" ] && VENDOR="unknown"
[ "$OS" = "macos" ] && [ -z "$ABI" ] && ABI="none"

if [ -z "$ARCH" ] || [ -z "$OS" ]; then
  echo "Usage: $0 --arch <arch> --os <os> [--vendor <vendor>] [--abi <abi>] --type <dynamic|static>"
  exit 1
fi

# Target triple
if [ -z "$ABI" ]; then
  TARGET_TRIPLE="$ARCH-$VENDOR-$OS"
else
  TARGET_TRIPLE="$ARCH-$VENDOR-$OS-$ABI"
fi
ZIG_TARGET="$ARCH-$OS-$ABI"

# File extension
case "$BUILD_TYPE" in
  dynamic)
    case "$OS" in
      linux) EXT="so" ;;
      macos|osx) EXT="dylib" ;;
      windows) EXT="dll" ;;
      *) echo "[build] Unsupported OS '$OS' for dynamic build" && exit 1 ;;
    esac
    ;;
  static)
    case "$OS" in
      linux|macos|osx) EXT="a" ;;
      windows) EXT="lib" ;;
      *) echo "[build] Unsupported OS '$OS' for static build" && exit 1 ;;
    esac
    ;;
  *)
    echo "[build] Unknown build type: $BUILD_TYPE"
    exit 1
    ;;
esac

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$SCRIPT_DIR/.."
LIB_DIR="$APP_DIR/lib"
PACKAGE_DIR="$APP_DIR/build/${BUILD_TYPE}/package"
mkdir -p "$PACKAGE_DIR"

echo "[build_libs_$BUILD_TYPE] Target: $ZIG_TARGET"

# Track built libs
BUILT_LIBS=""

# Build loop
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
    echo "[build_libs_$BUILD_TYPE] ▶️  Building $NAME..."

    BASE_OUTDIR="$APP_DIR/build/${BUILD_TYPE}/${TARGET_TRIPLE}/${NAME}"
    LIB_OUTDIR="${BASE_OUTDIR}/lib"
    INCLUDE_OUTDIR="${BASE_OUTDIR}/include"
    mkdir -p "$LIB_OUTDIR" "$INCLUDE_OUTDIR"

    case "$BUILD_TYPE" in
      dynamic)
        zig c++ \
          -target "$ZIG_TARGET" \
          -fPIC \
          -shared \
          "$CPP" \
          "$C_WRAPPER" \
          -I"$dir" \
          -std=c++20 \
          -o "${LIB_OUTDIR}/${LIB_PREFIX}${NAME}.${EXT}"
        ;;
      static)
        OBJ1="${LIB_OUTDIR}/${NAME}.o"
        OBJ2="${LIB_OUTDIR}/${NAME}_c.o"
        ARCHIVE="${LIB_OUTDIR}/${LIB_PREFIX}${NAME}.${EXT}"

        zig c++ -target "$ZIG_TARGET" -c "$CPP" -I"$dir" -std=c++20 -o "$OBJ1"
        zig c++ -target "$ZIG_TARGET" -c "$C_WRAPPER" -I"$dir" -std=c++20 -o "$OBJ2"

        zig ar rcs "$ARCHIVE" "$OBJ1" "$OBJ2"

        # 중간 산물 정리
        rm -f "$OBJ1" "$OBJ2"
        ;;
      *)
        echo "[build] Unknown build type: $BUILD_TYPE"
        exit 1
        ;;
    esac

    echo "[build_libs_$BUILD_TYPE] ✅ Built: ${LIB_OUTDIR}/${LIB_PREFIX}${NAME}.${EXT}"

    if [ -f "$C_HEADER" ]; then
      cp "$C_HEADER" "${INCLUDE_OUTDIR}/${NAME}.h"
      echo "[build_libs_$BUILD_TYPE] 📄 Copied: ${INCLUDE_OUTDIR}/${NAME}.h"
    else
      echo "[build_libs_$BUILD_TYPE] ⚠️  No header file found for $NAME"
    fi

    BUILT_LIBS="$BUILT_LIBS $NAME"
  else
    echo "[build_libs_$BUILD_TYPE] ⚠️ Skipped $NAME (missing ${NAME}.cpp or ${NAME}_c.cpp)"
  fi
done

# Packaging
if [ -n "$BUILT_LIBS" ]; then
  echo "[packaging] 📦 Packaging all built libraries into one archive..."

  ARCHIVE_NAME="libs-${BUILD_TYPE}-${TARGET_TRIPLE}.tar.gz"
  ARCHIVE_PATH="$PACKAGE_DIR/${ARCHIVE_NAME}"

  SHARED_BASE="$APP_DIR/build/${BUILD_TYPE}/${TARGET_TRIPLE}"
  tar -czf "$ARCHIVE_PATH" -C "$SHARED_BASE" $BUILT_LIBS

  echo "[packaging] ✅ Done: $ARCHIVE_PATH"
else
  echo "[packaging] ⚠️ No libraries built, skipping packaging."
fi

echo "[build_libs_$BUILD_TYPE] ✅ All done."
echo "Exit $SCRIPT_NAME"
