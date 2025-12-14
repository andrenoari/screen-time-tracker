@echo off
echo ============================================
echo   Screen Time Tracker - Build Installer
echo ============================================
echo.

echo [1/3] Cleaning previous build...
call flutter clean
if %errorlevel% neq 0 goto error

echo.
echo [2/3] Building Windows release...
call flutter build windows --release
if %errorlevel% neq 0 goto error

echo.
echo [3/3] Creating installer...
echo.
echo Please open 'installer.iss' with Inno Setup Compiler
echo and click Build > Compile to create the installer.
echo.
echo Or run from command line (if Inno Setup is in PATH):
echo   iscc installer.iss
echo.
echo The installer will be created in the 'installer' folder.
echo.

pause
goto end

:error
echo.
echo Build failed! Please check the errors above.
pause

:end
