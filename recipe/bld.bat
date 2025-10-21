@echo on
setlocal enabledelayedexpansion

:: Determine GPU acceleration settings based on variant
:: Default: no GPU acceleration
set WHISPER_CUDA=OFF
set WHISPER_METAL=OFF
set WHISPER_BLAS=OFF
set WHISPER_OPENBLAS=OFF
set WHISPER_CUBLAS=OFF

:: Handle CUDA variant
if "%gpu_variant%"=="cuda-12" (
    set WHISPER_CUDA=ON
    set WHISPER_CUBLAS=ON
    set WHISPER_BLAS=ON
    echo Building with CUDA support ^(cuBLAS^)
)

:: Handle CPU BLAS variants
if "%gpu_variant%"=="none" (
    set WHISPER_BLAS=ON

    if "%blas_impl%"=="openblas" (
        set WHISPER_OPENBLAS=ON
        echo Building with OpenBLAS support
    ) else if "%blas_impl%"=="mkl" (
        echo Building with MKL support ^(via BLAS^)
    )
)

:: Configure with CMake
cmake -S . -B build -GNinja ^
    %CMAKE_ARGS% ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DBUILD_SHARED_LIBS=ON ^
    -DGGML_CUDA=%WHISPER_CUDA% ^
    -DGGML_METAL=%WHISPER_METAL% ^
    -DGGML_BLAS=%WHISPER_BLAS% ^
    -DGGML_OPENBLAS=%WHISPER_OPENBLAS% ^
    -DGGML_CUBLAS=%WHISPER_CUBLAS% ^
    -DWHISPER_BUILD_EXAMPLES=ON ^
    -DWHISPER_BUILD_TESTS=OFF ^
    -DWHISPER_BUILD_SERVER=ON
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake configure failed" & exit /b !ERRORLEVEL!)

cmake --build build --config Release --verbose
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake build failed" & exit /b !ERRORLEVEL!)

cmake --install build
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake install failed" & exit /b !ERRORLEVEL!)

echo Build completed successfully
exit /b 0
