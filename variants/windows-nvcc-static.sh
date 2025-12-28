#!/bin/bash
FF_CONFIGURE="--enable-gpl --enable-version3 --disable-debug --enable-cuda-nvcc --enable-nonfree --disable-ffplay"
FF_CFLAGS=""
FF_CXXFLAGS=""
FF_LDFLAGS=""
GIT_BRANCH="master"
LICENSE_FILE=""

package_variant() {
    IN="$1"
    OUT="$2"

    mkdir -p "$OUT"
    cp "$IN"/bin/* "$OUT"
}
