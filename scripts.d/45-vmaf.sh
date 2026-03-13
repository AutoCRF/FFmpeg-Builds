#!/bin/bash

SCRIPT_REPO="https://github.com/lusoris/vmaf.git"
SCRIPT_COMMIT="06de35614e31503aac608bae512568eac187f586"

ffbuild_enabled() {
    return 0
}

ffbuild_depends() {
    echo base
    echo ffnvcodec
    echo onevpl
    echo level-zero
}

ffbuild_dockerstage() {
    to_df "RUN --mount=src=${SELF},dst=/stage.sh --mount=src=${SELFCACHE},dst=/cache.tar.xz --mount=src=patches/nvcc,dst=/patches run_stage /stage.sh"
}

ffbuild_dockerbuild() {
    # Kill build of unused and broken tools
    echo >libvmaf/tools/meson.build

    # git apply /patches/0001-fix-install.patch

    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        -Dbuilt_in_models=true
        -Denable_tests=false
        -Denable_docs=false
        -Denable_avx512=true
        -Denable_float=true
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    else
        echo "Unknown target"
        return -1
    fi

    source /patches/nvcc.sh
    echo 1

    #export CXXFLAGS="-fsycl -fpc-host-compiler=x86_64-ffbuild-linux-gnu-g++"
    #export LDFLAGS="-fsycl -fpc-host-compiler=x86_64-ffbuild-linux-gnu-g++"

    # export SYCL_PROGRAM_COMPILE_OPTION="${SYCL_PROGRAM_COMPILE_OPTIONS} -fcp-host-compiler=${CC}"

    # export LDFLAGS="$LDFLAGS /usr/lib/x86_64-linux-gnu/libze_loader.so"

    meson "${myconf[@]}" ../libvmaf ../libvmaf/build || cat ../libvmaf/build/meson-logs/meson-log.txt
    ninja -j"$(nproc)" -C ../libvmaf/build
    DESTDIR="$FFBUILD_DESTDIR" ninja install -C ../libvmaf/build

    # echo 'char __libc_single_threaded = 0;' | ${CC} -x c -c - -o "$FFBUILD_DESTPREFIX"/lib/libc_single_threaded_stub.o
    #sed -i 's|Libs.private:|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib -Wl, -lstdc++ -lsycl -lze_loader -lsvml -lintlc -lirc -lur_loader -lz|; t; $ a Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib -Wl, -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's|Libs.private:|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu -lstdc++ -lsycl -lze_loader -lsvml -lintlc -lirc -lur_loader -lz|; t; $ a Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu -lstdc++ -lsycl -lze_loader -lsvml -lintlc -lirc -lur_loader -lz' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    # sed -i 's|Libs.private:.*|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib -Wl,--allow-shlib-undefined -Wl,--defsym=__libc_single_threaded=0 -Wl,/usr/lib/x86_64-linux-gnu/libze_loader.so -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz|' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's|Libs.private:.*|Libs.private: /opt/ffbuild/lib/libc_hack.o /opt/ffbuild/lib/libc_single_threaded_stub.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,--allow-shlib-undefined -lstdc++ -lsycl /usr/lib/x86_64-linux-gnu/libze_loader.so -lsvml -lintlc -lirc -lur_loader -lz|' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's|Libs.private:.*|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu -lstdc++ -lsycl /usr/lib/x86_64-linux-gnu/libze_loader.so -lsvml -lintlc -lirc -lur_loader -lz|' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's|Libs.private:.*|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu -lstdc++ -lsycl /usr/lib/x86_64-linux-gnu/libze_loader.so -lsvml -lintlc -lirc -lur_loader -lz|' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's|Libs.private:|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -L/usr/lib/x86_64-linux-gnu -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu -lstdc++ -lsycl -lze_loader -lsvml -lintlc -lirc -lur_loader -lz|; t; $ a Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -L/usr/lib/x86_64-linux-gnu -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib:/lib64:/usr/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu -lstdc++ -lsycl -lze_loader -lsvml -lintlc -lirc -lur_loader -lz' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's|Libs.private:|Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib -lstdc++ -lsycl -lze_loader -lsvml -lintlc -lirc -lur_loader -lz|; t; $ a Libs.private: /opt/ffbuild/lib/libc_hack.o -L/opt/intel/oneapi/compiler/latest/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's/Libs.private:/Libs.private: -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz/; t; $ a Libs.private: -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's/Libs.private:/Libs.private: -L\/opt\/intel\/oneapi\/compiler\/latest\/lib -L\/opt\/intel\/oneapi\/compiler\/2025.3\/lib -Wl,-rpath-link=\/opt\/intel\/oneapi\/compiler\/latest\/lib -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz/; t; $ a Libs.private: -L/opt/intel/oneapi/compiler/latest/lib -L/opt/intel/oneapi/compiler/2025.3/lib -Wl,-rpath-link=/opt/intel/oneapi/compiler/latest/lib -lstdc++ -lsycl -lsvml -lintlc -lirc -lur_loader -lz' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    #sed -i 's/Libs.private:/Libs.private: -L\/opt\/intel\/oneapi\/compiler\/latest\/lib -Wl,-rpath-link=\/opt\/intel\/oneapi\/compiler\/latest\/lib /' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
    sed -i 's/Libs.private:/Libs.private: -lstdc++/; t; $ a Libs.private: -lstdc++' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
}

ffbuild_configure() {
    (($(ffbuild_ffver) >= 501)) || return 0
    echo --enable-libvmaf
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
