@echo on
setlocal enabledelayedexpansion

@rem ggml and its BLAS / OpenMP / CUDA backends come from libllama
@rem (WHISPER_USE_SYSTEM_GGML), so no GGML_* options are set here.
cmake -S . -B build -GNinja ^
    %CMAKE_ARGS% ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DBUILD_SHARED_LIBS=ON ^
    -DWHISPER_USE_SYSTEM_GGML=ON ^
    -DWHISPER_BUILD_EXAMPLES=ON ^
    -DWHISPER_BUILD_TESTS=OFF ^
    -DWHISPER_BUILD_SERVER=ON ^
    -DWHISPER_BUILD_IS_DEV=OFF
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake configure failed" & exit /b !ERRORLEVEL!)

cmake --build build --config Release --verbose
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake build failed" & exit /b !ERRORLEVEL!)

cmake --install build
if !ERRORLEVEL! NEQ 0 (echo "ERROR: cmake install failed" & exit /b !ERRORLEVEL!)

echo Build completed successfully
exit /b 0
