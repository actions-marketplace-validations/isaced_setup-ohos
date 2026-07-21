#!/bin/bash
# Install build tools for OpenHarmony cross-compilation.
# Supports two levels:
#   minimal - tools required by lycium's checkbuildenv()
#   full    - Docker-equivalent environment covering 349+ thirdparty libraries
set -eu

TOOLS_LEVEL="${TOOLS_LEVEL:-minimal}"

if [ "$TOOLS_LEVEL" = "minimal" ]; then
  echo "::group::Installing minimal build tools"
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    gcc g++ cmake make ninja-build \
    pkg-config autoconf automake \
    patch unzip curl wget git coreutils
  echo "::endgroup::"
elif [ "$TOOLS_LEVEL" = "full" ]; then
  echo "::group::Installing full build tools"
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    build-essential gcc g++ gcc-multilib g++-multilib \
    cmake make ninja-build \
    pkg-config autoconf automake libtool libtool-bin autopoint \
    patch unzip curl wget git coreutils \
    gperf flex bison yasm nasm \
    python3 python3-pip \
    gettext texinfo xmlto po4a \
    libxml2-utils libxml2-dev libxml-parser-perl \
    subversion gfortran tcl-dev
  pip3 install meson
  echo "::endgroup::"
else
  echo "::warning::Unknown tools level '$TOOLS_LEVEL', skipping installation"
fi
