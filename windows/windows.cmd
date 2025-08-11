@echo off
cd /d "%~dp0"
title MBOP Setup - Minecraft Bedrock on PC
setlocal enabledelayedexpansion
set "LOGFILE=setup_log.txt"
echo [START] %date% %time% > "%LOGFILE%"

:: Check admin
net session >nul 2>&1 || (
    echo [^^!] Admin rights required. Relaunching as admin... >> "%LOGFILE%"
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

:menu
:: GUI using PowerShell MessageBox
for /f %%i in ('powershell -NoProfile -Command ^
  "Add-Type -AssemblyName System.Windows.Forms; $res = [System.Windows.Forms.MessageBox]::Show(\"Install or Upgrade Minecraft? Choose No if you want to uninstall Minecraft.\", \"MBOP Setup\", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); if ($res -eq 'Yes') { 'install' } else { 'uninstall' }"') do (
    set "USERCHOICE=%%i"
)

if /i "%USERCHOICE%"=="install" goto install
if /i "%USERCHOICE%"=="uninstall" goto uninstall
exit /b

:install
>>"%LOGFILE%" echo [START INSTALL] %date% %time%
ver | findstr /i "10." >nul || (
    echo [^^!] Unsupported Windows version! >> "%LOGFILE%"
    echo [^^!] This script only works on Windows 10 or later!
    pause
    exit /b
)

if not exist runtime mkdir runtime
if not exist dll mkdir dll

echo [^^!] Starting installation...
echo [*] This command window will be a verbose log for what is happening with your computer.

:: DLL setup
set "DLL_TARGET=%SystemRoot%\System32\Windows.ApplicationModel.Store.dll"
set "DLL_SOURCE=%~dp0dll\Windows.ApplicationModel.Store.dll"

echo.
echo [*] Replacing Windows.ApplicationModel.Store.dll...

if not exist "!DLL_SOURCE!" (
    echo [^^!] Missing DLL. Downloading from GitHub... >> "%LOGFILE%"
    powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NammIsADev/MinecraftBEOnPC/main/windows/dll/Windows.ApplicationModel.Store.dll' -OutFile '!DLL_SOURCE!'" >> "%LOGFILE%" 2>&1
    if not exist "!DLL_SOURCE!" (
        echo [^^!] DLL download failed! >> "%LOGFILE%"
        echo [^^!] DLL download failed^^! Is it your PC are connected to the internet?
        goto skip_dll
    )
)

takeown /f "!DLL_TARGET!" >nul
icacls "!DLL_TARGET!" /grant administrators:F >nul
copy /y "!DLL_SOURCE!" "!DLL_TARGET!" >nul && (
    echo [+] DLL replaced successfully. >> "%LOGFILE%"
) || (
    echo [^^!] DLL copy failed. >> "%LOGFILE%"
    echo [^^!] DLL copy failed. Are you having Bitlocker or Antivirus? Turn it off^^!
)

:skip_dll

:: Locate Minecraft main package
set "pkg_file="
for %%f in (runtime\*.appx runtime\*.msix runtime\*.msixbundle) do (
    if not defined pkg_file set "pkg_file=%%~f"
)

if not defined pkg_file (
    echo [^^!] Failed to install Minecraft^^! Please check "setup_log.txt"^^! 
    echo [*] Writing log please wait... This could take some second...
    echo [^^!] Minecraft package not found. >> "%LOGFILE%"
    ping -n 1 localhost >nul
    echo [^!] ProductID to download Appx ^(remember to download lib like VCLib too^) 1>>"setup_log.txt"
    ping -n 1 localhost >nul
    echo       9NBLGGH2JHXJ >> "%LOGFILE%"
    ping -n 1 localhost >nul
    echo [^^!] Download it from >> "%LOGFILE%" 
    ping -n 1 localhost >nul
    echo       store.rg-adguard.net >> "%LOGFILE%"
    ping -n 1 localhost >nul
    echo [^^!] Put them in "runtime" folder. Then re-run this script^^! >> "%LOGFILE%"
    ping -n 1 localhost >nul
    echo [END INSTALL] %date% %time% INSTALLATION HALTED BECAUSE ERROR >>"%LOGFILE%"
    pause
    exit /b
)

:: Install dependencies
for %%f in (runtime\Microsoft.VCLibs* runtime\Microsoft.NET.Native*) do (
    echo [*] Installing dependency: %%~nxf >> "%LOGFILE%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Try { Add-AppxPackage -Path '%%~f' -ErrorAction Stop } Catch { Exit 1 }"
    if !errorlevel! neq 0 (
        echo [^^!] Failed: %%~nxf >> "%LOGFILE%"
    ) else (
        echo [+] Installed: %%~nxf >> "%LOGFILE%"
    )
)

:: Install Minecraft
echo [*] Installing: !pkg_file! >> "%LOGFILE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Try { Add-AppxPackage -Path '!pkg_file!' -ErrorAction Stop } Catch { Exit 1 }"
if !errorlevel! neq 0 (
    echo [^^!] Minecraft installation failed^^! >> "%LOGFILE%"
    pause
    exit /b
)

echo [:)] Minecraft Bedrock installed successfully! >> "%LOGFILE%"
echo [:)] Enjoy Minecraft Bedrock! Installed successfully^^! 
>>"%LOGFILE%" echo [END INSTALL] %date% %time%
pause
exit /b

:uninstall
>>"%LOGFILE%" echo [START UNINSTALL] %date% %time%
powershell -Command "Get-AppxPackage -Name Microsoft.MinecraftUWP | Remove-AppxPackage"
echo Minecraft has been removed.
>>"%LOGFILE%" echo [END UNINSTALL] %date% %time%
pause
exit /b
