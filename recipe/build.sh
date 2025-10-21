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
# Metal gpuAddress property requires macOS 13.0+ (available since whisper.cpp 1.8.x)
if [[ "${target_platform}" == "osx-arm64" ]]; then
    # Extract deployment target version (e.g., "12.1" -> "12")
    MACOS_VERSION=$(echo "${MACOSX_DEPLOYMENT_TARGET:-0}" | cut -d. -f1)
    if [[ "${MACOS_VERSION}" -ge 13 ]]; then
        WHISPER_METAL=ON
    else
        echo "Disabling Metal support for macOS < 13.0 (current target: ${MACOSX_DEPLOYMENT_TARGET})"
        WHISPER_METAL=OFF
    fi
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
