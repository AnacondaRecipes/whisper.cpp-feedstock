@echo on
setlocal enabledelayedexpansion

set FOUND_IOMP=0

for %%F in (%LIBRARY_BIN%\ggml*.dll %LIBRARY_BIN%\whisper.dll) do (
    if exist "%%~F" (
        dumpbin /dependents "%%~F" | findstr /I "VCOMP libomp" && exit /B 1
        dumpbin /dependents "%%~F" | findstr /I "libiomp5md.dll" && set FOUND_IOMP=1
    )
)

if "!FOUND_IOMP!"=="1" exit /B 0

echo libiomp5md.dll was not found in whisper.cpp or ggml binary dependencies.
exit /B 1
