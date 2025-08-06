@echo off
title MBOP Setup - Minecraft Bedrock on PC
color 0a
setlocal enabledelayedexpansion

:: Check Windows version
ver | findstr /i "10." >nul || (
    echo [!] This script only works on Windows 10 or later!
    pause
    exit /b
)

:: Check for Administrator privilege
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Please run this script as Administrator.
    pause
    exit /b
)

:: Create folders if not exist
if not exist runtime mkdir runtime
if not exist dll mkdir dll

:: Try to find App Installer in WinSxS
echo [+] Checking for App Installer...
set "installer_path="
for /R "%SystemRoot%\WinSxS" %%f in (*DesktopAppInstaller*.appx *DesktopAppInstaller*.msixbundle) do (
    set "installer_path=%%f"
    goto :found_installer
)

:found_installer
if defined installer_path (
    echo [+] Found App Installer in WinSxS:
    echo     !installer_path!
    powershell -Command "Add-AppxPackage -Path '!installer_path!'" 
    if %errorlevel% neq 0 (
        echo [!] Failed to install App Installer from WinSxS.
        pause
        exit /b
    )
) else (
    echo [!] App Installer not found!
    echo.
    echo [!] You must download and install App Installer manually.
    echo     1. Visit: https://store.rg-adguard.net/
    echo     2. Paste Product ID: 9NBLGGH4NNS1
    echo     3. Download and place the all the lib and App Installer (.appx or .msixbundle) into the ^"runtime^" folder.
    echo     If the installer encounters an error, please end any related tasks and run this script again.
    pause
    exit /b
)

:: Install all runtime packages
echo [*] Installing dependencies from ^"runtime^" folder...
for %%I in ("runtime\*.appx" "runtime\*.msixbundle") do (
    echo [*] Installing: %%~nxI
    powershell -command "Add-AppxPackage -Path '%%~fI'" || echo [!] Failed to install: %%~nxI
)

:: Replace DLL for Minecraft runtime
echo.
echo [*] Replacing Windows.ApplicationModel.Store.dll...
set DLL_TARGET=%SystemRoot%\System32\Windows.ApplicationModel.Store.dll
set DLL_SOURCE=%~dp0dll\Windows.ApplicationModel.Store.dll

if exist "!DLL_SOURCE!" (
    takeown /f "!DLL_TARGET!" >nul
    icacls "!DLL_TARGET!" /grant administrators:F >nul
    copy /y "!DLL_SOURCE!" "!DLL_TARGET!" >nul && (
        echo [+] DLL replaced successfully.
    ) || (
        echo [!] Failed to replace the DLL!
    )
) else (
    echo [!] Missing DLL file in ^"dll^" folder!
)

:: Install Minecraft package from current folder
echo.
echo [+] Looking for Minecraft .appx / .msix / .msixbundle in current folder...
set pkg_file=
for %%f in (*.appx *.msix *.msixbundle) do (
    set pkg_file=%%f
    goto :found_pkg
)

:found_pkg
if not defined pkg_file (
    echo [!] No .appx / .msix / .msixbundle found in this folder.
    echo.
    echo     Please get Minecraft Bedrock and all lib package from:
    echo     https://store.rg-adguard.net/
    echo     Paste this Product ID: 9NBLGGH2JHXJ
    echo.
    echo Then put the downloaded file here and re-run this script.
    pause
    exit /b
)

:: Install Minecraft
echo [+] Installing: !pkg_file!
powershell -command "Add-AppxPackage -Path '.\!pkg_file!'" 
if %errorlevel% neq 0 (
    echo [!] Minecraft installation failed.
    pause
    exit /b
)

echo.
echo [✔] Minecraft Bedrock installed successfully!
echo Enjoy Minecraft Bedrock!
pause
exit /b
