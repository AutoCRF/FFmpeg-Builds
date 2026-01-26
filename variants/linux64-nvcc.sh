#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/linux64-gpl.sh
FF_CONFIGURE="--enable-cuda-nvcc --enable-nonfree $FF_CONFIGURE"
LICENSE_FILE=""
