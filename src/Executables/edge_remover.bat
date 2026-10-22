@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =============================================================================
REM Z-LAG OS - ShadowWhisperer verified-setup Edge/WebView removal pass
REM
REM   1. Use a local setup.exe only when its SHA-256 matches the pinned hash.
REM   2. Otherwise download setup.exe from the requested repository and verify it.
REM   3. Force-uninstall Edge and WebView2.
REM   4. Remove shortcuts, files, tasks, services, AppX and malformed leftovers.
REM
REM remove_edge.ps1 runs immediately after this batch file as the authoritative,
REM idempotent all-user cleanup. Therefore download failure never blocks the
REM playbook and this script never pauses for interactive input.
REM =============================================================================

title Edge and WebView2 Remover - Z-LAG OS
set "expected=4963532e63884a66ecee0386475ee423ae7f7af8a6c6d160cf1237d085adf05e"
set "downloadUrl=https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/_Source/setup.exe"
set "fileSetup=%~dp0setup.exe"
set "downloadedSetup=0"
set "setupReady=0"

REM Administrator / TrustedInstaller permission check. FLTMC does not depend on
REM the Server service, unlike NET SESSION.
fltmc >NUL 2>&1
if errorlevel 1 (
    echo [Z-LAG-EDGE-BAT] Administrator privileges are required.
    exit /b 5
)

REM Prefer a bundled setup.exe only if it is the exact pinned binary.
if exist "%fileSetup%" call :check_hash "%fileSetup%"
if "%setupReady%"=="1" goto uninst_edge

REM Reuse a previously verified temporary copy or download a fresh one.
set "fileSetup=%TEMP%\ZLAG-EdgeSetup.exe"
if exist "%fileSetup%" call :check_hash "%fileSetup%"
if "%setupReady%"=="1" goto uninst_edge
if exist "%fileSetup%" del /f /q "%fileSetup%" >NUL 2>&1

:file_download
echo [Z-LAG-EDGE-BAT] Downloading the verified Edge setup remover...
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%downloadUrl%','%fileSetup%')" >NUL 2>&1
if not exist "%fileSetup%" (
    echo [Z-LAG-EDGE-BAT] Download failed; continuing with local cleanup.
    goto users_cleanup
)
set "downloadedSetup=1"
call :check_hash "%fileSetup%"
if not "%setupReady%"=="1" (
    echo [Z-LAG-EDGE-BAT] Downloaded setup.exe hash did not match; refusing to execute it.
    del /f /q "%fileSetup%" >NUL 2>&1
    goto users_cleanup
)
goto uninst_edge

:check_hash
set "actualHash="
for /f "usebackq delims=" %%H in (`powershell.exe -NoLogo -NoProfile -NonInteractive -Command "(Get-FileHash -LiteralPath '%~1' -Algorithm SHA256).Hash.ToLowerInvariant()" 2^>NUL`) do set "actualHash=%%H"
if /I "%actualHash%"=="%expected%" (
    set "setupReady=1"
) else (
    set "setupReady=0"
)
exit /b 0

REM -----------------------------------------------------------------------------
REM Edge browser and WebView2 official force-uninstall pass.
REM -----------------------------------------------------------------------------
:uninst_edge
echo [Z-LAG-EDGE-BAT] Removing Microsoft Edge...
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" call :run_edge_setup
if exist "%ProgramFiles%\Microsoft\Edge\Application" call :run_edge_setup

:uninst_wv
echo [Z-LAG-EDGE-BAT] Removing WebView2 Runtime...
if exist "%ProgramFiles(x86)%\Microsoft\EdgeWebView\Application" call :run_webview_setup
if exist "%ProgramFiles%\Microsoft\EdgeWebView\Application" call :run_webview_setup

REM Delete empty WebView directories from the deepest path upward.
for /f "delims=" %%D in ('dir /ad /b /s "%ProgramFiles(x86)%\Microsoft\EdgeWebView" 2^>NUL ^| sort /r') do rd "%%D" 2>NUL
for /f "delims=" %%D in ('dir /ad /b /s "%ProgramFiles%\Microsoft\EdgeWebView" 2^>NUL ^| sort /r') do rd "%%D" 2>NUL

