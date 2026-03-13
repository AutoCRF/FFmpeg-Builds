# mkdir /tmp/intel
# # cd /tmp/intel
# # --- Part A: Get libze-dev from Ubuntu repositories ---
# # 'apt-get download' fetches the .deb to the current dir without installing it
# #
# # https://archive.ubuntu.com/ubuntu/dists/jammy/universe/binary-amd64/Packages.gz
# UBUNTU_REPO="http://archive.ubuntu.com/ubuntu"
# wget -qO- ${UBUNTU_REPO}/dists/questing/universe/binary-amd64/Packages.gz | gunzip > /tmp/U_Packages
# REL_PATH=$(grep -A 20 "^Package: libze1$" /tmp/U_Packages | grep "^Filename:" | head -n 1 | awk '{print $2}')
# wget -q "${UBUNTU_REPO}/${REL_PATH}" -P /tmp/intel/

# # --- Part B: Get the Compiler from Intel's repo manually ---
# URL_BASE="https://apt.repos.intel.com/oneapi"
# # Fetch the index to find the latest filename
# wget -qO- ${URL_BASE}/dists/all/main/binary-amd64/Packages.gz | gunzip > /tmp/I_Packages
# REL_PATH=$(grep -A 20 "^Package: intel-oneapi-compiler-dpcpp-cpp$" /tmp/I_Packages | grep "^Filename:" | head -n 1 | awk '{print $2}')

# wget -q "${URL_BASE}/${REL_PATH}" -P /tmp/intel/
# REL_PATH=$(grep -A 20 "^Package: intel-oneapi-compiler-dpcpp-cpp-2021.1.1$" /tmp/I_Packages | grep "^Filename:" | head -n 1 | awk '{print $2}')

# wget -q "${URL_BASE}/${REL_PATH}" -P /tmp/intel/

# # --- Part C: Extract everything to /tmp/intel ---
# # dpkg -x extracts the filesystem content of the .deb into the current folder (.)
# for deb in /tmp/intel/*.deb; do dpkg -x "$deb" /tmp/intel/; done

# Cleanup installers and index

# # 1. Configuration
# export INSTALL_DIR="/tmp/intel"
# export DOWNLOAD_URL="https://registrationcenter-download.intel.com/akdlm/IRC_NAS/6caa93ca-e10a-4cc5-b210-68f385feea9e/intel-oneapi-base-toolkit-2025.3.1.36.sh"
# export INSTALLER_NAME="basekit_installer.sh"

# # 2. Setup Directory
# echo "Creating directory at $INSTALL_DIR..."
# mkdir -p "$INSTALL_DIR/install" "$INSTALL_DIR/download" "$INSTALL_DIR/extract"

# # 3. Download
# if [ ! -f "$INSTALLER_NAME" ]; then
#     echo "Downloading Intel oneAPI Base Toolkit..."
#     curl -L "$DOWNLOAD_URL" -o "$INSTALLER_NAME"
# fi

# # 4. Silent Install
# echo "Installing icpx and ze_loader to $INSTALL_DIR..."
# bash "$INSTALLER_NAME" --extract-folder "$INSTALL_DIR/extract" -a --silent --eula accept \
#   --install-dir "$INSTALL_DIR/install" \
#   --download-dir "$INSTALL_DIR/download" \
#   --components intel.oneapi.lin.dpcpp-cpp-compiler

# # 5. Export Paths (Current Session Only)
export PATH="/opt/intel/oneapi/compiler/latest/bin:$PATH"
# export PATH="/opt/intel/oneapi/compiler/latest/bin/intel64:$PATH"
export LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/lib:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="$INSTALL_DIR/level-zero/latest/lib:$LD_LIBRARY_PATH"

# 6. Verification
echo "------------------------------------------------"
echo "Installation complete."
icpx --version && echo "Success: icpx is in the PATH."
#find / | grep -i ze_loader && exit 1
echo "------------------------------------------------"

# Optional: cleanup installer
# rm "$INSTALLER_NAME"

if [[ "$VARIANT" == *legacy ]]; then
    NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "aarch64")
    NV_VER="12.9.1"
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_nvcc
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cudart
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component libcurand
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cccl
    patch -p1 math_functions.h -d "/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </patches/glibc.patch
    patch -p0 math_functions.h -d "/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </patches/glibc.diff
else
    NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "sbsa")
    NV_VER="13.1.0"
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_nvcc
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cudart
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_crt
    /patches/nvidia.py --label "${NV_VER}" --product cuda --output "/tmp/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component libnvvm
    patch -p1 math_functions.h -d "/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </patches/glibc.patch
fi

export SYCL_PROGRAM_COMPILE_OPTION="${SYCL_PROGRAM_COMPILE_OPTIONS} -fcp-host-compiler=${CC}"
export NVCC_APPEND_FLAGS="-ccbin=${CC}"
export NVCC_PREPEND_FLAGS="-I/opt/ffbuild/include"
export __INTEL_PRE_CFLAGS="-I/opt/ffbuild/include"
export CUDA_PATH="/tmp/cuda-${NV_VER}/linux-${NV_ARCH}"
export CUDA_HOME="/tmp/cuda-${NV_VER}/linux-${NV_ARCH}"
export PATH="${PATH}:/tmp/cuda-${NV_VER}/linux-${NV_ARCH}/bin"
export PATH="${PATH}:/opt/intel/oneapi/compiler/latest/linux/bin"
git config user.email "builder@localhost"
git config user.name "Builder"
git config advice.detachedHead false

if [[ "$TARGET" != "winarm64" && "$STAGENAME" == *vmaf ]]; then
    sed -i '/exe_wrapper/d' /cross.meson
    sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson
    myconf+=(
        --cross-file=/cross.meson
        -Denable_asm=true
        -Denable_cuda=true
        -Denable_nvcc=true
    )
    # if [[ "$TARGET" == "*arm64" ]]; then
    #     myconf+=(
    #         -Denable_sycl=true
    #     )
    # fi

    if [[ "$VARIANT" == *legacy ]]; then
        git apply --directory=.. /patches/vmaf-nvcc-legacy.patch
    else
        git apply --directory=.. /patches/vmaf-nvcc.patch
    fi

elif [[ -z "$STAGENAME" ]]; then

    if [[ "$VARIANT" == *legacy ]]; then
        git apply /patches/ffmpeg-nvcc-legacy.patch
    else
        git apply /patches/ffmpeg-nvcc.patch
    fi

fi
#source /opt/intel/oneapi/setvars.sh
PATH="/opt/intel/oneapi/compiler/latest/bin:$PATH"
LD_LIBRARY_PATH="/opt/intel/oneapi/compiler/latest/lib:/usr/include/level_zero/loader:$LD_LIBRARY_PATH"
