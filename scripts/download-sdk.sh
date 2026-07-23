#!/bin/bash
# Download and extract the OpenHarmony SDK.
# When actions/cache restores the SDK directory, download is skipped entirely.
set -eu

SDK_VERSION="${SDK_VERSION}"
SDK_URL="${SDK_URL:-https://repo.huaweicloud.com/openharmony/os/${SDK_VERSION}/ohos-sdk-windows_linux-public.tar.gz}"
SDK_CACHE_HIT="${SDK_CACHE_HIT:-false}"
CACHE_DIR="$RUNNER_TEMP/ohos-sdk/${SDK_VERSION}"

if [ "$SDK_CACHE_HIT" = "true" ] && [ -d "$CACHE_DIR/linux/native" ]; then
  echo "SDK restored from cache: $CACHE_DIR"
elif [ -d "$CACHE_DIR/linux/native" ]; then
  echo "SDK already exists locally: $CACHE_DIR"
else
  echo "Downloading OHOS SDK ${SDK_VERSION}..."
  echo "URL: $SDK_URL"
  mkdir -p "$CACHE_DIR"
  curl -# -o /tmp/ohos-sdk.tar.gz "$SDK_URL" 2>&1
  echo "Extracting SDK..."
  tar -C "$CACHE_DIR" -zxf /tmp/ohos-sdk.tar.gz
  rm -f /tmp/ohos-sdk.tar.gz

  # Remove Windows SDK (not needed on Linux runners)
  rm -rf "$CACHE_DIR/windows"

  # Extract zip archives inside linux/ directory.
  # Lycium only needs the native toolchain, skip the rest.
  cd "$CACHE_DIR/linux"
  for i in *.zip; do
    [ -f "$i" ] || continue
    if [ "$i" = "native.zip" ]; then
      echo "Extracting $i..."
      unzip -q "$i"
    else
      echo "Skip $i (not needed)"
    fi
    rm "$i"
  done
fi

# Verify the native directory exists
if [ ! -d "$CACHE_DIR/linux/native" ]; then
  echo "::error::SDK extraction failed - native/ directory not found"
  exit 1
fi

echo "SDK ready at: $CACHE_DIR/linux"
echo "sdk-path=$CACHE_DIR/linux" >> "$GITHUB_OUTPUT"
