FROM ubuntu:25.10

ARG TARGETPLATFORM

ENV DEBIAN_FRONTEND=noninteractive
RUN \
    apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install --no-install-recommends \
        $([ "$TARGETPLATFORM" != "linux/amd64" ] || echo gcc-multilib g++-multilib) \
        build-essential yasm nasm \
        xxd pkgconf curl wget unzip zip git subversion mercurial rsync jq \
        autoconf automake libtool libtool-bin autopoint gettext cmake meson ninja-build \
        clang llvm lcov lld qemu-user \
        texinfo texi2html help2man flex bison groff \
        gperf itstool ragel libc6-dev zlib1g-dev libssl-dev \
        gtk-doc-tools gobject-introspection gawk \
        ocaml ocaml-findlib ocamlbuild libnum-ocaml-dev indent p7zip-full zstd \
        python3-setuptools python3-pip python3-venv python3-jinja2 python3-jsonschema python3-apt python3-dev python-is-python3 && \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get -y install nodejs && \
    apt-get -y install --no-install-recommends gcc-12 g++-12 && \
    apt-get -y autoremove && \
    apt-get -y clean autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    git config --global user.email "builder@localhost" && \
    git config --global user.name "Builder" && \
    git config --global advice.detachedHead false

ENV CARGO_HOME="/opt/cargo" RUSTUP_HOME="/opt/rustup" PATH="/opt/cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path && \
    cargo install cargo-c && rm -rf "${CARGO_HOME}"/registry "${CARGO_HOME}"/git

RUN --mount=src=.,dst=/input \
    for s in /input/*.sh; do cp $s /usr/bin/$(echo $s | sed -e 's|.*/||' -e 's/\.sh$//'); done

ENV HOST_CC="gcc" \
    HOST_CXX="g++" \
    HOST_CFLAGS="-O2 -pipe" \
    HOST_CXXFLAGS="-O2 -pipe"

# ---- Set environment variables for CUDA ----
ENV CUDA_PATH="/usr/local/cuda" \
    CUDA_HOME="/usr/local/cuda" \
    PATH="${PATH}:/usr/local/cuda/bin"

# ---- Install nvcc and CUDA libraries ----
RUN NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "sbsa") \
    NV_VER="13.1.0" \
    && wget -O nvidia.py https://raw.githubusercontent.com/NVIDIA/build-system-archive-import-examples/refs/heads/main/parse_redist.py \
    && chmod +x nvidia.py \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda --os linux --arch ${NV_ARCH} --component cuda_nvcc \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda --os linux --arch ${NV_ARCH} --component cuda_cudart \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda --os linux --arch ${NV_ARCH} --component cuda_crt \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda --os linux --arch ${NV_ARCH} --component libnvvm \
    && ln -sfn /usr/local/cuda/linux-${NV_ARCH}/lib     /usr/local/cuda/lib \
    && ln -sfn /usr/local/cuda/linux-${NV_ARCH}/lib     /usr/local/cuda/lib64 \
    && ln -sfn /usr/local/cuda/linux-${NV_ARCH}/include /usr/local/cuda/include \
    && ln -sfn /usr/local/cuda/linux-${NV_ARCH}/bin     /usr/local/cuda/bin \
    && cd /usr/local/cuda/linux-${NV_ARCH}/include/crt \
    && wget -O math.patch https://raw.githubusercontent.com/stefantalpalaru/gentoo-overlay/75b7793fdc88314165ca28c75b557defcb38f6d8/dev-util/nvidia-cuda-toolkit/files/nvidia-cuda-toolkit-glibc-2.42.patch \
    && patch -p1 math_functions.h <math.patch 
