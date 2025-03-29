#!/bin/sh

# Usage: sh build.sh <basename> <os> <arch> <build_type>
# Example: sh build.sh main linux x86_64 release
# Example: sh build.sh main linux aarch64 debug
# Example: sh build.sh main macos x86_64 debug
# Example: sh build.sh main macos aarch64 debug
# Example: sh build.sh main windows x86_64 release
# Example: sh build.sh main windows aarch64 debug

BASENAME="$1"
OS="$2"
ARCH="$3"
BUILD_TYPE="$4"

if [ -z "$BASENAME" ] || [ -z "$OS" ] || [ -z "$ARCH" ] ||  [ -z "$BUILD_TYPE" ]; then
    echo "Usage: $0 <basename> <os> <arch> <build_type>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
cd "$ROOT_DIR" || exit 1
BUILDTYPE_OS_ARCH_PATH="build/${BUILD_TYPE}/${OS}-${ARCH}"
mkdir -p ${BUILDTYPE_OS_ARCH_PATH}

INCLUDES=$(find lib -type d -exec printf -- "-I%s " {} \;)

# Compose Zig target triple
if [ "$OS" = "macos" ]; then
    ZIG_TARGET="$ARCH-macos"
    EXT=""
elif [ "$OS" = "windows" ]; then
    ZIG_TARGET="$ARCH-windows-gnu"
    EXT=".exe"
elif [ "$OS" = "linux" ]; then
    ZIG_TARGET="$ARCH-linux-gnu"
    EXT=""
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Determine the build mode
if [ "$BUILD_TYPE" = "release" ]; then
    OPTIMIZE="-O3"
    # ex) release build: no debug symbols
    DEBUG_FLAG="-g0"
elif [ "$BUILD_TYPE" = "debug" ]; then
    OPTIMIZE="-O0"
    # ex) debug build: include debug symbols
    DEBUG_FLAG="-g -Og"
else
    echo "Unsupported build type: $BUILD_TYPE"
    exit 1
fi

OUTPUT="${BUILDTYPE_OS_ARCH_PATH}/${BASENAME}-${OS}-${ARCH}-${BUILD_TYPE}${EXT}"

# Compile with Zig(detect source files and include directories automatically)
zig c++ \
  -target "$ZIG_TARGET" \
  $(find src lib -name '*.cpp') \
  $INCLUDES \
  -std=c++20 \
  -o "$OUTPUT" \
  $DEBUG_FLAG $OPTIMIZE

# if release build, strip the binary
if [ "$BUILD_TYPE" = "release" ]; then
    if [ "$OS" = "linux" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            x86_64-linux-gnu-strip "$OUTPUT"
        elif [ "$ARCH" = "aarch64" ]; then
            aarch64-linux-gnu-strip "$OUTPUT"
        fi
    elif [ "$OS" = "macos" ]; then
        echo "Strip is not available to macOS executables"
        echo "Please use 'strip [executable]' on macOS(match with the target) to strip the executable"
    elif [ "$OS" = "windows" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            x86_64-w64-mingw32-strip "$OUTPUT"
        elif [ "$ARCH" = "aarch64" ]; then
            aarch64-w64-mingw32-strip "$OUTPUT"
        fi
    fi
fi