REM -----------------------------------------------------------------------------
REM Additional files and every-user shortcuts.
REM -----------------------------------------------------------------------------
:users_cleanup
echo [Z-LAG-EDGE-BAT] Removing additional files and shortcuts...
set "REG_USERS_PATH=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
for /f "skip=2 tokens=2,*" %%C in ('reg query "%REG_USERS_PATH%" /v Public 2^>NUL') do call :user_rem_lnks_by_path "%%D"
for /f "skip=2 tokens=2,*" %%C in ('reg query "%REG_USERS_PATH%" /v Default 2^>NUL') do call :user_rem_lnks_by_path "%%D"
for /f "skip=1 tokens=7 delims=\" %%K in ('reg query "%REG_USERS_PATH%" /k /f "*" 2^>NUL') do call :user_rem_lnks_by_sid "%%K"
goto users_done

:user_rem_lnks_by_sid
set "candidateSid=%~1"
if /I "%candidateSid%"=="S-1-5-18" goto user_end
if /I "%candidateSid%"=="S-1-5-19" goto user_end
if /I "%candidateSid%"=="S-1-5-20" goto user_end
for /f "skip=2 tokens=2,*" %%C in ('reg query "%REG_USERS_PATH%\%candidateSid%" /v ProfileImagePath 2^>NUL') do (
    call :user_rem_lnks_by_path "%%D"
    if /I "%UserProfile%"=="%%D" set "USER_SID=%candidateSid%"
)
goto user_end

:user_rem_lnks_by_path
if "%~1"=="" goto user_end
del /s /q "%~1\Desktop\edge.lnk" >NUL 2>&1
del /s /q "%~1\Desktop\Microsoft Edge.lnk" >NUL 2>&1
del /s /q "%~1\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >NUL 2>&1

:user_end
exit /b 0

:users_done

REM Legacy System32 binaries.
if exist "%SystemRoot%\System32\MicrosoftEdgeCP.exe" (
    for /f "delims=" %%A in ('dir /b "%SystemRoot%\System32\MicrosoftEdge*" 2^>NUL') do (
        takeown /f "%SystemRoot%\System32\%%A" /a >NUL 2>&1
        icacls "%SystemRoot%\System32\%%A" /inheritance:e /grant "*S-1-5-32-544:F" /T /C >NUL 2>&1
        del /f /q "%SystemRoot%\System32\%%A" >NUL 2>&1
    )
)

REM Folders.
taskkill /im MicrosoftEdgeUpdate.exe /f >NUL 2>&1
taskkill /im msedgewebview2.exe /f >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeWebView" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >NUL 2>&1
rd /s /q "%ProgramFiles(x86)%\Microsoft\Temp" >NUL 2>&1
rd /s /q "%ProgramFiles%\Microsoft\Edge" >NUL 2>&1
rd /s /q "%ProgramFiles%\Microsoft\EdgeCore" >NUL 2>&1
rd /s /q "%ProgramFiles%\Microsoft\EdgeWebView" >NUL 2>&1
rd /s /q "%ProgramFiles%\Microsoft\EdgeUpdate" >NUL 2>&1
rd /s /q "%AllUsersProfile%\Microsoft\EdgeUpdate" >NUL 2>&1

REM Start Menu files.
del /s /q "%AllUsersProfile%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" >NUL 2>&1

REM Registry.
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f >NUL 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Edge" /f >NUL 2>&1

REM Scheduled task files and registered task names.
for /r "%SystemRoot%\System32\Tasks" %%F in (*MicrosoftEdge*) do del /f /q "%%F" >NUL 2>&1
for /f "skip=1 tokens=1 delims=," %%A in ('schtasks /query /fo csv 2^>NUL') do (
    echo %%~A | findstr /i "MicrosoftEdge EdgeUpdate WebView" >NUL && schtasks /delete /tn "%%~A" /f >NUL 2>&1
)

