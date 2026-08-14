@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Z-LAG OS - Aggressive Microsoft Edge Remover (WebView2 preserved)

echo.
echo ============================================================
echo   Z-LAG OS - AGGRESSIVE MICROSOFT EDGE REMOVER
echo   Removes the Edge BROWSER completely.
echo   WebView2 runtime is PRESERVED (apps depend on it).
echo ============================================================
echo.

:: ------------------------------------------------------------------
:: Admin check
:: ------------------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run this script as Administrator.
    pause
    exit /b 1
)

:: ------------------------------------------------------------------
:: [1/8] Close Edge browser processes.
::       NOTE: msedgewebview2.exe (WebView2) is intentionally NOT killed.
:: ------------------------------------------------------------------
echo [1/8] Closing Edge browser processes (WebView2 untouched)...
taskkill /f /im msedge.exe /t >nul 2>&1
taskkill /f /im msedge_proxy.exe /t >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe /t >nul 2>&1
taskkill /f /im MicrosoftEdgeCP.exe /t >nul 2>&1
taskkill /f /im MicrosoftEdgeSH.exe /t >nul 2>&1

:: ------------------------------------------------------------------
:: [2/8] Run the official uninstaller shipped inside Edge, if present.
:: ------------------------------------------------------------------
echo [2/8] Running the official Edge uninstaller if available...
set "EDGE_APP=%ProgramFiles(x86)%\Microsoft\Edge\Application"
set "EDGE_SETUP="
if exist "%EDGE_APP%\" (
    for /f "delims=" %%V in ('dir /b /ad "%EDGE_APP%" 2^>nul') do (
        if exist "%EDGE_APP%\%%V\Installer\setup.exe" set "EDGE_SETUP=%EDGE_APP%\%%V\Installer\setup.exe"
    )
)
if defined EDGE_SETUP (
    echo   - %EDGE_SETUP%
    "%EDGE_SETUP%" --uninstall --system-level --force-uninstall --verbose-logging >nul 2>&1
) else (
    echo   - Official uninstaller not found; proceeding with manual removal.
)

:: ------------------------------------------------------------------
:: [3/8] Stop and delete Edge update services.
:: ------------------------------------------------------------------
echo [3/8] Stopping and deleting Edge update services...
for %%S in (edgeupdate edgeupdatem MicrosoftEdgeElevationService) do (
    sc stop %%S >nul 2>&1
    sc delete %%S >nul 2>&1
)

:: ------------------------------------------------------------------
:: [4/8] Remove Edge scheduled tasks.
::       WebView2 runtime files are kept; it simply stops self-updating
::       (updates are blocked by this OS anyway).
:: ------------------------------------------------------------------
echo [4/8] Removing Edge scheduled tasks...
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f >nul 2>&1
rd /s /q "%SystemRoot%\System32\Tasks\Microsoft\Windows\EdgeUpdate" >nul 2>&1
rd /s /q "%SystemRoot%\System32\Tasks\Microsoft\Windows\Edge" >nul 2>&1

:: ------------------------------------------------------------------
:: [5/8] Remove Edge AppX packages (WebView2 / WebExperience kept).
:: ------------------------------------------------------------------
echo [5/8] Removing Edge AppX packages (WebView2 kept)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*Edge*' -and $_.Name -notlike '*WebView*' -and $_.Name -notlike '*WebExperience*' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*Edge*' -and $_.DisplayName -notlike '*WebView*' -and $_.DisplayName -notlike '*WebExperience*' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue"

:: ------------------------------------------------------------------
:: [6/8] Delete Edge files and folders.
::       "%ProgramFiles(x86)%\Microsoft\EdgeWebView" (WebView2) is
::       intentionally PRESERVED.
:: ------------------------------------------------------------------
echo [6/8] Deleting Edge files and folders (WebView2 folder preserved)...
rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" >nul 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" >nul 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >nul 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Temp" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft\EdgeUpdate" >nul 2>&1
rd /s /q "%LocalAppData%\Microsoft\Edge" >nul 2>&1
rd /s /q "%LocalAppData%\Microsoft\EdgeUpdate" >nul 2>&1
del /f /q "%tmp%\setup.exe" >nul 2>&1
del /f /q "%~dp0setup.exe" >nul 2>&1

