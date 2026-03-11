#!/bin/bash

SCRIPT_REPO="https://github.com/oneapi-src/level-zero.git"
SCRIPT_COMMIT="v1.18.0"

ffbuild_enabled() {
    # Other oneAPI/Vulkan libs disable 32-bit targets
    [[ $TARGET != *32 ]] || return -1
    [[ $TARGET == *arm64 ]] && return -1
    return 0
}

ffbuild_depends() {
    echo opencl
}

ffbuild_dockerstage() {
    to_df "RUN --mount=src=${SELF},dst=/stage.sh --mount=src=${SELFCACHE},dst=/cache.tar.xz run_stage /stage.sh"
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    local myconf=(
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTS=OFF
        -DLEVEL_ZERO_BUILD_TOOLS=OFF
    )

    cmake -G Ninja "${myconf[@]}" ..
    ninja -j"$(nproc)"
    DESTDIR="$FFBUILD_DESTDIR" ninja install

    if [ -f "$FFBUILD_DESTPREFIX"/lib/pkgconfig/ze_loader.pc ]; then
        echo "Libs.private: -lstdc++" >>"$FFBUILD_DESTPREFIX"/lib/pkgconfig/ze_loader.pc
    fi

}
