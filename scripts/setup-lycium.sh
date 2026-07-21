#!/bin/bash
# Clone and set up the lycium cross-compilation framework.
# lycium automates C/C++ third-party library cross-compilation for OpenHarmony.
# The preparetoolchain() in lycium's build.sh handles toolchain wrapper scripts
# (aarch64-linux-ohos-clang etc.) automatically on first run.
set -eu

LYCIUM_REPO="${LYCIUM_REPO}"
LYCIUM_REF="${LYCIUM_REF}"
LYCIUM_HOME="$RUNNER_TEMP/lycium"

CLONE_ARGS="--depth 1"
if [ -n "$LYCIUM_REF" ]; then
  CLONE_ARGS="$CLONE_ARGS --branch $LYCIUM_REF"
fi

echo "Cloning lycium from: $LYCIUM_REPO"
git clone $CLONE_ARGS "$LYCIUM_REPO" "$LYCIUM_HOME"

# Create the usr directory required by lycium's build.sh
mkdir -p "$LYCIUM_HOME/lycium/usr"

echo "LYCIUM_HOME=$LYCIUM_HOME" >> "$GITHUB_ENV"
echo "lycium-home=$LYCIUM_HOME" >> "$GITHUB_OUTPUT"

echo "lycium ready at: $LYCIUM_HOME"
echo "Usage: cd \$LYCIUM_HOME/lycium && ./build.sh <package>"
