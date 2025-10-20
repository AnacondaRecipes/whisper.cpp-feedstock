@echo on
setlocal enabledelayedexpansion

cmake -S . -B build -GNinja ^
    %CMAKE_ARGS% ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DBUILD_SHARED_LIBS=ON ^
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
