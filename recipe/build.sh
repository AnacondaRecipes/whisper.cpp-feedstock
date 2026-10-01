#!/bin/bash
set -euxo pipefail

# workaround to get PBP to see that OSX_SDK_DIR is used
# and thus get it forwarded to the build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $OSX_SDK_DIR
fi

# ggml and its BLAS / OpenMP / CUDA / Metal backends come from libllama
# (WHISPER_USE_SYSTEM_GGML), so no GGML_* options are set here.
CMAKE_FLAGS=(
    -S . -B build -GNinja
    ${CMAKE_ARGS}
    -DCMAKE_INSTALL_PREFIX=${PREFIX}
    -DCMAKE_PREFIX_PATH=${PREFIX}
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DWHISPER_USE_SYSTEM_GGML=ON
    -DWHISPER_BUILD_EXAMPLES=ON
    -DWHISPER_BUILD_TESTS=OFF
    -DWHISPER_BUILD_SERVER=ON
    # upstream defaults to ON, which stamps "<version>-dev" into whisper_version() and the .pc files
    -DWHISPER_BUILD_IS_DEV=OFF
)

cmake "${CMAKE_FLAGS[@]}"

cmake --build build --config Release --verbose
cmake --install build