:: Legacy EdgeHTML leftovers (SystemApps + System32)
for /d %%d in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
    takeown /f "%%~d" /r /d y >nul 2>&1
    icacls "%%~d" /grant administrators:F /t >nul 2>&1
    rd /s /q "%%~d" >nul 2>&1
)
for %%f in ("%SystemRoot%\System32\MicrosoftEdgeCP.exe" "%SystemRoot%\System32\MicrosoftEdgeSH.exe" "%SystemRoot%\System32\MicrosoftEdge.exe") do (
    if exist "%%~f" (
        takeown /f "%%~f" >nul 2>&1
        icacls "%%~f" /grant administrators:F >nul 2>&1
        del /f /q "%%~f" >nul 2>&1
    )
)

:: ------------------------------------------------------------------
:: [7/8] Remove Edge shortcuts from EVERY user profile:
::       Desktop, Start Menu, Taskbar, Quick Launch.
:: ------------------------------------------------------------------
echo [7/8] Removing Edge shortcuts (Desktop / Start Menu / Taskbar / Quick Launch) for all users...
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do call :clean_user "%%c"

:: Common (all-users) locations
del /f /q "%Public%\Desktop\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%Public%\Desktop\edge.lnk" >nul 2>&1
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\edge.lnk" >nul 2>&1

:: Unpin Edge from the Start Menu tile cache (forces Start to rebuild without Edge)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -LiteralPath '%LOCALAPPDATA%\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start.bin' -Force -ErrorAction SilentlyContinue"

:: ------------------------------------------------------------------
:: [8/8] Clean registry entries.
::       Only the Edge BROWSER update-client GUID is removed; the
::       WebView2 runtime client is left intact.
:: ------------------------------------------------------------------
echo [8/8] Cleaning registry (WebView2 entries preserved)...
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>&1
reg delete "HKCU\Software\Clients\StartMenuInternet\Microsoft Edge" /f >nul 2>&1
reg delete "HKCR\MSEdgeHTM" /f >nul 2>&1
reg delete "HKCR\MSEdgePDF" /f >nul 2>&1
reg delete "HKCR\MSEdgeMHT" /f >nul 2>&1
reg delete "HKCR\MSEdgeHTML" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\RegisteredApplications" /v "Microsoft Edge" /f >nul 2>&1

:: Remove ONLY the Edge browser update client - keep the WebView2 runtime client.
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /f >nul 2>&1

:: Block Edge from ever reinstalling itself through Windows Update.
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v DoNotUpdateToEdgeWithChromium /t REG_DWORD /d 1 /f >nul 2>&1

echo.
echo ============================================================
echo   Microsoft Edge has been completely removed.
echo   WebView2 runtime preserved (still working for apps).
echo ============================================================
echo.
exit /b 0

:: ------------------------------------------------------------------
:: clean_user: wipe Edge shortcuts + user data for ONE profile path.
:: ------------------------------------------------------------------
:clean_user
set "UP=%~1"
if "%UP%"=="" exit /b 0
if not exist "%UP%" exit /b 0

del /f /q "%UP%\Desktop\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%UP%\Desktop\edge.lnk" >nul 2>&1
del /f /q "%UP%\Desktop\Microsoft Edge (1).lnk" >nul 2>&1
del /f /q "%UP%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%UP%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\edge.lnk" >nul 2>&1
del /f /q "%UP%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%UP%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\edge.lnk" >nul 2>&1
del /f /q "%UP%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >nul 2>&1
del /f /q "%UP%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\edge.lnk" >nul 2>&1
rd /s /q "%UP%\AppData\Local\Microsoft\Edge" >nul 2>&1
rd /s /q "%UP%\AppData\Local\Microsoft\EdgeUpdate" >nul 2>&1
exit /b 0
