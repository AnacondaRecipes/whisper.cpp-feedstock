@echo on
setlocal enabledelayedexpansion

:: Determine GPU acceleration settings based on variant
:: Default: no GPU acceleration
set WHISPER_CUDA=OFF
set WHISPER_METAL=OFF
set WHISPER_BLAS=OFF
set WHISPER_OPENBLAS=OFF
set WHISPER_CUBLAS=OFF

:: Handle CUDA variant (covers cuda-12 and cuda-13)
echo %gpu_variant% | findstr /B "cuda-" >nul
if !errorlevel! == 0 (
    set WHISPER_CUDA=ON
    set WHISPER_CUBLAS=ON
    set WHISPER_BLAS=ON
    echo Building with CUDA support ^(cuBLAS^), CUDA %cuda_compiler_version%
)

:: Handle CPU BLAS variants (matching llama.cpp-feedstock approach)
if "%blas_impl%"=="mkl" (
    set WHISPER_BLAS=ON
    set WHISPER_ACCELERATE=OFF
    set WHISPER_OPENBLAS=OFF
    set WHISPER_BLAS_VENDOR=Intel10_64_dyn
    echo Building with MKL support ^(via BLAS^)
) else if "%blas_impl%"=="openblas" (
    set WHISPER_BLAS=ON
    set WHISPER_ACCELERATE=OFF
    set WHISPER_OPENBLAS=ON
    set WHISPER_BLAS_VENDOR=OpenBLAS
    echo Building with OpenBLAS support
) else (
    set WHISPER_BLAS=OFF
    set WHISPER_ACCELERATE=OFF
    set WHISPER_OPENBLAS=OFF
    set WHISPER_BLAS_VENDOR=
)

:: Configure with CMake
set CMAKE_FLAGS=-S . -B build -GNinja ^
    %CMAKE_ARGS% ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DBUILD_SHARED_LIBS=ON ^
    -DGGML_CUDA=%WHISPER_CUDA% ^
    -DGGML_METAL=%WHISPER_METAL% ^
    -DGGML_BLAS=%WHISPER_BLAS% ^
    -DGGML_ACCELERATE=%WHISPER_ACCELERATE% ^
    -DGGML_OPENBLAS=%WHISPER_OPENBLAS% ^
    -DGGML_CUBLAS=%WHISPER_CUBLAS% ^
    -DWHISPER_CURL=ON ^
    -DWHISPER_BUILD_EXAMPLES=ON ^
    -DWHISPER_BUILD_TESTS=OFF ^
    -DWHISPER_BUILD_SERVER=ON

:: Add BLAS vendor if specified
if defined WHISPER_BLAS_VENDOR (
    set CMAKE_FLAGS=%CMAKE_FLAGS% -DGGML_BLAS_VENDOR=%WHISPER_BLAS_VENDOR%
)

cmake %CMAKE_FLAGS%
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake configure failed" & exit /b !ERRORLEVEL!)

cmake --build build --config Release --verbose
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake build failed" & exit /b !ERRORLEVEL!)

cmake --install build
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake install failed" & exit /b !ERRORLEVEL!)

echo Build completed successfully
exit /b 0
