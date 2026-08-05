#!/bin/bash
# Set up environment variables for OpenHarmony cross-compilation.
# Exports OHOS_SDK, OHOS_NDK_HOME, PATH additions, and CMake toolchain path.
# Does NOT set CC/CXX - lycium's envset.sh handles that per-architecture.
#
# When HVIGOR_MODE=true, the HarmonyOS SDK bundled with the DevEco command-line
# tools is reused as OHOS_SDK (the standalone OpenHarmony SDK download is
# skipped), and the DevEco ArkTS toolchain env vars are exported too:
#   DEVECO_ROOT / DEVECO_NODE_HOME / DEVECO_SDK_HOME / NODE_HOME
#   PATH += <deveco>/bin (hvigorw, ohpm), <node>/bin
set -eu

HVIGOR_MODE="${HVIGOR_MODE:-false}"

if [ "$HVIGOR_MODE" = "true" ]; then
  # ---- DevEco mode: reuse the SDK bundled with the command-line tools ----
  DEVECO_ROOT="${RUNNER_TEMP}/deveco"
  DEVECO_NODE_HOME="${DEVECO_ROOT}/tool/node"
  DEVECO_SDK_HOME="${DEVECO_ROOT}/sdk"
  SDK_PATH="${DEVECO_SDK_HOME}/default/openharmony"
  NATIVE="$SDK_PATH/native"

  # Verify SDK structure
  if [ ! -d "$NATIVE/llvm/bin" ]; then
    echo "::error::Invalid SDK path: $NATIVE/llvm/bin not found"
    exit 1
  fi

  # Core environment variables
  echo "OHOS_SDK=$SDK_PATH" >> "$GITHUB_ENV"
  echo "OHOS_NDK_HOME=$NATIVE" >> "$GITHUB_ENV"
  echo "LYCIUM_BUILD_CHECK=false" >> "$GITHUB_ENV"
  echo "DEVECO_ROOT=$DEVECO_ROOT" >> "$GITHUB_ENV"
  echo "DEVECO_NODE_HOME=$DEVECO_NODE_HOME" >> "$GITHUB_ENV"
  echo "DEVECO_SDK_HOME=$DEVECO_SDK_HOME" >> "$GITHUB_ENV"
  echo "NODE_HOME=$DEVECO_NODE_HOME" >> "$GITHUB_ENV"

  # Add toolchain to PATH (hvigorw/ohpm first, then node, then NDK, then cmake)
  echo "$DEVECO_ROOT/bin" >> "$GITHUB_PATH"
  echo "$DEVECO_NODE_HOME/bin" >> "$GITHUB_PATH"
  echo "$NATIVE/llvm/bin" >> "$GITHUB_PATH"
  echo "$NATIVE/build-tools/cmake/bin" >> "$GITHUB_PATH"
else
  # ---- Standalone mode: OpenHarmony SDK downloaded by download-sdk.sh ----
  SDK_PATH="${SDK_PATH:?SDK_PATH is required}"
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
fi

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

if [ "$HVIGOR_MODE" = "true" ]; then
  echo "deveco-root=$DEVECO_ROOT" >> "$GITHUB_OUTPUT"
  echo "deveco-sdk-home=$DEVECO_SDK_HOME" >> "$GITHUB_OUTPUT"
fi

echo "Environment configured:"
echo "  OHOS_SDK=$SDK_PATH"
echo "  OHOS_NDK_HOME=$NATIVE"
echo "  OHOS_CMAKE_TOOLCHAIN=$TOOLCHAIN"
if [ "$HVIGOR_MODE" = "true" ]; then
  echo "  DEVECO_ROOT=$DEVECO_ROOT"
  echo "  DEVECO_NODE_HOME=$DEVECO_NODE_HOME"
  echo "  DEVECO_SDK_HOME=$DEVECO_SDK_HOME"
fi
