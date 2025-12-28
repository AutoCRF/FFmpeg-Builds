#!/bin/bash

SCRIPT_REPO="https://github.com/Netflix/vmaf.git"
SCRIPT_COMMIT="6b75f37728b2eb70c11508ece93afaacc6572b45"
NV_CODEC_TAG="876af32a202d0de83bd1d36fe74ee0f7fcf86b0d"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    # Kill build of unused and broken tools
    echo > libvmaf/tools/meson.build

    wget -q -O - https://github.com/AutoCRF/vmaf/pull/3.patch | git apply

    mkdir build && cd build

    local myconf=(
        --buildtype=release
        --prefix="$FFBUILD_PREFIX"
        --default-library=static
        -Dbuilt_in_models=true
        -Denable_tests=false
        -Denable_docs=false
        -Denable_avx512=true
        -Denable_asm=true
        -Denable_float=true
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        sed -i '/exe_wrapper/d' /cross.meson
        sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson

        # ---- Install ffmpeg NVIDIA headers ----
        wget https://github.com/FFmpeg/nv-codec-headers/archive/${NV_CODEC_TAG}.zip && unzip ${NV_CODEC_TAG}.zip
        cd nv-codec-headers-${NV_CODEC_TAG}
        make && make install
        make PREFIX="../../build" install
        make PREFIX="$FFBUILD_PREFIX" install
        cd ..

        # ---- Add cuda to meson config ----
        export NVCC_APPEND_FLAGS="-ccbin=/usr/bin/gcc-12"
        myconf+=(
            --cross-file=/cross.meson
            -Denable_cuda=true
            -Denable_nvcc=true
        )
    else
        echo "Unknown target"
        return -1
    fi

    CFLAGS+=" -I../include" meson "${myconf[@]}" ../libvmaf/build ../libvmaf || cat ../libvmaf/build/meson-logs/meson-log.txt

    ninja -j"$(nproc)" -C ../libvmaf/build
    DESTDIR="$FFBUILD_DESTDIR" ninja install -C ../libvmaf/build

    sed -i 's/Libs.private:/Libs.private: -lstdc++/; t; $ a Libs.private: -lstdc++' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
}

ffbuild_configure() {
    (( $(ffbuild_ffver) >= 501 )) || return 0
    echo "--enable-libvmaf --enable-cuda-nvcc"
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
