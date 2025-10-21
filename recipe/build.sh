#!/bin/bash
set -euxo pipefail

# workaround to get PBP to see that OSX_SDK_DIR is used
# and thus get it forwarded to the build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ${OSX_SDK_DIR:-}
    # Fix for macOS libc++ availability issues
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Determine GPU acceleration settings based on variant
# Default: no GPU acceleration
WHISPER_CUDA=OFF
WHISPER_METAL=OFF
WHISPER_BLAS=OFF
WHISPER_OPENBLAS=OFF
WHISPER_CUBLAS=OFF

# Handle CUDA variant
if [[ "${gpu_variant:-none}" == "cuda-12" ]]; then
    WHISPER_CUDA=ON
    WHISPER_CUBLAS=ON
    WHISPER_BLAS=ON
    echo "Building with CUDA support (cuBLAS)"
fi

# Handle Metal variant (macOS ARM64 only)
if [[ "${gpu_variant:-none}" == "metal" ]]; then
    if [[ "${target_platform}" == "osx-arm64" ]]; then
        WHISPER_METAL=ON
        echo "Building with Metal support for Apple Silicon"
    else
        echo "Metal variant requested but not on osx-arm64, disabling Metal"
    fi
fi

# Handle CPU BLAS variants
if [[ "${gpu_variant:-none}" == "none" ]]; then
    WHISPER_BLAS=ON

    if [[ "${blas_impl:-}" == "openblas" ]]; then
        WHISPER_OPENBLAS=ON
        echo "Building with OpenBLAS support"
    elif [[ "${blas_impl:-}" == "mkl" ]]; then
        echo "Building with MKL support (via BLAS)"
    elif [[ "${blas_impl:-}" == "accelerate" ]]; then
        echo "Building with Accelerate framework (macOS)"
    fi
fi

# Configure with CMake
cmake -S . -B build -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_CUDA=${WHISPER_CUDA} \
    -DGGML_METAL=${WHISPER_METAL} \
    -DGGML_BLAS=${WHISPER_BLAS} \
    -DGGML_OPENBLAS=${WHISPER_OPENBLAS} \
    -DGGML_CUBLAS=${WHISPER_CUBLAS} \
    -DWHISPER_BUILD_EXAMPLES=ON \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_SERVER=ON

cmake --build build --config Release --verbose
cmake --install build
