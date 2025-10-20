#!/bin/bash
set -euxo pipefail

# workaround to get PBP to see that OSX_SDK_DIR is used
# and thus get it forwarded to the build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ${OSX_SDK_DIR:-}
    # Fix for macOS libc++ availability issues
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Determine Metal support for macOS ARM64
if [[ "$OSTYPE" == "darwin"* ]] && [[ "${target_platform}" == "osx-arm64" ]]; then
    WHISPER_METAL=ON
else
    WHISPER_METAL=OFF
fi

cmake -S . -B build -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_METAL=${WHISPER_METAL} \
    -DWHISPER_BUILD_EXAMPLES=ON \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_SERVER=ON

cmake --build build --config Release --verbose
cmake --install build
