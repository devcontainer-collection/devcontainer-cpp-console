#!/bin/bash

set -e

SCRIPT_NAME=$(basename "$0")

trap 'echo "Exit $SCRIPT_NAME"' EXIT
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
PACKAGE_DIR="$APP_DIR/build/${BUILD_TYPE}/packages"
mkdir -p "$PACKAGE_DIR"

echo "[build_libs_$BUILD_TYPE] Target: $ZIG_TARGET"

BUILT_LIBS=""

if [ "$BUILD_TYPE" = "dynamic" ]; then

  for MODE in debug release; do
    echo "[build_libs_dynamic] 🔧 Building $MODE..."

    if [ "$MODE" = "debug" ]; then
      ZIG_FLAGS="-O0 -g"
    else
      ZIG_FLAGS="-O3 -DNDEBUG"
    fi
    
    for dir in "$LIB_DIR"/*/; do
      NAME=$(basename "$dir")
      CPP="${dir}${NAME}.cpp"
      C_WRAPPER="${dir}${NAME}_c.cpp"
      C_HEADER="${dir}${NAME}_c.h"

      [ "$OS" = "windows" ] && LIB_PREFIX="" || LIB_PREFIX="lib"

      if [ -f "$CPP" ] && [ -f "$C_WRAPPER" ]; then
        OUTDIR="$APP_DIR/build/dynamic/${TARGET_TRIPLE}/${NAME}/${MODE}"
        INCLUDE_DIR="$APP_DIR/build/dynamic/${TARGET_TRIPLE}/${NAME}/include"
        mkdir -p "$OUTDIR"

        zig c++ \
          -target "$ZIG_TARGET" \
          $ZIG_FLAGS \
          -fPIC \
          -shared \
          "$CPP" "$C_WRAPPER" \
          -I"$dir" \
          -std=c++20 \
          -o "$OUTDIR/${LIB_PREFIX}${NAME}.${EXT}"

        # Fix install_name for .dylib on macOS
        if [[ "$OS" == "macos" || "$OS" == "osx" ]] && [[ "$EXT" == "dylib" ]]; then
          if command -v llvm-install-name-tool &>/dev/null; then
            echo "[install_name] setting install_name to @rpath/${LIB_PREFIX}${NAME}.${EXT}"
            llvm-install-name-tool -id "@rpath/${LIB_PREFIX}${NAME}.${EXT}" "$OUTDIR/${LIB_PREFIX}${NAME}.${EXT}"
          else
            echo "[install_name] ⚠️ llvm-install-name-tool not found in container. Skipping install_name fix."
          fi
        fi          

        echo "[build_libs_dynamic] ✅ Built: $OUTDIR/${LIB_PREFIX}${NAME}.${EXT}"

        if [ "$MODE" = "release" ]; then
          bash "$SCRIPT_DIR/strip.sh" --bin "$OUTDIR/${LIB_PREFIX}${NAME}.${EXT}" --target-triple "$TARGET_TRIPLE"

          if [ -f "$C_HEADER" ]; then
            mkdir -p "$INCLUDE_DIR"
            cp "$C_HEADER" "$INCLUDE_DIR/${NAME}.h"
            echo "[include] Copied: $INCLUDE_DIR/${NAME}.h"
          fi
        fi

        BUILT_LIBS="$BUILT_LIBS $NAME"
      else
        echo "[build_libs_dynamic] ⚠️ Skipped $NAME (missing ${NAME}.cpp or ${NAME}_c.cpp)"
      fi
    done
  done

  # Package
  if [ -n "$BUILT_LIBS" ]; then
    ARCHIVE_NAME="libs-dynamic-${TARGET_TRIPLE}.tar.gz"
    ARCHIVE_PATH="$PACKAGE_DIR/$ARCHIVE_NAME"
    tar -czf "$ARCHIVE_PATH" -C "$APP_DIR/build/dynamic/${TARGET_TRIPLE}" $BUILT_LIBS
    echo "[packaging] ✅ Created: $ARCHIVE_PATH"
  else
    echo "[packaging] ⚠️ Nothing to package."
  fi

else
  # static
  for MODE in debug release; do
    echo "[build_libs_static] 🔧 Building $MODE..."

    if [ "$MODE" = "debug" ]; then
      ZIG_FLAGS="-O0 -g -fno-sanitize=undefined"
    else
      ZIG_FLAGS="-O3 -DNDEBUG -fno-sanitize=undefined"
    fi
    
    for dir in "$LIB_DIR"/*/; do
      NAME=$(basename "$dir")
      CPP="${dir}${NAME}.cpp"
      C_WRAPPER="${dir}${NAME}_c.cpp"
      C_HEADER="${dir}${NAME}_c.h"

      [ "$OS" = "windows" ] && LIB_PREFIX="" || LIB_PREFIX="lib"

      if [ -f "$CPP" ] && [ -f "$C_WRAPPER" ]; then
        OUTDIR="$APP_DIR/build/static/${TARGET_TRIPLE}/${NAME}/${MODE}"
        INCLUDE_OUTDIR="$APP_DIR/build/static/${TARGET_TRIPLE}/${NAME}/include"
        mkdir -p "$OUTDIR"

        OBJ1="${OUTDIR}/${NAME}.o"
        OBJ2="${OUTDIR}/${NAME}_c.o"
        ARCHIVE="${OUTDIR}/${LIB_PREFIX}${NAME}.${EXT}"

        zig c++ -target "$ZIG_TARGET" $ZIG_FLAGS -c "$CPP" -I"$dir" -std=c++20 -o "$OBJ1"
        zig c++ -target "$ZIG_TARGET" $ZIG_FLAGS -c "$C_WRAPPER" -I"$dir" -std=c++20 -o "$OBJ2"

        if [ "$MODE" = "release" ]; then
          bash "$SCRIPT_DIR/strip.sh" --bin "$OBJ1" --target-triple "$TARGET_TRIPLE"
          bash "$SCRIPT_DIR/strip.sh" --bin "$OBJ2" --target-triple "$TARGET_TRIPLE"
        fi

        zig ar rcs "$ARCHIVE" "$OBJ1" "$OBJ2"
        rm -f "$OBJ1" "$OBJ2"

        echo "[build_libs_static] ✅ Built: $ARCHIVE"

        if [ "$MODE" = "release" ] && [ -f "$C_HEADER" ]; then
          mkdir -p "$INCLUDE_OUTDIR"
          cp "$C_HEADER" "${INCLUDE_OUTDIR}/${NAME}.h"
          echo "[include] Copied: ${INCLUDE_OUTDIR}/${NAME}.h"
        fi

        BUILT_LIBS="$BUILT_LIBS $NAME"
      else
        echo "[build_libs_static] ⚠️ Skipped $NAME (missing source)"
      fi
    done
  done

  # Package
  if [ -n "$BUILT_LIBS" ]; then
    ARCHIVE_NAME="libs-static-${TARGET_TRIPLE}.tar.gz"
    ARCHIVE_PATH="$PACKAGE_DIR/$ARCHIVE_NAME"
    tar -czf "$ARCHIVE_PATH" -C "$APP_DIR/build/static/${TARGET_TRIPLE}" $BUILT_LIBS
    echo "[packaging] ✅ Created: $ARCHIVE_PATH"
  else
    echo "[packaging] ⚠️ Nothing to package."
  fi
fi

echo "[build_libs_$BUILD_TYPE] ✅ All done."

