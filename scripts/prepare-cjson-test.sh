#!/bin/bash
# Prepare cJSON HPKBUILD for lycium cross-compilation test.
# Called by the CI workflow to create the HPKBUILD file in the
# lycium thirdparty directory so that build.sh can find it.
set -eu

CJSON_DIR="${LYCIUM_HOME:?LYCIUM_HOME not set}/thirdparty/cJSON"
mkdir -p "$CJSON_DIR"

cat > "$CJSON_DIR/HPKBUILD" << 'HPK'
pkgname=cJSON
pkgver=v1.7.19
pkgrel=0
pkgdesc=""
url="https://github.com/DaveGamble/cJSON"
archs=("armeabi-v7a" "arm64-v8a")
license=("MIT")
depends=()
makedepends=()

source="https://github.com/DaveGamble/$pkgname/archive/refs/tags/$pkgver.tar.gz"

autounpack=true
downloadpackage=true
buildtools="cmake"

builddir=$pkgname-${pkgver:1}
packagename=$builddir.tar.gz

prepare() {
    mkdir -p $builddir/$ARCH-build
}

build() {
    cd $builddir
    PKG_CONFIG_LIBDIR="${pkgconfigpath}" ${OHOS_SDK}/native/build-tools/cmake/bin/cmake "$@" \
        -DOHOS_ARCH=$ARCH -B$ARCH-build -S./ -L > $buildlog 2>&1
    $MAKE VERBOSE=1 -C $ARCH-build >> $buildlog 2>&1
    ret=$?
    cd $OLDPWD
    return $ret
}

package() {
    cd $builddir
    $MAKE VERBOSE=1 -C $ARCH-build install >> $buildlog 2>&1
    cd $OLDPWD
}

check() {
    echo "The test must be on an OpenHarmony device!"
}

cleanbuild(){
    rm -rf ${PWD}/$builddir
}
HPK