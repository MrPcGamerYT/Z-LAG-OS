@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SRC=%~dp0"
set "DEFAULT_SHELL=%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell"
set "DEFAULT_INSTALLER=%SystemDrive%\Users\Default\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"

rem CRITICAL: stop the Start Menu hosts BEFORE deleting their caches. The host
rem keeps the pin list in memory and rewrites start2.bin when it exits, which
rem silently undid every previous cleanup pass. It restarts automatically in
rem the user's session, so this is safe.
taskkill /f /im StartMenuExperienceHost.exe >nul 2>&1
taskkill /f /im ShellExperienceHost.exe >nul 2>&1

if exist "%SystemRoot%\StartMenuLayout.xml" del /f /q "%SystemRoot%\StartMenuLayout.xml" >nul 2>&1
mkdir "%DEFAULT_SHELL%" >nul 2>&1
for %%F in (LayoutModification.xml LayoutModification.json DefaultLayouts.xml) do (
    if exist "%SRC%%%F" copy /y "%SRC%%%F" "%DEFAULT_SHELL%\%%F" >nul 2>&1
)
mkdir "%DEFAULT_INSTALLER%" >nul 2>&1
if exist "%SRC%settings.json" copy /y "%SRC%settings.json" "%DEFAULT_INSTALLER%\settings.json" >nul 2>&1

rem Apply only to currently loaded real user hives. Missing package/cache keys are
rem expected and are silently ignored.
for /f "tokens=1" %%H in ('reg query HKU 2^>nul ^| findstr /r /c:"HKEY_USERS\\S-1-5-21-"') do (
    for /f "tokens=2,*" %%A in ('reg query "%%H\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Local AppData" 2^>nul ^| findstr /i "Local AppData"') do (
        set "LOCALAPP=%%B"
        call set "LOCALAPP=%%LOCALAPP%%"
        if defined LOCALAPP (
            mkdir "!LOCALAPP!\Microsoft\Windows\Shell" >nul 2>&1
            for %%F in (LayoutModification.xml LayoutModification.json DefaultLayouts.xml) do (
                if exist "%SRC%%%F" copy /y "%SRC%%%F" "!LOCALAPP!\Microsoft\Windows\Shell\%%F" >nul 2>&1
            )
            for /d %%P in ("!LOCALAPP!\Packages\Microsoft.Windows.StartMenuExperienceHost*") do (
                del /f /q "%%~fP\LocalState\start*.bin" >nul 2>&1
            )
        )
    )
    rem GamerzOS-style: delete the real Win10 pinned-tile grid (start.tilegrid
    rem keys under CloudStore DefaultAccount) so the pinned section is fully
    rem cleared for every user, not just the cache copy.
    for /f "delims=" %%K in ('reg query "%%H\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" /s /k /f "start.tilegrid" 2^>nul ^| findstr /i "start.tilegrid"') do (
        reg delete "%%K" /f >nul 2>&1
    )
    reg delete "%%H\Software\Microsoft\Windows\CurrentVersion\Start" /v Config /f >nul 2>&1
)

echo [Z-LAG] Start Menu layout and caches reset.
exit /b 0
