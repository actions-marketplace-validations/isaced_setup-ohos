#!/bin/bash
# Install DevEco command-line tools (hvigor / ohpm / node / HarmonyOS SDK all-in-one)
# on a GitHub Actions runner.
#
# Adapted from cnb-setup-ohos/scripts/install-deveco.sh. The single zip ships the
# ENTIRE ArkTS toolchain: hvigor 6.24.4 (native, supports API 20+ SDKs),
# ohpm 6.1.2.285, node 18 and a complete HarmonyOS SDK (API 24, incl. hms) in the
# exact layout hvigor expects (sdk/default/{openharmony,hms,sdk-pkg.json}).
#
# The official download link is signed & expiring, so the zip is mirrored at:
#   https://github.com/isaced/setup-ohos/releases/download/v1/commandline-tools-linux-x64-6.1.1.300.zip
#
# When actions/cache restores the extracted directory, download is skipped entirely.
set -eu

CLT_VERSION="${CLT_VERSION:-6.1.1.300}"
CLT_URL="${CLT_URL:-https://github.com/isaced/setup-ohos/releases/download/v1/commandline-tools-linux-x64-${CLT_VERSION}.zip}"
CLT_CACHE_HIT="${CLT_CACHE_HIT:-false}"
PNPM_VERSION="${PNPM_VERSION:-8.13.1}"
OHPM_REGISTRY="${OHPM_REGISTRY:-https://ohpm.openharmony.cn/ohpm/}"
DEVECO_ROOT="$RUNNER_TEMP/deveco"

if [ "$CLT_CACHE_HIT" = "true" ] && [ -x "$DEVECO_ROOT/bin/hvigorw" ]; then
  echo "DevEco tools restored from cache: $DEVECO_ROOT"
elif [ -x "$DEVECO_ROOT/bin/hvigorw" ]; then
  echo "DevEco tools already present: $DEVECO_ROOT"
else
  echo "::group::Downloading DevEco command-line tools ${CLT_VERSION}"
  curl -fL --retry 3 -o /tmp/clt.zip "$CLT_URL"
  echo "::endgroup::"

  rm -rf /tmp/clt-extract "$DEVECO_ROOT"
  mkdir -p /tmp/clt-extract
  echo "::group::Extracting DevEco tools"
  unzip -q -o /tmp/clt.zip -d /tmp/clt-extract
  mv /tmp/clt-extract/command-line-tools "$DEVECO_ROOT"
  rm -rf /tmp/clt.zip /tmp/clt-extract
  echo "::endgroup::"
fi

# ---------- sanity checks ----------
test -x "$DEVECO_ROOT/bin/hvigorw" || { echo "::error::hvigorw missing in $DEVECO_ROOT"; exit 1; }
test -x "$DEVECO_ROOT/bin/ohpm"    || { echo "::error::ohpm missing in $DEVECO_ROOT"; exit 1; }
test -x "$DEVECO_ROOT/tool/node/bin/node" || { echo "::error::node missing in $DEVECO_ROOT"; exit 1; }
test -d "$DEVECO_ROOT/sdk/default/openharmony/ets"    || { echo "::error::SDK ets missing"; exit 1; }
test -d "$DEVECO_ROOT/sdk/default/openharmony/native" || { echo "::error::SDK native missing"; exit 1; }

# ---------- ohpm registry configuration ----------
export NODE_HOME="$DEVECO_ROOT/tool/node"
export PATH="$NODE_HOME/bin:$PATH"
"$DEVECO_ROOT/bin/ohpm" config set registry "$OHPM_REGISTRY" || true
"$DEVECO_ROOT/bin/ohpm" config set strict_ssl false || true

# ---------- pre-install pnpm ----------
# hvigor bootstraps pnpm on first build; installing eagerly against a fast
# mirror removes that runtime bootstrap entirely.
npm config set registry https://registry.npmmirror.com || true
npm install -g "pnpm@${PNPM_VERSION}" || \
  echo "::warning::pnpm pre-install failed, hvigor will bootstrap it at build time"

# ---------- sanity output ----------
"$DEVECO_ROOT/bin/hvigorw" --version 2>&1 | head -1 || echo "warn: hvigorw --version failed"
"$DEVECO_ROOT/bin/ohpm" -v 2>/dev/null || echo "warn: ohpm -v failed"

echo "==> DevEco toolchain ready at ${DEVECO_ROOT}"