REM Update services.
for %%N in (edgeupdate edgeupdatem MicrosoftEdgeElevationService) do (
    sc stop %%N >NUL 2>&1
    sc delete %%N >NUL 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\%%N" /f >NUL 2>&1
)

REM -----------------------------------------------------------------------------
REM Edge AppX removal and deprovisioning markers.
REM -----------------------------------------------------------------------------
echo [Z-LAG-EDGE-BAT] Removing Edge AppX packages...
if not defined USER_SID (
    for /f "delims=" %%A in ('powershell.exe -NoLogo -NoProfile -Command "(New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value" 2^>NUL') do set "USER_SID=%%A"
)
if not defined USER_SID set "USER_SID=S-1-5-18"

set "REG_APPX_STORE=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
for /f "usebackq delims=" %%A in (`powershell.exe -NoLogo -NoProfile -NonInteractive -Command "Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like '*microsoftedge*' -or $_.PackageFullName -like '*webview*' } | Select-Object -ExpandProperty PackageFullName" 2^>NUL`) do (
    if not "%%A"=="" (
        reg add "%REG_APPX_STORE%\EndOfLife\%USER_SID%\%%A" /f >NUL 2>&1
        reg add "%REG_APPX_STORE%\EndOfLife\S-1-5-18\%%A" /f >NUL 2>&1
        reg add "%REG_APPX_STORE%\Deprovisioned\%%A" /f >NUL 2>&1
        powershell.exe -NoLogo -NoProfile -NonInteractive -Command "Remove-AppxPackage -Package '%%A' -ErrorAction SilentlyContinue; Remove-AppxPackage -Package '%%A' -AllUsers -ErrorAction SilentlyContinue" 2>NUL
    )
)

REM Legacy Edge and Win32 WebView SystemApps.
for /d %%D in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*" "%SystemRoot%\SystemApps\Microsoft.Win32WebViewHost*") do (
    if exist "%%~D" (
        takeown /f "%%~D" /a /r /d y >NUL 2>&1
        icacls "%%~D" /grant "*S-1-5-32-544:(OI)(CI)F" /t /c >NUL 2>&1
        rd /s /q "%%~D" >NUL 2>&1
    )
)

REM Remove malformed AppxAllUserStore keys using the supplied validation rules.
echo [Z-LAG-EDGE-BAT] Fixing malformed AppX registry keys...
set "reg_path=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
for /f "tokens=*" %%K in ('reg query "%reg_path%" /s 2^>NUL ^| findstr /b /i "%reg_path%"') do (
    set "full_key=%%K"
    set "delete_key=false"
    set "reason="
    for %%A in ("!full_key!") do set "key_name=%%~nxA"
    if "!key_name!"=="" (
        set "reason=empty key name"
    ) else if "!key_name!"=="!full_key!" (
        set "reason=key name same as full path"
    ) else (
        set "spaced_key=!key_name: =!"
        if not "!key_name!"=="!spaced_key!" (
            set "delete_key=true"
        ) else (
            echo /7 - !key_name! | findstr /r /c:"[a-zA-Z]" >NUL
            if errorlevel 1 set "delete_key=true"
        )
    )
    if "!delete_key!"=="true" reg delete "!full_key!" /f >NUL 2>&1
)

if "%downloadedSetup%"=="1" del /f /q "%fileSetup%" >NUL 2>&1
echo [Z-LAG-EDGE-BAT] Verified setup and legacy cleanup pass complete.
exit /b 0

:run_edge_setup
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$p=Start-Process -FilePath '%fileSetup%' -ArgumentList @('--uninstall','--system-level','--force-uninstall') -WindowStyle Hidden -PassThru; if(-not $p.WaitForExit(180000)){Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; exit 1460}; exit $p.ExitCode" >NUL 2>&1
exit /b 0

:run_webview_setup
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$p=Start-Process -FilePath '%fileSetup%' -ArgumentList @('--uninstall','--msedgewebview','--system-level','--force-uninstall') -WindowStyle Hidden -PassThru; if(-not $p.WaitForExit(180000)){Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; exit 1460}; exit $p.ExitCode" >NUL 2>&1
exit /b 0
