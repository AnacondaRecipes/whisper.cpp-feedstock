#!/bin/bash
set -euxo pipefail

# workaround to get PBP to see that OSX_SDK_DIR is used
# and thus get it forwarded to the build
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo $OSX_SDK_DIR
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

# Handle Metal variant (matching llama.cpp approach)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "${gpu_variant:-none}" == "none" ]]; then
        # Explicitly disable Metal for none variant to prevent auto-detection
        # Metal requires macOS 13.0+ for gpuAddress property
        WHISPER_METAL=OFF
        echo "Building CPU-only variant (Metal disabled)"
    elif [[ "${gpu_variant:-none}" == "metal" ]]; then
        if [[ "${target_platform}" == "osx-arm64" ]]; then
            WHISPER_METAL=ON
            echo "Building with Metal support for Apple Silicon"
        else
            echo "Metal variant requested but not on osx-arm64, disabling Metal"
            WHISPER_METAL=OFF
        fi
    fi
fi

# Handle CPU BLAS variants (matching llama.cpp-feedstock approach)
if [[ "${blas_impl:-}" == "accelerate" ]]; then
    WHISPER_BLAS=ON
    WHISPER_ACCELERATE=ON
    WHISPER_OPENBLAS=OFF
    WHISPER_BLAS_VENDOR="Apple"
    echo "Building with Accelerate framework (macOS)"
elif [[ "${blas_impl:-}" == "mkl" ]]; then
    WHISPER_BLAS=ON
    WHISPER_ACCELERATE=OFF
    WHISPER_OPENBLAS=OFF
    WHISPER_BLAS_VENDOR="Intel10_64_dyn"
    echo "Building with MKL support (via BLAS)"
elif [[ "${blas_impl:-}" == "openblas" ]]; then
    WHISPER_BLAS=ON
    WHISPER_ACCELERATE=OFF
    WHISPER_OPENBLAS=ON
    WHISPER_BLAS_VENDOR="OpenBLAS"
    echo "Building with OpenBLAS support"
else
    WHISPER_BLAS=OFF
    WHISPER_ACCELERATE=OFF
    WHISPER_OPENBLAS=OFF
    WHISPER_BLAS_VENDOR=""
fi

# Configure with CMake
CMAKE_FLAGS=(
    -S . -B build -GNinja
    ${CMAKE_ARGS}
    -DCMAKE_INSTALL_PREFIX=${PREFIX}
    -DCMAKE_PREFIX_PATH=${PREFIX}
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DGGML_CUDA=${WHISPER_CUDA}
    -DGGML_METAL=${WHISPER_METAL}
    -DGGML_BLAS=${WHISPER_BLAS}
    -DGGML_ACCELERATE=${WHISPER_ACCELERATE}
    -DGGML_OPENBLAS=${WHISPER_OPENBLAS}
    -DGGML_CUBLAS=${WHISPER_CUBLAS}
    -DWHISPER_CURL=ON
    -DWHISPER_BUILD_EXAMPLES=ON
    -DWHISPER_BUILD_TESTS=OFF
    -DWHISPER_BUILD_SERVER=ON
)

# Add BLAS vendor if specified
if [[ -n "${WHISPER_BLAS_VENDOR}" ]]; then
    CMAKE_FLAGS+=(-DGGML_BLAS_VENDOR=${WHISPER_BLAS_VENDOR})
fi

cmake "${CMAKE_FLAGS[@]}"

cmake --build build --config Release --verbose
cmake --install build
