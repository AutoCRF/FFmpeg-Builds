#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/win32-gpl-shared.sh
FF_CONFIGURE="--enable-cuda-nvcc --enable-nonfree $FF_CONFIGURE"
