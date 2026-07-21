#!/bin/bash
# Set up environment variables for OpenHarmony cross-compilation.
# Exports OHOS_SDK, OHOS_NDK_HOME, PATH additions, and CMake toolchain path.
# Does NOT set CC/CXX - lycium's envset.sh handles that per-architecture.
set -eu

SDK_PATH="${SDK_PATH}"
NATIVE="$SDK_PATH/native"

# Verify SDK structure
if [ ! -d "$NATIVE/llvm/bin" ]; then
  echo "::error::Invalid SDK path: $NATIVE/llvm/bin not found"
  exit 1
fi

# Core environment variables (available in subsequent steps via $GITHUB_ENV)
echo "OHOS_SDK=$SDK_PATH" >> "$GITHUB_ENV"
echo "OHOS_NDK_HOME=$NATIVE" >> "$GITHUB_ENV"
echo "LYCIUM_BUILD_CHECK=false" >> "$GITHUB_ENV"

# Add toolchain to PATH
echo "$NATIVE/llvm/bin" >> "$GITHUB_PATH"
echo "$NATIVE/build-tools/cmake/bin" >> "$GITHUB_PATH"

# Detect CMake toolchain file (compatible with different SDK versions)
TOOLCHAIN=""
if [ -f "$NATIVE/build/cmake/ohos.toolchain.cmake" ]; then
  TOOLCHAIN="$NATIVE/build/cmake/ohos.toolchain.cmake"
elif [ -f "$NATIVE/build-tools/cmake/share/ohos.toolchain.cmake" ]; then
  TOOLCHAIN="$NATIVE/build-tools/cmake/share/ohos.toolchain.cmake"
else
  echo "::warning::ohos.toolchain.cmake not found in SDK"
fi

if [ -n "$TOOLCHAIN" ]; then
  echo "OHOS_CMAKE_TOOLCHAIN=$TOOLCHAIN" >> "$GITHUB_ENV"
fi

# Step outputs
echo "ohos-sdk=$SDK_PATH" >> "$GITHUB_OUTPUT"
echo "ohos-native=$NATIVE" >> "$GITHUB_OUTPUT"
echo "ohos-cmake-toolchain=$TOOLCHAIN" >> "$GITHUB_OUTPUT"

echo "Environment configured:"
echo "  OHOS_SDK=$SDK_PATH"
echo "  OHOS_NDK_HOME=$NATIVE"
echo "  OHOS_CMAKE_TOOLCHAIN=$TOOLCHAIN"
