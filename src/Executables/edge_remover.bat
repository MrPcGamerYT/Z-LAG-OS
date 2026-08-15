@echo off
title Full Microsoft Edge Remover 

echo Closing Edge...
taskkill /F /IM msedge.exe >nul 2>&1

echo Uninstalling Microsoft Edge (All Versions)...
cd %PROGRAMFILES(X86)%\Microsoft\Edge\Application\

for /d %%i in (*.*.*.*) do (
    echo Removing version: %%i
    %%i\Installer\setup.exe --uninstall --system-level --force-uninstall
)

cd %PROGRAMFILES%\Microsoft\Edge\Application\
for /d %%i in (*.*.*.*) do (
    echo Removing version: %%i
    %%i\Installer\setup.exe --uninstall --system-level --force-uninstall
)

echo Removing Edge WebView2...
for /f "tokens=2 delims== " %%i in ('wmic product where "name like 'Microsoft Edge WebView%'" get IdentifyingNumber /value ^| find "="') do (
    msiexec /x %%i /qn
)

echo Deleting leftover folders...
rmdir /s /q "%PROGRAMFILES(X86)%\Microsoft\Edge" >nul 2>&1
rmdir /s /q "%PROGRAMFILES%\Microsoft\Edge" >nul 2>&1
rmdir /s /q "%LOCALAPPDATA%\Microsoft\Edge" >nul 2>&1
rmdir /s /q "%APPDATA%\Microsoft\Edge" >nul 2>&1

echo Blocking Edge from reinstalling...
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "UpdateDefault" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "AutoUpdateCheckPeriodMinutes" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "DisableInstall" /t REG_DWORD /d 1 /f >nul

echo.
echo Microsoft Edge fully removed!


[Theme]
DisplayName=ZX OS • Deep Purple Gaming
ThemeId={7B6C2E91-5A44-4D8D-9F2A-6E8B4C71D930}

[Control Panel\Desktop]
Wallpaper=%windir%\AtlasModules\Wallpapers\atlas-v0.4.x-light.png
Pattern=
MultimonBackgrounds=0
PicturePosition=10
WindowsSpotlight=0

[Control Panel\Colors]
ActiveTitle=18 5 38
InactiveTitle=12 4 25
TitleText=245 238 255
InactiveTitleText=155 140 175
Hilight=91 25 190
HilightText=255 255 255
HotTrackingColor=122 42 220
Menu=10 4 20
MenuText=240 232 250
Window=9 4 18
WindowText=242 235 250
ButtonFace=20 8 35
ButtonText=242 235 250
GrayText=125 112 145
InfoWindow=14 5 27
InfoText=242 235 250
Scrollbar=18 7 31
Background=4 2 8
AppWorkspace=7 3 13
ButtonShadow=3 1 6
ButtonHilight=42 18 65
ButtonDkShadow=0 0 0
ButtonLight=31 12 48
WindowFrame=28 8 52
MenuHilight=74 18 145
MenuBar=9 4 18

[Control Panel\Cursors]
AppStarting=%windir%\cursors\aero_working.ani
Arrow=%windir%\cursors\aero_arrow.cur
Hand=%windir%\cursors\aero_link.cur
Help=%windir%\cursors\aero_helpsel.cur
No=%windir%\cursors\aero_unavail.cur
NWPen=%windir%\cursors\aero_pen.cur
SizeAll=%windir%\cursors\aero_move.cur
SizeNESW=%windir%\cursors\aero_nesw.cur
SizeNS=%windir%\cursors\aero_ns.cur
SizeNWSE=%windir%\cursors\aero_nwse.cur
SizeWE=%windir%\cursors\aero_ew.cur
UpArrow=%windir%\cursors\aero_up.cur
Wait=%windir%\cursors\aero_busy.ani
DefaultValue=Windows Default

[Sounds]
SchemeName=No Sounds

[VisualStyles]
Path=%windir%\resources\themes\Aero\Aero.msstyles
ColorStyle=NormalColor
Size=NormalSize
AutoColorization=0
ColorizationColor=0xC45B00BE
SystemMode=Dark
AppMode=Dark
VisualStyleVersion=10

[MasterThemeSelector]
MTSM=RJSPBS

ÿþ&cls
@echo off
@chcp 65001 >nul
shift /0
color 0d
cd %systemroot%\system32
call :IsAdmin
SETLOCAL EnableDelayedExpansion
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)

cls
::Tweaks
bcdedit /set linearaddress57 OptOut
bcdedit /set increaseuserva 268435328
bcdedit /set firstmegabytepolicy UseAll
bcdedit /set avoidlowmemory 0x8000000
bcdedit /set nolowmem Yes
bcdedit /set allowedinmemorysettings 0x0
bcdedit /set isolatedcontext No
bcdedit /set vsmlaunchtype Off
bcdedit /set vm No
bcdedit /set configaccesspolicy Default
bcdedit /set MSI Default
bcdedit /set usephysicaldestination No
bcdedit /set usefirmwarepcisettings No
bcdedit /set allowedinmemorysettings 0
bcdedit /deletevalue useplatformclock
bcdedit /set useplatformtick Yes
bcdedit /set tscsyncpolicy Enhanced
bcdedit /set debug No
bcdedit /set pae ForceEnable
bcdedit /set bootmenupolicy Legacy
bcdedit /set sos Yes
bcdedit /set disabledynamictick Yes
bcdedit /set disableelamdrivers Yes
bcdedit /set quietboot Yes
bcdedit /set ems No
bcdedit /set linearaddress57 optin
bcdedit /set noumex Yes
bcdedit /set bootems No
bcdedit /set graphicsmodedisabled No
bcdedit /set extendedinput Yes
bcdedit /set highestmode Yes
bcdedit /set forcefipscrypto No
bcdedit /set perfmem 0
bcdedit /set configflags 0
bcdedit /set uselegacyapicmode No
bcdedit /set onecpu No
bcdedit /set halbreakpoint No
bcdedit /set forcelegacyplatform No
bcdedit /set useplatformclock no
bcdedit /set useplatformtick yes
bcdedit /set firstmegabytepolicy UseAll 
bcdedit /set forcefipscrypto No
bcdedit /set nx AlwaysOff
bcdedit /timeout 2
bcdedit /set {globalsettings} custom:16000067 true
bcdedit /set {globalsettings} custom:16000069 true
bcdedit /set {globalsettings} custom:16000068 true
bcdedit /set nx optout
bcdedit /set bootux disabled
bcdedit /set bootmenupolicy standard
bcdedit /set hypervisorlaunchtype off
bcdedit /set tpmbootentropy ForceDisable
cls
fsutil behavior set memoryusage 2
fsutil behavior set mftzone 4
fsutil behavior set disablelastaccess 1
fsutil behavior set disabledeletenotify 0
fsutil behavior set encryptpagingfile 0
cls
::RegTweaks
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "NonPagedPoolQuota" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagedPoolQuota" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettings" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemPages" /t REG_SZ /d "ffffffff" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBoottrace" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet002\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet002\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" /v "ValueMax" /t REG_DWORD /d "100" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /v "ValueMax" /t REG_DWORD /d "100" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "VsyncIdleTimeout" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "67108864" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d "4294967295" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Priority" /t REG_DWORD /d "6" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Priority" /t REG_DWORD /d "5" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "BackgroundPriority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Priority" /t REG_DWORD /d "4" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d "6" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "BackgroundPriority" /t REG_DWORD /d "4" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Priority" /t REG_DWORD /d "3" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d "1" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Priority" /t REG_DWORD /d "5" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d "6" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "Win32_AutoGameModeDefaultProfile" /t REG_BINARY /d "01000100000000000000000000000000000000000000000000000000000000000000000000000000" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "Win32_GameModeRelatedProcesses" /t REG_BINARY /d "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabledDefault" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "5000" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "4000" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_DWORD /d "4096" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "WaitToKillServiceTimeout" /t REG_DWORD /d "8192" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\943c8cb6-6f93-4227-ad87-e9a3feec08d1" /v "Attributes" /t REG_DWORD /d "2" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "DCSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "DCSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f
cls

::Services Disable
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\UevAgentService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\AsssignedAccessManagerSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PeerDistSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\p2psvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\p2pimsvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PhoneSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\cbdhsvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\MapsBroker" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SmsRouter" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\CscService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SEMgrSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PNRPsvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WpnService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\TabletInputService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PNRPAutoreg" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WbioSrvc" /v "Start" /t reg_DWORD /d "3" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WinRM" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\RetailDemo" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v "Start" /t reg_DWORD /d "2" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\TabletInputService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WinRM" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\edgeupdate" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\edgeupdatem" /v "Start" /t reg_DWORD /d "4" /f
::Windows Update Disable
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX" /v "IsConvergedUpdateStackEnabled" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d "17" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d "8" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightCommitted" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "LastToastAction" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "UxOption" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "InsiderProgramEnabled" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PendingRebootStartTime" /t REG_SZ /d "2019-07-28T03:07:38Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "2019-07-28T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "2019-07-28T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "2099-01-01T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "2099-01-01T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "2099-01-01T10:38:56Z" /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
REG ADD "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ShutdownWithoutLogon" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DontDisplayLastUserName" /t REG_DWORD /d "0" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CaptureService" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ConsentUxUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PimIndexMaintenanceSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DevicePickerUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DevicesFlowUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BcastDVRUserService" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MessagingService" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PrintWorkflowUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\OneSyncSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UserDataSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UnistoreSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DoSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TokenBroker" /v Start /t REG_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MessagingService" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmcompute" /v Start /t reg_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\cbdhsvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wisvc" /v Start /t REG_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\WpnUserService" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SSDPSRV" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\vmms" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\vmicvmsession" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\hidserv" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\LanmanServer" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\LanmanWorkstation" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SSDPSRV" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SysMain" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Themes" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\WSearch" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\PlugPlay" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\DoSvc" /v Start /t reg_DWORD /d 00000004 /f
cls
net accounts /maxpwage:unlimited
powercfg /hibernate off
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
cls
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%a
set /a ram=%mem% + 768000
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients" /f
cls
sc stop BITS
for /f "tokens=3" %%a in ('sc queryex "BITS" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start DsSvc
for /f "tokens=3" %%a in ('sc queryex "DsSvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start Dhcp
for /f "tokens=3" %%a in ('sc queryex "Dhcp" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start DPS 
for /f "tokens=3" %%a in ('sc queryex "DPS" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start Dnscache
for /f "tokens=3" %%a in ('sc queryex "Dnscache" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start WinHttpAutoProxySvc
for /f "tokens=3" %%a in ('sc queryex "WinHttpAutoProxySvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start DcpSvc
for /f "tokens=3" %%a in ('sc queryex "BITS" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "DcpSvc"
sc start WlanSvc
for /f "tokens=3" %%a in ('sc queryex "WlanSvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start LSM
for /f "tokens=3" %%a in ('sc queryex "LSM" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start smphost
for /f "tokens=3" %%a in ('sc queryex "smphost" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start PNRPsvc
for /f "tokens=3" %%a in ('sc queryex "PNRPsvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start SensrSvc
for /f "tokens=3" %%a in ('sc queryex "SensrSvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start Wcmsvc
for /f "tokens=3" %%a in ('sc queryex "Wcmsvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start Wersvc
for /f "tokens=3" %%a in ('sc queryex "Wersvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start Spooler
for /f "tokens=3" %%a in ('sc queryex "Spooler" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start vds
for /f "tokens=3" %%a in ('sc queryex "vds" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
cls
sc config "wsearch" start= disabled
sc stop wsearch
sc config "WerSvc" start= disabled
sc config "DiagTrack" start= disabled
sc config SysMain start= disabled
sc stop SysMain
cls
sc config iphlpsvc start= disabled
sc config SCardSvr start= disabled
sc config WpcMonSvc start= disabled
sc config PimIndexMaintenanceSvc_725a1 start= disabled
sc config diagsvc start= disabled
sc config ExperiÃªncia de Telemetria start= disabled
sc config Fax start= disabled
sc config WdiServiceHost start= disabled
sc config WdiSystemHost start= disabled
sc config seclogon start= disabled
sc config AppVClient start= disabled
sc config Microsoft Update Health Service start= disabled
sc config ssh-agent start= disabled
sc config FDResPub start= disabled
sc config RemoteRegistry start= disabled
sc config RRemoteAccess start= disabled
sc config LanmanServer start= disabled
sc config ServiÃ§o Coletor de PadrÃµes de Hub de DiagnÃ³stico da Microsoft (R) start= disabled
sc config WbioSrvc start= disabled
sc config NetTcpPortSharing start= disabled
sc config WMPNetworkSvc start= disabled
sc config SensrSvc start= disabled
sc config DPS start= disabled
sc config ServiÃ§o de RelatÃ³rios de Erro do Windows start= disabled
sc config dmwappushservice start= disabled
sc config SensorService start= disabled
sc config TabletInputService start= disabled
sc config PhoneSvc start= disabled
sc config UevAgentService start= disabled
sc config WpnUserService_725a1 start= disabled
sc config ServiÃ§o do Participante do Programa Windows Insider start= disabled
sc config shpamsvc start= disabled
sc config SysMain start= disabled
sc config TapiSrv start= disabled
sc config WSearch start= disabled
sc config SCPolicySvc start= disabled
sc config ScDeviceEnum start= disabled
sc config gupdate start= disabled
sc config gupdatem start= disabled
sc config edgeupdate start= disabled
sc config edgeupdatem start= disabled
sc config autotimesvc start= disabled
sc config SensorDataService start= disabled
sc config diagnosticshub.standardcollector.service start= disabled
sc config PhoneSvc start= disabled
sc config TapiSrv start= disabled
sc config Wecsvc start= disabled
sc config SEMgrSvc start= disabled
sc config BDESVC start= disabled
sc config DevQueryBroker start= disabled
cls
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\Uploader"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Uploader" /disable
schtasks /end /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable
schtasks /end /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
schtasks /change /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /disable
schtasks /end /tn "\Microsoft\Windows\Application Experience\StartupAppTask"
schtasks /change /tn "\Microsoft\Windows\Application Experience\StartupAppTask" /disable"
schtasks /end /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /end /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver"
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /disable
cls
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%a
set /a ram=%mem% + 1024000
reg add "hklm\system\currentcontrolset\control" /v "svchostsplitthresholdinkb" /t reg_dword /d "%ram%" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DontDisplayLastUserName" /t REG_DWORD /d "0" /f
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 00000000 /f
cls

echo Disabling AllJoyn Router Service...
sc stop AJRouter
sc config AJRouter start= disabled

echo Disabling AppX Deployment Service (AppXSVC)...
sc stop AppXSvc
sc config AppXSvc start= disabled

echo Disabling Application Layer Gateway Service...
sc stop ALG
sc config ALG start= disabled

echo Disabling Application Management...
sc stop AppMgmt
sc config AppMgmt start= disabled

echo Disabling App Readiness...
sc stop AppReadiness
sc config AppReadiness start= disabled

echo Disabling Auto Time Zone Updater...
sc stop tzautoupdate
sc config tzautoupdate start= disabled

echo Disabling AssignedAccessManager Service...
sc stop AssignedAccessManagerSvc
sc config AssignedAccessManagerSvc start= disabled

echo Disabling Background Intelligent Transfer Service...
sc stop BITS
sc config BITS start= disabled

echo Disabling BitLocker Drive Encryption Service...
sc stop BDESVC
sc config BDESVC start= disabled

echo Disabling Block Level Backup Engine Service...
sc stop wbengine
sc config wbengine start= disabled

echo Disabling BranchCache...
sc stop PeerDistSvc
sc config PeerDistSvc start= disabled

echo Disabling CNG Key Isolation...
sc stop KeyIso
sc config KeyIso start= disabled

echo Disabling Certificate Propagation...
sc stop CertPropSvc
sc config CertPropSvc start= disabled

echo Disabling Client License Service (ClipSVC)...
sc stop ClipSVC
sc config ClipSVC start= disabled

echo Disabling Connected User Experiences and Telemetry...
sc stop DiagTrack
sc config DiagTrack start= disabled

echo Disabling Credential Manager...
sc stop VaultSvc
sc config VaultSvc start= disabled

echo Disabling Connected Devices Platform Service...
sc stop CDPSvc
sc config CDPSvc start= disabled

echo Disabling Data Usage...
sc stop DusmSvc
sc config DusmSvc start= disabled

echo Disabling Delivery Optimization...
sc stop DoSvc
sc config DoSvc start= disabled

echo Disabling Diagnostic Execution Service...
sc stop diagsvc
sc config diagsvc start= disabled

echo Disabling Diagnostic Policy Service...
sc stop DPS
sc config DPS start= disabled

echo Disabling Diagnostic Service Host...
sc stop WdiServiceHost
sc config WdiServiceHost start= disabled

echo Disabling Diagnostic System Host...
sc stop WdiSystemHost
sc config WdiSystemHost start= disabled

echo Disabling Distributed Link Tracking Client...
sc stop TrkWks
sc config TrkWks start= disabled

echo Disabling Distributed Transaction Coordinator...
sc stop MSDTC
sc config MSDTC start= disabled

echo Disabling dmwappushsvc...
sc stop dmwappushservice
sc config dmwappushservice start= disabled

echo Disabling Display Enhancement Service...
sc stop DisplayEnhancementService
sc config DisplayEnhancementService start= disabled

echo Disabling Downloaded Maps Manager...
sc stop MapsBroker
sc config MapsBroker start= disabled

echo Disabling Function Discovery Provider Host...
sc stop fdPHost
sc config fdPHost start= disabled

echo Disabling Function Discovery Resource Publication...
sc stop FDResPub
sc config FDResPub start= disabled

echo Disabling Encrypting File System (EFS)...
sc stop EFS
sc config EFS start= disabled

echo Disabling Enterprise App Management Service...
sc stop EntAppSvc
sc config EntAppSvc start= disabled

echo Disabling File History Service...
sc stop fhsvc
sc config fhsvc start= disabled

echo Disabling Geolocation Service...
sc stop lfsvc
sc config lfsvc start= disabled

echo Disabling GraphicsPerfSvc...
sc stop GraphicsPerfSvc
sc config GraphicsPerfSvc start= disabled

echo Disabling HomeGroup Listener...
sc stop HomeGroupListener
sc config HomeGroupListener start= disabled

echo Disabling HomeGroup Provider...
sc stop HomeGroupProvider
sc config HomeGroupProvider start= disabled

echo Disabling HV Host Service...
sc stop HvHost
sc config HvHost start= disabled

echo Disabling Host Network Service...
sc stop hns
sc config hns start= disabled

echo Disabling Hyper-V Data Exchange Service...
sc stop vmickvpexchange
sc config vmickvpexchange start= disabled

echo Disabling Hyper-V Guest Service Interface...
sc stop vmicguestinterface
sc config vmicguestinterface start= disabled

echo Disabling Hyper-V Guest Shutdown Service...
sc stop vmicshutdown
sc config vmicshutdown start= disabled

echo Disabling Hyper-V Heartbeat Service...
sc stop vmicheartbeat
sc config vmicheartbeat start= disabled

echo Disabling Hyper-V PowerShell Direct Service...
sc stop vmicvmsession
sc config vmicvmsession start= disabled

echo Disabling Hyper-V Remote Desktop Virtualization Service...
sc stop vmicrdv
sc config vmicrdv start= disabled

echo Disabling Hyper-V Time Synchronization Service...
sc stop vmictimesync
sc config vmictimesync start= disabled

echo Disabling Hyper-V Volume Shadow Copy Requestor...
sc stop vmicvss
sc config vmicvss start= disabled

echo Disabling Internet Explorer ETW Collector Service...
sc stop IEEtwCollectorService
sc config IEEtwCollectorService start= disabled

echo Disabling IP Helper...
sc stop iphlpsvc
sc config iphlpsvc start= disabled

echo Disabling IP Translation Configuration Service...
sc stop IpxlatCfgSvc
sc config IpxlatCfgSvc start= disabled

echo Disabling IPsec Policy Agent...
sc stop PolicyAgent
sc config PolicyAgent start= disabled

echo Disabling Infrared monitor service...
sc stop irmon
sc config irmon start= disabled

echo Disabling Internet Connection Sharing (ICS)...
sc stop SharedAccess
sc config SharedAccess start= disabled

echo Disabling Link-Layer Topology Discovery Mapper...
sc stop lltdsvc
sc config lltdsvc start= disabled

echo Disabling Microsoft (R) Diagnostics Hub Standard Collector Service...
sc stop diagnosticshub.standardcollector.service
sc config diagnosticshub.standardcollector.service start= disabled

echo Disabling Microsoft Account Sign-in Assistant...
sc stop wlidsvc
sc config wlidsvc start= disabled

echo Disabling Microsoft App-V Client...
sc stop AppVClient
sc config AppVClient start= disabled

echo Disabling Microsoft Passport...
sc stop NgcSvc
sc config NgcSvc start= disabled

echo Disabling Microsoft Passport Container...
sc stop NgcCtnrSvc
sc config NgcCtnrSvc start= disabled

echo Disabling Microsoft Storage Spaces SMP...
sc stop smphost
sc config smphost start= disabled

echo Disabling Microsoft Store Install Service...
sc stop InstallService
sc config InstallService start= disabled

echo Disabling Microsoft Windows SMS Router Service...
sc stop SmsRouter
sc config SmsRouter start= disabled

echo Disabling Microsoft iSCSI Initiator Service...
sc stop MSiSCSI
sc config MSiSCSI start= disabled

echo Disabling Natural Authentication...
sc stop NaturalAuthentication
sc config NaturalAuthentication start= disabled

echo Disabling Netlogon...
sc stop Netlogon
sc config Netlogon start= disabled

echo Disabling Network Connected Devices Auto-Setup...
sc stop NcdAutoSetup
sc config NcdAutoSetup start= disabled

echo Disabling Network Connection Broker...
sc stop NcbService
sc config NcbService start= disabled

echo Disabling Network Connectivity Assistant...
sc stop NcaSvc
sc config NcaSvc start= disabled

echo Disabling Offline Files...
sc stop CscService
sc config CscService start= disabled

echo Disabling Optimize drives...
sc stop defragsvc
sc config defragsvc start= disabled

echo Disabling Payments and NFC/SE Manager...
sc stop SEMgrSvc
sc config SEMgrSvc start= disabled

echo Disabling Peer Name Resolution Protocol...
sc stop PNRPsvc
sc config PNRPsvc start= disabled

echo Disabling Peer Networking Grouping...
sc stop p2psvc
sc config p2psvc start= disabled

echo Disabling Peer Networking Identity Manager...
sc stop p2pimsvc
sc config p2pimsvc start= disabled

echo Disabling Performance Logs & Alerts...
sc stop pla
sc config pla start= disabled

echo Disabling Phone Service...
sc stop PhoneSvc
sc config PhoneSvc start= disabled

echo Disabling Portable Device Enumerator Service...
sc stop WPDBusEnum
sc config WPDBusEnum start= disabled

echo Disabling Print Spooler...
sc stop Spooler
sc config Spooler start= disabled

echo Disabling Printer Extensions and Notifications...
sc stop PrintNotify
sc config PrintNotify start= disabled

echo Disabling Program Compatibility Assistant Service...
sc stop PcaSvc
sc config PcaSvc start= disabled

echo Disabling Parental Controls...
sc stop WpcMonSvc
sc config WpcMonSvc start= disabled

echo Disabling Quality Windows Audio Video Experience...
sc stop QWAVE
sc config QWAVE start= disabled

echo Disabling Remote Access Auto Connection Manager...
sc stop RasAuto
sc config RasAuto start= disabled

echo Disabling Remote Access Connection Manager...
sc stop RasMan
sc config RasMan start= disabled

echo Disabling Remote Desktop Configuration...
sc stop SessionEnv
sc config SessionEnv start= disabled

echo Disabling Remote Desktop Services...
sc stop TermService
sc config TermService start= disabled

echo Disabling Remote Desktop Services UserMode Port Redirector...
sc stop UmRdpService
sc config UmRdpService start= disabled

echo Disabling Remote Procedure Call (RPC) Locator...
sc stop RpcLocator
sc config RpcLocator start= disabled

echo Disabling Remote Registry...
sc stop RemoteRegistry
sc config RemoteRegistry start= disabled

echo Disabling Retail Demo Service...
sc stop RetailDemo
sc config RetailDemo start= disabled

echo Disabling Routing and Remote Access...
sc stop RemoteAccess
sc config RemoteAccess start= disabled

echo Disabling Radio Management Service...
sc stop RmSvc
sc config RmSvc start= disabled

echo Disabling SNMP Trap...
sc stop SNMPTRAP
sc config SNMPTRAP start= disabled

echo Disabling Secondary Logon...
sc stop seclogon
sc config seclogon start= disabled

echo Disabling Security Center...
sc stop wscsvc
sc config wscsvc start= disabled

echo Disabling Security Accounts Manager...
sc stop SamSs
sc config SamSs start= disabled

echo Disabling Sensor Data Service...
sc stop SensorDataService
sc config SensorDataService start= disabled

echo Disabling Sensor Monitoring Service...
sc stop SensrSvc
sc config SensrSvc start= disabled

echo Disabling Sensor Service...
sc stop SensorService
sc config SensorService start= disabled

echo Disabling Server...
sc stop LanmanServer
sc config LanmanServer start= disabled

echo Disabling Server...
sc stop ssh-agent
sc config ssh-agent start= disabled

echo Disabling Shared PC Account Manager...
sc stop shpamsvc
sc config shpamsvc start= disabled

echo Disabling Shell Hardware Detection...
sc stop ShellHWDetection
sc config ShellHWDetection start= disabled

echo Disabling Smart Card...
sc stop SCardSvr
sc config SCardSvr start= disabled

echo Disabling Smart Card Device Enumeration Service...
sc stop ScDeviceEnum
sc config ScDeviceEnum start= disabled

echo Disabling Smart Card Removal Policy...
sc stop SCPolicySvc
sc config SCPolicySvc start= disabled

echo Disabling Spatial Data Service...
sc stop SharedRealitySvc
sc config SharedRealitySvc start= disabled

echo Disabling Storage Service...
sc stop StorSvc
sc config StorSvc start= disabled

echo Disabling Storage Tiers Management...
sc stop TieringEngineService
sc config TieringEngineService start= disabled

echo Disabling Superfetch (SysMain)...
sc stop SysMain
sc config SysMain start= disabled

echo Disabling System Guard Runtime Monitor Broker...
sc stop SgrmBroker
sc config SgrmBroker start= disabled

echo Disabling Telephony...
sc stop TapiSrv
sc config TapiSrv start= disabled

echo Disabling Themes...
sc stop Themes
sc config Themes start= disabled

echo Disabling Tile Data model server...
sc stop tiledatamodelsvc
sc config tiledatamodelsvc start= disabled

echo Disabling Touch Keyboard and Handwriting Panel Service...
sc stop TabletInputService
sc config TabletInputService start= disabled

echo Disabling Update Orchestrator Service...
sc stop UsoSvc
sc config UsoSvc start= disabled

echo Disabling User Experience Virtualization Service...
sc stop UevAgentService
sc config UevAgentService start= disabled

echo Disabling WalletService...
sc stop WalletService
sc config WalletService start= disabled

echo Disabling WMI Performance Adapter...
sc stop wmiApSrv
sc config wmiApSrv start= disabled

echo Disabling WWAN AutoConfig...
sc stop WwanSvc
sc config WwanSvc start= disabled

echo Disabling Web Account Manager...
sc stop TokenBroker
sc config TokenBroker start= disabled

echo Disabling WebClient...
sc stop WebClient
sc config WebClient start= disabled

echo Disabling Wi-Fi Direct Services Connection Manager Service...
sc stop WFDSConMgrSvc
sc config WFDSConMgrSvc start= disabled

echo Disabling Windows Backup...
sc stop SDRSVC
sc config SDRSVC start= disabled

echo Disabling Windows Biometric Service...
sc stop WbioSrvc
sc config WbioSrvc start= disabled

echo Disabling Windows Camera Frame Server...
sc stop FrameServer
sc config FrameServer start= disabled

echo Disabling Windows Connect Now - Config Registrar...
sc stop wcncsvc
sc config wcncsvc start= disabled

echo Disabling Windows Defender Advanced Threat Protection Service...
sc stop Sense
sc config Sense start= disabled

echo Disabling Windows Defender Antivirus Network Inspection Service...
sc stop WdNisSvc
sc config WdNisSvc start= disabled

echo Disabling Windows Defender Antivirus Service...
sc stop WinDefend
sc config WinDefend start= disabled

echo Disabling Windows Defender Security Center Service...
sc stop SecurityHealthService
sc config SecurityHealthService start= disabled

echo Disabling Windows Encryption Provider Host Service...
sc stop WEPHOSTSVC
sc config WEPHOSTSVC start= disabled

echo Disabling Windows Error Reporting Service...
sc stop WerSvc
sc config WerSvc start= disabled

echo Disabling Windows Event Collector...
sc stop Wecsvc
sc config Wecsvc start= disabled

echo Disabling Windows Font Cache Service...
sc stop FontCache
sc config FontCache start= disabled

echo Disabling Windows Image Acquisition (WIA)...
sc stop StiSvc
sc config StiSvc start= disabled

echo Disabling Windows Insider Service...
sc stop wisvc
sc config wisvc start= disabled

echo Disabling Windows License Manager Service...
sc stop LicenseManager
sc config LicenseManager start= disabled

echo Disabling Windows Mobile Hotspot Service...
sc stop icssvc
sc config icssvc start= disabled

echo Disabling Windows Media Player Network Sharing Service...
sc stop WMPNetworkSvc
sc config WMPNetworkSvc start= disabled

echo Disabling Windows Presentation Foundation Font Cache 3.0.0.0...
sc stop FontCache3.0.0.0
sc config FontCache3.0.0.0 start= disabled

echo Disabling Windows Push Notifications System Service...
sc stop WpnService
sc config WpnService start= disabled

echo Disabling Windows Perception Simulation Service...
sc stop perceptionsimulation
sc config perceptionsimulation start= disabled

echo Disabling Windows Perception Service...
sc stop spectrum
sc config spectrum start= disabled

echo Disabling Windows Remote Management (WS-Management)...
sc stop WinRM
sc config WinRM start= disabled

echo Disabling Windows Search...
sc stop WSearch
sc config WSearch start= disabled

echo Disabling Windows Security Service...
sc stop SecurityHealthService
sc config SecurityHealthService start= disabled

echo Disabling Windows Time...
sc stop W32Time
sc config W32Time start= disabled

echo Disabling Windows Update...
sc stop wuauserv
sc config wuauserv start= disabled

echo Disabling Windows Update Medic Service...
sc stop WaaSMedicSvc
sc config WaaSMedicSvc start= disabled

echo Disabling Workstation...
sc stop LanmanWorkstation
sc config LanmanWorkstation start= disabled

echo Disabling Xbox Accessory Management Service...
sc stop XboxGipSvc
sc config XboxGipSvc start= disabled

echo Disabling Xbox Game Monitoring...
sc stop xbgm
sc config xbgm start= disabled

echo Disabling Xbox Live Auth Manager...
sc stop XblAuthManager
sc config XblAuthManager start= disabled

echo Disabling Xbox Live Game Save...
sc stop XblGameSave
sc config XblGameSave start= disabled

echo Disabling Xbox Live Networking Service...
sc stop XboxNetApiSvc
sc config XboxNetApiSvc start= disabled
cls

powershell -command "Get-AppxPackage *XboxApp* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *Xbox.TCUI* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *XboxGameOverlay* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *XboxGamingOverlay* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *XboxIdentityProvider* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *XboxSpeechToTextOverlay* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *XboxGameCallableUI* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *ZuneMusic* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *ZuneVideo* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *YourPhone* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *MixedReality.Portal* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *BingWeather* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *Getstarted* | Remove-AppxPackage"
powershell -command "Get-AppxPackage *GetHelp* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *WindowsMaps* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *MicrosoftSolitaireCollection* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *People* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *Microsoft3DViewer* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *SkypeApp* | Remove-AppxPackage"

powershell -command "Get-AppxPackage *WindowsCamera* | Remove-AppxPackage"


Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.7z" /ve /t REG_SZ /d "7-Zip.7z" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.7z" /ve /t REG_SZ /d "7z Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.7z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,0" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.7z\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.7z\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.7z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.zip" /ve /t REG_SZ /d "7-Zip.zip" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.zip" /ve /t REG_SZ /d "zip Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.zip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,1" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.zip\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.zip\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.zip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.rar" /ve /t REG_SZ /d "7-Zip.rar" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rar" /ve /t REG_SZ /d "rar Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,3" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rar\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rar\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.001" /ve /t REG_SZ /d "7-Zip.001" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.001" /ve /t REG_SZ /d "001 Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.001\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,9" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.001\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.001\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.001\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.cab" /ve /t REG_SZ /d "7-Zip.cab" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cab" /ve /t REG_SZ /d "cab Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cab\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,7" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cab\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cab\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cab\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.iso" /ve /t REG_SZ /d "7-Zip.iso" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.iso" /ve /t REG_SZ /d "iso Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.iso\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,8" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.iso\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.iso\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.iso\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.xz" /ve /t REG_SZ /d "7-Zip.xz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xz" /ve /t REG_SZ /d "xz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.txz" /ve /t REG_SZ /d "7-Zip.txz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.txz" /ve /t REG_SZ /d "txz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.txz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,23" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.txz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.txz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.txz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.lzma" /ve /t REG_SZ /d "7-Zip.lzma" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzma" /ve /t REG_SZ /d "lzma Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzma\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,16" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzma\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzma\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzma\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.tar" /ve /t REG_SZ /d "7-Zip.tar" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tar" /ve /t REG_SZ /d "tar Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,13" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tar\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tar\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.cpio" /ve /t REG_SZ /d "7-Zip.cpio" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cpio" /ve /t REG_SZ /d "cpio Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cpio\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,12" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cpio\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cpio\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.cpio\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.bz2" /ve /t REG_SZ /d "7-Zip.bz2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bz2" /ve /t REG_SZ /d "bz2 Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bz2\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bz2\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.bzip2" /ve /t REG_SZ /d "7-Zip.bzip2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bzip2" /ve /t REG_SZ /d "bzip2 Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bzip2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bzip2\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bzip2\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.bzip2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.tbz2" /ve /t REG_SZ /d "7-Zip.tbz2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz2" /ve /t REG_SZ /d "tbz2 Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz2\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz2\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz2\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz2\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.tbz" /ve /t REG_SZ /d "7-Zip.tbz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz" /ve /t REG_SZ /d "tbz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,2" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tbz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.gz" /ve /t REG_SZ /d "7-Zip.gz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gz" /ve /t REG_SZ /d "gz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.gzip" /ve /t REG_SZ /d "7-Zip.gzip" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gzip" /ve /t REG_SZ /d "gzip Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gzip\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gzip\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gzip\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.gzip\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.tgz" /ve /t REG_SZ /d "7-Zip.tgz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tgz" /ve /t REG_SZ /d "tgz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tgz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tgz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tgz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tgz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.tpz" /ve /t REG_SZ /d "7-Zip.tpz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tpz" /ve /t REG_SZ /d "tpz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tpz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,14" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tpz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tpz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.tpz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.z" /ve /t REG_SZ /d "7-Zip.z" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.z" /ve /t REG_SZ /d "z Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.z\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.z\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.z\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.z\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.taz" /ve /t REG_SZ /d "7-Zip.taz" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.taz" /ve /t REG_SZ /d "taz Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.taz\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,5" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.taz\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.taz\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.taz\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.lzh" /ve /t REG_SZ /d "7-Zip.lzh" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzh" /ve /t REG_SZ /d "lzh Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzh\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzh\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzh\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lzh\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.lha" /ve /t REG_SZ /d "7-Zip.lha" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lha" /ve /t REG_SZ /d "lha Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lha\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,6" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lha\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lha\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.lha\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.rpm" /ve /t REG_SZ /d "7-Zip.rpm" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rpm" /ve /t REG_SZ /d "rpm Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rpm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,10" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rpm\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rpm\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.rpm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.deb" /ve /t REG_SZ /d "7-Zip.deb" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.deb" /ve /t REG_SZ /d "deb Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.deb\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,11" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.deb\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.deb\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.deb\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.arj" /ve /t REG_SZ /d "7-Zip.arj" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.arj" /ve /t REG_SZ /d "arj Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.arj\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,4" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.arj\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.arj\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.arj\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.vhd" /ve /t REG_SZ /d "7-Zip.vhd" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.vhd" /ve /t REG_SZ /d "vhd Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.vhd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,20" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.vhd\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.vhd\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.vhd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.wim" /ve /t REG_SZ /d "7-Zip.wim" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.wim" /ve /t REG_SZ /d "wim Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.wim\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.wim\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.wim\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.wim\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.swm" /ve /t REG_SZ /d "7-Zip.swm" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.swm" /ve /t REG_SZ /d "swm Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.swm\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.swm\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.swm\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.swm\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.esd" /ve /t REG_SZ /d "7-Zip.esd" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.esd" /ve /t REG_SZ /d "esd Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.esd\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,15" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.esd\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.esd\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.esd\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.fat" /ve /t REG_SZ /d "7-Zip.fat" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.fat" /ve /t REG_SZ /d "fat Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.fat\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,21" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.fat\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.fat\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.fat\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.ntfs" /ve /t REG_SZ /d "7-Zip.ntfs" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.ntfs" /ve /t REG_SZ /d "ntfs Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.ntfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,22" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.ntfs\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.ntfs\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.ntfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.dmg" /ve /t REG_SZ /d "7-Zip.dmg" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.dmg" /ve /t REG_SZ /d "dmg Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.dmg\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,17" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.dmg\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.dmg\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.dmg\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.hfs" /ve /t REG_SZ /d "7-Zip.hfs" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.hfs" /ve /t REG_SZ /d "hfs Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.hfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,18" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.hfs\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.hfs\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.hfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.xar" /ve /t REG_SZ /d "7-Zip.xar" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xar" /ve /t REG_SZ /d "xar Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xar\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,19" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xar\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xar\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.xar\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\.squashfs" /ve /t REG_SZ /d "7-Zip.squashfs" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.squashfs" /ve /t REG_SZ /d "squashfs Archive" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.squashfs\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files\7-Zip\7z.dll,24" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.squashfs\shell" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.squashfs\shell\open" /ve /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Classes\7-Zip.squashfs\shell\open\command" /ve /t REG_SZ /d "\"C:\Program Files\7-Zip\7zFM.exe\" \"%%1\"" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "GlobalAssocChangedCounter" /t REG_DWORD /d "46" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\7-Zip\Options" /v "MenuIcons" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\7-Zip\Options" /v "ElimDupExtract" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\7-Zip\Options" /v "ContextMenu" /t REG_DWORD /d "516" /f

Windows Registry Editor Version 5.00

*Memory Management Optimization*

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"ClearPageFileAtShutdown"=dword:00000000
"DisablePagingExecutive"=dword:00000001
"NonPagedPoolQuota"=dword:00000000
"NonPagedPoolSize"=dword:00000000
"PagedPoolQuota"=dword:00000000
"PagedPoolSize"=dword:000000c0
"SecondLevelDataCache"=dword:00000400
"SessionPoolSize"=dword:000000c0
"SessionViewSize"=dword:000000c0
"SystemPages"=dword:ffffffff
"PhysicalAddressExtension"=dword:00000001
"FeatureSettings"=dword:00000001
"FeatureSettingsOverride"=dword:00000003
"FeatureSettingsOverrideMask"=dword:00000003
"IoPageLockLimit"=dword:00fefc00
"PoolUsageMaximum"=dword:00000060

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters]
"EnablePrefetcher"=dword:00000000
"EnableSuperfetch"=dword:00000000
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\fhsvc]
"Start"=dword:00000004

Windows Registry Editor Version 5.00

; Disable all notifications
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer]
"NoToastApplicationNotification"=dword:00000001
"NoToastApplicationNotificationOnLockScreen"=dword:00000001
"NoToastApplicationNotificationOverlays"=dword:00000001
"DisableNotificationCenter"=dword:00000001

Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate]
"DisableWindowsUpdateAccess"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU]
"NoAutoUpdate"=dword:00000001
"AUOptions"=dword:00000002
"ScheduledInstallDay"=dword:00000000
"ScheduledInstallTime"=dword:00000003

Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"LargeSystemCache"=dword:000001

Reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "AltTabSettings" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_DWORD /d "10" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "DelayBeforeAcceptance" /t REG_SZ /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "AutoRepeatDelay" /t REG_SZ /d "500" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "AutoRepeatRate" /t REG_SZ /d "33" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "BounceTime" /t REG_SZ /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "Favorites" /t REG_BINARY /d "00a40100003a001f80c827341f105c1042aa032ee45287d668260001002600efbe12000000af90a1a727ddd801e62ef4d827ddd801aaa809d927ddd801140056003100000000004b55b62111005461736b42617200400009000400efbe4b55b6214b55b6212e0000001070010000000100000000000000000000000000000056e30f015400610073006b00420061007200000016001201320097010000874f0749200046494c4545587e312e4c4e4b00007c0009000400efbe4b55b6214b55b6212e00000017700100000001000000000000000000520000000000589c4400460069006c00650020004500780070006c006f007200650072002e006c006e006b00000040007300680065006c006c00330032002e0064006c006c002c002d003200320030003600370000001c00120000002b00efbed4060cd927ddd8011c00420000001d00efbe02004d006900630072006f0073006f00660074002e00570069006e0064006f00770073002e004500780070006c006f0072006500720000001c00260000001e00efbe0200530079007300740065006d00500069006e006e006500640000001c000000ff" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "EulaAccepted" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "AlwaysOntop" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "Windowplacement" /t REG_BINARY /d "2c0000000200000003000000ffffffffffffffffffffffffffffffff75030000110000009506000069020000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "FindWindowplacement" /t REG_BINARY /d "2c00000000000000000000000000000000000000000000000000000096000000960000000000000000000000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "SysinfoWindowplacement" /t REG_BINARY /d "2c00000000000000010000000000000000000000ffffffffffffffff28000000280000002b0300002b020000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "PropWindowplacement" /t REG_BINARY /d "2c00000000000000000000000000000000000000000000000000000028000000280000000000000000000000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DllPropWindowplacement" /t REG_BINARY /d "2c00000000000000010000000000000000000000ffffffffffffffff2800000028000000e70100009f020000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "UnicodeFont" /t REG_BINARY /d "080000000000000000000000000000009001000000000000000000004d00530020005300680065006c006c00200044006c00670000000000000000000000000000000000000000000000000000000000000000000000000000000000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "Divider" /t REG_BINARY /d "531f0e151662ea3f" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "SavedDivider" /t REG_BINARY /d "531f0e151662ea3f" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ProcessImageColumnWidth" /t REG_DWORD /d "261" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowUnnamedHandles" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowDllView" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HandleSortColumn" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HandleSortDirection" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DllSortColumn" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DllSortDirection" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ProcessSortColumn" /t REG_DWORD /d "4294967295" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ProcessSortDirection" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightServices" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightOwnProcesses" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightRelocatedDlls" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightJobs" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightNewProc" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightDelProc" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightImmersive" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightProtected" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightPacked" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightNetProcess" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightSuspend" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HighlightDuration" /t REG_DWORD /d "1000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowCpuFractions" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowLowerpane" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowAllUsers" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowProcessTree" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "SymbolWarningShown" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HideWhenMinimized" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "AlwaysOntop" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "OneInstance" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "NumColumnSets" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ConfirmKill" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "RefreshRate" /t REG_DWORD /d "5000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "PrcessColumnCount" /t REG_DWORD /d "18" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DllColumnCount" /t REG_DWORD /d "5" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "HandleColumnCount" /t REG_DWORD /d "2" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DefaultProcPropPage" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DefaultSysInfoPage" /t REG_DWORD /d "4" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DefaultDllPropPage" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "DbgHelpPath" /t REG_SZ /d "C:\Windows\SYSTEM32\dbghelp.dll" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "SymbolPath" /t REG_SZ /d "" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorPacked" /t REG_DWORD /d "16711808" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorImmersive" /t REG_DWORD /d "15395328" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorOwn" /t REG_DWORD /d "16765136" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorServices" /t REG_DWORD /d "13684991" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorRelocatedDlls" /t REG_DWORD /d "10551295" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorGraphBk" /t REG_DWORD /d "15790320" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorJobs" /t REG_DWORD /d "27856" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorDelProc" /t REG_DWORD /d "4605695" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorNewProc" /t REG_DWORD /d "4652870" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorNet" /t REG_DWORD /d "10551295" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorProtected" /t REG_DWORD /d "8388863" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowHeatmaps" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ColorSuspend" /t REG_DWORD /d "8421504" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "StatusBarColumns" /t REG_DWORD /d "13589" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowAllCpus" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowAllGpus" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "Opacity" /t REG_DWORD /d "100" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "GpuNodeUsageMask" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "GpuNodeUsageMask1" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "VerifySignatures" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "VirusTotalCheck" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "VirusTotalSubmitUnknown" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ToolbarBands" /t REG_BINARY /d "0601000000000000000000004b00000001000000000000004b00000002000000000000004b00000003000000000000004b0000000400000000000000400000000500000000000000500000000600000000000000930400000700000000000000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "UseGoogle" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowNewProcesses" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "TrayCPUHistory" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowIoTray" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowNetTray" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowDiskTray" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowPhysTray" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowCommitTray" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ShowGpuTray" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "FormatIoBytes" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "StackWindowPlacement" /t REG_BINARY /d "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer" /v "ETWstandardUserWarning" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumnMap" /v "0" /t REG_DWORD /d "26" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumnMap" /v "1" /t REG_DWORD /d "42" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumnMap" /v "2" /t REG_DWORD /d "1033" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumnMap" /v "3" /t REG_DWORD /d "1111" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumnMap" /v "4" /t REG_DWORD /d "1670" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumns" /v "0" /t REG_DWORD /d "110" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumns" /v "1" /t REG_DWORD /d "180" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumns" /v "2" /t REG_DWORD /d "140" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumns" /v "3" /t REG_DWORD /d "300" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\DllColumns" /v "4" /t REG_DWORD /d "100" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\HandleColumnMap" /v "0" /t REG_DWORD /d "21" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\HandleColumnMap" /v "1" /t REG_DWORD /d "22" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\HandleColumns" /v "0" /t REG_DWORD /d "100" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\HandleColumns" /v "1" /t REG_DWORD /d "450" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "0" /t REG_DWORD /d "3" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "1" /t REG_DWORD /d "1055" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "2" /t REG_DWORD /d "1650" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "3" /t REG_DWORD /d "1200" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "4" /t REG_DWORD /d "1092" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "5" /t REG_DWORD /d "1333" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "6" /t REG_DWORD /d "1622" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "7" /t REG_DWORD /d "1636" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "8" /t REG_DWORD /d "1179" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "9" /t REG_DWORD /d "1340" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "10" /t REG_DWORD /d "5" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "11" /t REG_DWORD /d "1339" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "12" /t REG_DWORD /d "1060" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "13" /t REG_DWORD /d "1063" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "14" /t REG_DWORD /d "4" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "15" /t REG_DWORD /d "1065" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "16" /t REG_DWORD /d "18" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "17" /t REG_DWORD /d "1670" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "18" /t REG_DWORD /d "1653" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumnMap" /v "19" /t REG_DWORD /d "1653" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "0" /t REG_DWORD /d "261" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "1" /t REG_DWORD /d "35" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "2" /t REG_DWORD /d "37" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "3" /t REG_DWORD /d "82" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "4" /t REG_DWORD /d "81" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "5" /t REG_DWORD /d "65" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "6" /t REG_DWORD /d "93" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "7" /t REG_DWORD /d "76" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "8" /t REG_DWORD /d "55" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "9" /t REG_DWORD /d "60" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "10" /t REG_DWORD /d "39" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "11" /t REG_DWORD /d "80" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "12" /t REG_DWORD /d "70" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "13" /t REG_DWORD /d "70" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "14" /t REG_DWORD /d "31" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "15" /t REG_DWORD /d "52" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "16" /t REG_DWORD /d "52" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\ProcessColumns" /v "17" /t REG_DWORD /d "44" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000326Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "PreventOverride" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v "ShowedToastAtLevel" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarOpenOnHover" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" /v "RomeSdkChannelUserAuthzPolicy" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\EnableWebContentEvaluation" /v "Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" /v "Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f
Reg.exe add "HKEY_CURRENT_USER\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "58" /f
Reg.exe add "HKEY_CURRENT_USER\SOFTWARE\Sysinternals\Process Explorer\VirusTotal" /v "VirusTotalTermsAccepted" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" /v "Value" /t REG_SZ /d "Allow" /f


net stop "SysMain"
net stop "DiagTrack"
net stop "WSearch"
net stop "WerSvc"
net stop "dmwappushservice"
net stop "Fax"
net stop "TermService"
net stop "wlidsvc"
net stop "MapsBroker"
net stop "RetailDemo"
net stop "PhoneSvc"
net stop "WMPNetworkSvc"
net stop "TrkWks"
net stop "RemoteRegistry"
net stop "WbioSrvc"
net stop "TabletInputService"
net stop "iphlpsvc"
net stop "SharedAccess"
net stop "PrintSpooler"
net stop "BthAvctpSvc"


::Tweaks
bcdedit /set linearaddress57 OptOut
bcdedit /set increaseuserva 268435328
bcdedit /set firstmegabytepolicy UseAll
bcdedit /set avoidlowmemory 0x8000000
bcdedit /set nolowmem Yes
bcdedit /set allowedinmemorysettings 0x0
bcdedit /set isolatedcontext No
bcdedit /set vsmlaunchtype Off
bcdedit /set vm No
bcdedit /set configaccesspolicy Default
bcdedit /set MSI Default
bcdedit /set usephysicaldestination No
bcdedit /set usefirmwarepcisettings No
bcdedit /set allowedinmemorysettings 0
bcdedit /deletevalue useplatformclock
bcdedit /set useplatformtick Yes
bcdedit /set tscsyncpolicy Enhanced
bcdedit /set debug No
bcdedit /set pae ForceEnable
bcdedit /set bootmenupolicy Legacy
bcdedit /set sos Yes
bcdedit /set disabledynamictick Yes
bcdedit /set disableelamdrivers Yes
bcdedit /set quietboot Yes
bcdedit /set ems No
bcdedit /set linearaddress57 optin
bcdedit /set noumex Yes
bcdedit /set bootems No
bcdedit /set graphicsmodedisabled No
bcdedit /set extendedinput Yes
bcdedit /set highestmode Yes
bcdedit /set forcefipscrypto No
bcdedit /set perfmem 0
bcdedit /set configflags 0
bcdedit /set uselegacyapicmode No
bcdedit /set onecpu No
bcdedit /set halbreakpoint No
bcdedit /set forcelegacyplatform No
bcdedit /set useplatformclock no
bcdedit /set useplatformtick yes
bcdedit /set firstmegabytepolicy UseAll 
bcdedit /set forcefipscrypto No
bcdedit /set nx AlwaysOff
bcdedit /timeout 2
bcdedit /set {globalsettings} custom:16000067 true
bcdedit /set {globalsettings} custom:16000069 true
bcdedit /set {globalsettings} custom:16000068 true
bcdedit /set nx optout
bcdedit /set bootux disabled
bcdedit /set bootmenupolicy standard
bcdedit /set hypervisorlaunchtype off
bcdedit /set tpmbootentropy ForceDisable
cls
fsutil behavior set memoryusage 2
fsutil behavior set mftzone 4
fsutil behavior set disablelastaccess 1
fsutil behavior set disabledeletenotify 0
fsutil behavior set encryptpagingfile 0
cls
::RegTweaks
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "NonPagedPoolQuota" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagedPoolQuota" /t REG_DWORD /d "0" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettings" /t REG_DWORD /d "1" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f
Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemPages" /t REG_SZ /d "ffffffff" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBoottrace" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet002\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMax" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\ControlSet002\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v "ValueMin" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" /v "ValueMax" /t REG_DWORD /d "100" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /v "ValueMax" /t REG_DWORD /d "100" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "VsyncIdleTimeout" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "67108864" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d "4294967295" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Priority" /t REG_DWORD /d "6" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Priority" /t REG_DWORD /d "5" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Capture" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "BackgroundPriority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Priority" /t REG_DWORD /d "4" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Distribution" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d "6" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "BackgroundPriority" /t REG_DWORD /d "4" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Priority" /t REG_DWORD /d "3" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Playback" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d "1" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Background Only" /t REG_SZ /d "True" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Priority" /t REG_DWORD /d "5" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "SFIO Priority" /t REG_SZ /d "Normal" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d "10000" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d "8" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d "6" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
Reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "Win32_AutoGameModeDefaultProfile" /t REG_BINARY /d "01000100000000000000000000000000000000000000000000000000000000000000000000000000" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "Win32_GameModeRelatedProcesses" /t REG_BINARY /d "010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "HibernateEnabledDefault" /t REG_DWORD /d "0" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "5000" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "4000" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_DWORD /d "4096" /f
Reg.exe add "HKCU\Control Panel\Desktop" /v "WaitToKillServiceTimeout" /t REG_DWORD /d "8192" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\943c8cb6-6f93-4227-ad87-e9a3feec08d1" /v "Attributes" /t REG_DWORD /d "2" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "DCSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" /v "DCSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /v "ACSettingIndex" /t REG_DWORD /d "0" /f
Reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d "1" /f
cls
::Services Disable
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\UevAgentService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\AsssignedAccessManagerSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PeerDistSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\p2psvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\p2pimsvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PhoneSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\cbdhsvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\MapsBroker" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SmsRouter" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\CscService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SEMgrSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PNRPsvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WpnService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\TabletInputService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\PNRPAutoreg" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WbioSrvc" /v "Start" /t reg_DWORD /d "3" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WinRM" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\RetailDemo" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v "Start" /t reg_DWORD /d "2" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SENS" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\TabletInputService" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\WinRM" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\edgeupdate" /v "Start" /t reg_DWORD /d "4" /f
reg ADD "HKLM\SYSTEM\CurrentControlSet\Services\edgeupdatem" /v "Start" /t reg_DWORD /d "4" /f
::Windows Update Disable
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX" /v "IsConvergedUpdateStackEnabled" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursEnd" /t REG_DWORD /d "17" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ActiveHoursStart" /t REG_DWORD /d "8" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightCommitted" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "LastToastAction" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "UxOption" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "InsiderProgramEnabled" /t REG_DWORD /d "0" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PendingRebootStartTime" /t REG_SZ /d "2019-07-28T03:07:38Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "2019-07-28T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "2019-07-28T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "2099-01-01T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "2099-01-01T10:38:56Z" /f
REG ADD "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "2099-01-01T10:38:56Z" /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
REG ADD "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ShutdownWithoutLogon" /t REG_DWORD /d "1" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DontDisplayLastUserName" /t REG_DWORD /d "0" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CaptureService" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ConsentUxUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PimIndexMaintenanceSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DevicePickerUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DevicesFlowUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BcastDVRUserService" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MessagingService" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PrintWorkflowUserSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\OneSyncSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UserDataSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UnistoreSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DoSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TokenBroker" /v Start /t REG_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MessagingService" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmcompute" /v Start /t reg_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\cbdhsvc" /v Start /t REG_DWORD /d 00000004 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wisvc" /v Start /t REG_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\WpnUserService" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SSDPSRV" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\vmms" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\vmicvmsession" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\hidserv" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\LanmanServer" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\LanmanWorkstation" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SSDPSRV" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SysMain" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Themes" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\WSearch" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\PlugPlay" /v Start /t reg_DWORD /d 00000004 /f
REG add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\DoSvc" /v Start /t reg_DWORD /d 00000004 /f
cls

for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%a
set /a ram=%mem% + 768000
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients" /f
cls
sc stop BITS
for /f "tokens=3" %%a in ('sc queryex "BITS" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start DsSvc
for /f "tokens=3" %%a in ('sc queryex "DsSvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start Dhcp
for /f "tokens=3" %%a in ('sc queryex "Dhcp" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start DPS 
for /f "tokens=3" %%a in ('sc queryex "DPS" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start Dnscache
for /f "tokens=3" %%a in ('sc queryex "Dnscache" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start WinHttpAutoProxySvc
for /f "tokens=3" %%a in ('sc queryex "WinHttpAutoProxySvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start DcpSvc
for /f "tokens=3" %%a in ('sc queryex "BITS" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "DcpSvc"
sc start WlanSvc
for /f "tokens=3" %%a in ('sc queryex "WlanSvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start LSM
for /f "tokens=3" %%a in ('sc queryex "LSM" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start smphost
for /f "tokens=3" %%a in ('sc queryex "smphost" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start PNRPsvc
for /f "tokens=3" %%a in ('sc queryex "PNRPsvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start SensrSvc
for /f "tokens=3" %%a in ('sc queryex "SensrSvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start Wcmsvc
for /f "tokens=3" %%a in ('sc queryex "Wcmsvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start Wersvc
for /f "tokens=3" %%a in ('sc queryex "Wersvc" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "low"
sc start Spooler
for /f "tokens=3" %%a in ('sc queryex "Spooler" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
sc start vds
for /f "tokens=3" %%a in ('sc queryex "vds" ^| findstr "PID"') do (set pid=%%a)
wmic process where ProcessId=%pid% CALL setpriority "realtime"
cls
sc config "wsearch" start= disabled
sc stop wsearch
sc config "WerSvc" start= disabled
sc config "DiagTrack" start= disabled
sc config SysMain start= disabled
sc stop SysMain
cls
sc config iphlpsvc start= disabled
sc config SCardSvr start= disabled
sc config WpcMonSvc start= disabled
sc config PimIndexMaintenanceSvc_725a1 start= disabled
sc config diagsvc start= disabled
sc config ExperiÃªncia de Telemetria start= disabled
sc config Fax start= disabled
sc config WdiServiceHost start= disabled
sc config WdiSystemHost start= disabled
sc config seclogon start= disabled
sc config AppVClient start= disabled
sc config Microsoft Update Health Service start= disabled
sc config ssh-agent start= disabled
sc config FDResPub start= disabled
sc config RemoteRegistry start= disabled
sc config RRemoteAccess start= disabled
sc config LanmanServer start= disabled
sc config ServiÃ§o Coletor de PadrÃµes de Hub de DiagnÃ³stico da Microsoft (R) start= disabled
sc config WbioSrvc start= disabled
sc config NetTcpPortSharing start= disabled
sc config WMPNetworkSvc start= disabled
sc config SensrSvc start= disabled
sc config DPS start= disabled
sc config ServiÃ§o de RelatÃ³rios de Erro do Windows start= disabled
sc config dmwappushservice start= disabled
sc config SensorService start= disabled
sc config TabletInputService start= disabled
sc config PhoneSvc start= disabled
sc config UevAgentService start= disabled
sc config WpnUserService_725a1 start= disabled
sc config ServiÃ§o do Participante do Programa Windows Insider start= disabled
sc config shpamsvc start= disabled
sc config SysMain start= disabled
sc config TapiSrv start= disabled
sc config WSearch start= disabled
sc config SCPolicySvc start= disabled
sc config ScDeviceEnum start= disabled
sc config gupdate start= disabled
sc config gupdatem start= disabled
sc config edgeupdate start= disabled
sc config edgeupdatem start= disabled
sc config autotimesvc start= disabled
sc config SensorDataService start= disabled
sc config diagnosticshub.standardcollector.service start= disabled
sc config PhoneSvc start= disabled
sc config TapiSrv start= disabled
sc config Wecsvc start= disabled
sc config SEMgrSvc start= disabled
sc config BDESVC start= disabled
sc config DevQueryBroker start= disabled
cls
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable
schtasks /end /tn "\Microsoft\Windows\Customer Experience Improvement Program\Uploader"
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Uploader" /disable
schtasks /end /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable
schtasks /end /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
schtasks /change /tn "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /disable
schtasks /end /tn "\Microsoft\Windows\Application Experience\StartupAppTask"
schtasks /change /tn "\Microsoft\Windows\Application Experience\StartupAppTask" /disable"
schtasks /end /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /end /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver"
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" /disable
cls
for /f "tokens=2 delims==" %%a in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%a
set /a ram=%mem% + 1024000
reg add "hklm\system\currentcontrolset\control" /v "svchostsplitthresholdinkb" /t reg_dword /d "%ram%" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DontDisplayLastUserName" /t REG_DWORD /d "0" /f
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 00000000 /f
cls

echo Disabling AllJoyn Router Service...
sc stop AJRouter
sc config AJRouter start= disabled

echo Disabling AppX Deployment Service (AppXSVC)...
sc stop AppXSvc
sc config AppXSvc start= disabled

echo Disabling Application Layer Gateway Service...
sc stop ALG
sc config ALG start= disabled

echo Disabling Application Management...
sc stop AppMgmt
sc config AppMgmt start= disabled

echo Disabling App Readiness...
sc stop AppReadiness
sc config AppReadiness start= disabled

echo Disabling Auto Time Zone Updater...
sc stop tzautoupdate
sc config tzautoupdate start= disabled

echo Disabling AssignedAccessManager Service...
sc stop AssignedAccessManagerSvc
sc config AssignedAccessManagerSvc start= disabled

echo Disabling Background Intelligent Transfer Service...
sc stop BITS
sc config BITS start= disabled

echo Disabling BitLocker Drive Encryption Service...
sc stop BDESVC
sc config BDESVC start= disabled

echo Disabling Block Level Backup Engine Service...
sc stop wbengine
sc config wbengine start= disabled

echo Disabling BranchCache...
sc stop PeerDistSvc
sc config PeerDistSvc start= disabled

echo Disabling CNG Key Isolation...
sc stop KeyIso
sc config KeyIso start= disabled

echo Disabling Certificate Propagation...
sc stop CertPropSvc
sc config CertPropSvc start= disabled

echo Disabling Client License Service (ClipSVC)...
sc stop ClipSVC
sc config ClipSVC start= disabled

echo Disabling Connected User Experiences and Telemetry...
sc stop DiagTrack
sc config DiagTrack start= disabled

echo Disabling Credential Manager...
sc stop VaultSvc
sc config VaultSvc start= disabled

echo Disabling Connected Devices Platform Service...
sc stop CDPSvc
sc config CDPSvc start= disabled

echo Disabling Data Usage...
sc stop DusmSvc
sc config DusmSvc start= disabled

echo Disabling Delivery Optimization...
sc stop DoSvc
sc config DoSvc start= disabled

echo Disabling Diagnostic Execution Service...
sc stop diagsvc
sc config diagsvc start= disabled

echo Disabling Diagnostic Policy Service...
sc stop DPS
sc config DPS start= disabled

echo Disabling Diagnostic Service Host...
sc stop WdiServiceHost
sc config WdiServiceHost start= disabled

echo Disabling Diagnostic System Host...
sc stop WdiSystemHost
sc config WdiSystemHost start= disabled

echo Disabling Distributed Link Tracking Client...
sc stop TrkWks
sc config TrkWks start= disabled

echo Disabling Distributed Transaction Coordinator...
sc stop MSDTC
sc config MSDTC start= disabled

echo Disabling dmwappushsvc...
sc stop dmwappushservice
sc config dmwappushservice start= disabled

echo Disabling Display Enhancement Service...
sc stop DisplayEnhancementService
sc config DisplayEnhancementService start= disabled

echo Disabling Downloaded Maps Manager...
sc stop MapsBroker
sc config MapsBroker start= disabled

echo Disabling Function Discovery Provider Host...
sc stop fdPHost
sc config fdPHost start= disabled

echo Disabling Function Discovery Resource Publication...
sc stop FDResPub
sc config FDResPub start= disabled

echo Disabling Encrypting File System (EFS)...
sc stop EFS
sc config EFS start= disabled

echo Disabling Enterprise App Management Service...
sc stop EntAppSvc
sc config EntAppSvc start= disabled

echo Disabling File History Service...
sc stop fhsvc
sc config fhsvc start= disabled

echo Disabling Geolocation Service...
sc stop lfsvc
sc config lfsvc start= disabled

echo Disabling GraphicsPerfSvc...
sc stop GraphicsPerfSvc
sc config GraphicsPerfSvc start= disabled

echo Disabling HomeGroup Listener...
sc stop HomeGroupListener
sc config HomeGroupListener start= disabled

echo Disabling HomeGroup Provider...
sc stop HomeGroupProvider
sc config HomeGroupProvider start= disabled

echo Disabling HV Host Service...
sc stop HvHost
sc config HvHost start= disabled

echo Disabling Host Network Service...
sc stop hns
sc config hns start= disabled

echo Disabling Hyper-V Data Exchange Service...
sc stop vmickvpexchange
sc config vmickvpexchange start= disabled

echo Disabling Hyper-V Guest Service Interface...
sc stop vmicguestinterface
sc config vmicguestinterface start= disabled

echo Disabling Hyper-V Guest Shutdown Service...
sc stop vmicshutdown
sc config vmicshutdown start= disabled

echo Disabling Hyper-V Heartbeat Service...
sc stop vmicheartbeat
sc config vmicheartbeat start= disabled

echo Disabling Hyper-V PowerShell Direct Service...
sc stop vmicvmsession
sc config vmicvmsession start= disabled

echo Disabling Hyper-V Remote Desktop Virtualization Service...
sc stop vmicrdv
sc config vmicrdv start= disabled

echo Disabling Hyper-V Time Synchronization Service...
sc stop vmictimesync
sc config vmictimesync start= disabled

echo Disabling Hyper-V Volume Shadow Copy Requestor...
sc stop vmicvss
sc config vmicvss start= disabled

echo Disabling Internet Explorer ETW Collector Service...
sc stop IEEtwCollectorService
sc config IEEtwCollectorService start= disabled

echo Disabling IP Helper...
sc stop iphlpsvc
sc config iphlpsvc start= disabled

echo Disabling IP Translation Configuration Service...
sc stop IpxlatCfgSvc
sc config IpxlatCfgSvc start= disabled

echo Disabling IPsec Policy Agent...
sc stop PolicyAgent
sc config PolicyAgent start= disabled

echo Disabling Infrared monitor service...
sc stop irmon
sc config irmon start= disabled

echo Disabling Internet Connection Sharing (ICS)...
sc stop SharedAccess
sc config SharedAccess start= disabled

echo Disabling Link-Layer Topology Discovery Mapper...
sc stop lltdsvc
sc config lltdsvc start= disabled

echo Disabling Microsoft (R) Diagnostics Hub Standard Collector Service...
sc stop diagnosticshub.standardcollector.service
sc config diagnosticshub.standardcollector.service start= disabled

echo Disabling Microsoft Account Sign-in Assistant...
sc stop wlidsvc
sc config wlidsvc start= disabled

echo Disabling Microsoft App-V Client...
sc stop AppVClient
sc config AppVClient start= disabled

echo Disabling Microsoft Passport...
sc stop NgcSvc
sc config NgcSvc start= disabled

echo Disabling Microsoft Passport Container...
sc stop NgcCtnrSvc
sc config NgcCtnrSvc start= disabled

echo Disabling Microsoft Storage Spaces SMP...
sc stop smphost
sc config smphost start= disabled

echo Disabling Microsoft Store Install Service...
sc stop InstallService
sc config InstallService start= disabled

echo Disabling Microsoft Windows SMS Router Service...
sc stop SmsRouter
sc config SmsRouter start= disabled

echo Disabling Microsoft iSCSI Initiator Service...
sc stop MSiSCSI
sc config MSiSCSI start= disabled

echo Disabling Natural Authentication...
sc stop NaturalAuthentication
sc config NaturalAuthentication start= disabled

echo Disabling Netlogon...
sc stop Netlogon
sc config Netlogon start= disabled

echo Disabling Network Connected Devices Auto-Setup...
sc stop NcdAutoSetup
sc config NcdAutoSetup start= disabled

echo Disabling Network Connection Broker...
sc stop NcbService
sc config NcbService start= disabled

echo Disabling Network Connectivity Assistant...
sc stop NcaSvc
sc config NcaSvc start= disabled

echo Disabling Offline Files...
sc stop CscService
sc config CscService start= disabled

echo Disabling Optimize drives...
sc stop defragsvc
sc config defragsvc start= disabled

echo Disabling Payments and NFC/SE Manager...
sc stop SEMgrSvc
sc config SEMgrSvc start= disabled

echo Disabling Peer Name Resolution Protocol...
sc stop PNRPsvc
sc config PNRPsvc start= disabled

echo Disabling Peer Networking Grouping...
sc stop p2psvc
sc config p2psvc start= disabled

echo Disabling Peer Networking Identity Manager...
sc stop p2pimsvc
sc config p2pimsvc start= disabled

echo Disabling Performance Logs & Alerts...
sc stop pla
sc config pla start= disabled

echo Disabling Phone Service...
sc stop PhoneSvc
sc config PhoneSvc start= disabled

echo Disabling Portable Device Enumerator Service...
sc stop WPDBusEnum
sc config WPDBusEnum start= disabled

echo Disabling Print Spooler...
sc stop Spooler
sc config Spooler start= disabled

echo Disabling Printer Extensions and Notifications...
sc stop PrintNotify
sc config PrintNotify start= disabled

echo Disabling Program Compatibility Assistant Service...
sc stop PcaSvc
sc config PcaSvc start= disabled

echo Disabling Parental Controls...
sc stop WpcMonSvc
sc config WpcMonSvc start= disabled

echo Disabling Quality Windows Audio Video Experience...
sc stop QWAVE
sc config QWAVE start= disabled

echo Disabling Remote Access Auto Connection Manager...
sc stop RasAuto
sc config RasAuto start= disabled

echo Disabling Remote Access Connection Manager...
sc stop RasMan
sc config RasMan start= disabled

echo Disabling Remote Desktop Configuration...
sc stop SessionEnv
sc config SessionEnv start= disabled

echo Disabling Remote Desktop Services...
sc stop TermService
sc config TermService start= disabled

echo Disabling Remote Desktop Services UserMode Port Redirector...
sc stop UmRdpService
sc config UmRdpService start= disabled

echo Disabling Remote Procedure Call (RPC) Locator...
sc stop RpcLocator
sc config RpcLocator start= disabled

echo Disabling Remote Registry...
sc stop RemoteRegistry
sc config RemoteRegistry start= disabled

echo Disabling Retail Demo Service...
sc stop RetailDemo
sc config RetailDemo start= disabled

echo Disabling Routing and Remote Access...
sc stop RemoteAccess
sc config RemoteAccess start= disabled

echo Disabling Radio Management Service...
sc stop RmSvc
sc config RmSvc start= disabled

echo Disabling SNMP Trap...
sc stop SNMPTRAP
sc config SNMPTRAP start= disabled

echo Disabling Secondary Logon...
sc stop seclogon
sc config seclogon start= disabled

echo Disabling Security Center...
sc stop wscsvc
sc config wscsvc start= disabled

echo Disabling Security Accounts Manager...
sc stop SamSs
sc config SamSs start= disabled

echo Disabling Sensor Data Service...
sc stop SensorDataService
sc config SensorDataService start= disabled

echo Disabling Sensor Monitoring Service...
sc stop SensrSvc
sc config SensrSvc start= disabled

echo Disabling Sensor Service...
sc stop SensorService
sc config SensorService start= disabled

echo Disabling Server...
sc stop LanmanServer
sc config LanmanServer start= disabled

echo Disabling Server...
sc stop ssh-agent
sc config ssh-agent start= disabled

echo Disabling Shared PC Account Manager...
sc stop shpamsvc
sc config shpamsvc start= disabled

echo Disabling Shell Hardware Detection...
sc stop ShellHWDetection
sc config ShellHWDetection start= disabled

echo Disabling Smart Card...
sc stop SCardSvr
sc config SCardSvr start= disabled

echo Disabling Smart Card Device Enumeration Service...
sc stop ScDeviceEnum
sc config ScDeviceEnum start= disabled

echo Disabling Smart Card Removal Policy...
sc stop SCPolicySvc
sc config SCPolicySvc start= disabled

echo Disabling Spatial Data Service...
sc stop SharedRealitySvc
sc config SharedRealitySvc start= disabled

echo Disabling Storage Service...
sc stop StorSvc
sc config StorSvc start= disabled

echo Disabling Storage Tiers Management...
sc stop TieringEngineService
sc config TieringEngineService start= disabled

echo Disabling Superfetch (SysMain)...
sc stop SysMain
sc config SysMain start= disabled

echo Disabling System Guard Runtime Monitor Broker...
sc stop SgrmBroker
sc config SgrmBroker start= disabled

echo Disabling Telephony...
sc stop TapiSrv
sc config TapiSrv start= disabled

echo Disabling Themes...
sc stop Themes
sc config Themes start= disabled

echo Disabling Tile Data model server...
sc stop tiledatamodelsvc
sc config tiledatamodelsvc start= disabled

echo Disabling Touch Keyboard and Handwriting Panel Service...
sc stop TabletInputService
sc config TabletInputService start= disabled

echo Disabling Update Orchestrator Service...
sc stop UsoSvc
sc config UsoSvc start= disabled

echo Disabling User Experience Virtualization Service...
sc stop UevAgentService
sc config UevAgentService start= disabled

echo Disabling WalletService...
sc stop WalletService
sc config WalletService start= disabled

echo Disabling WMI Performance Adapter...
sc stop wmiApSrv
sc config wmiApSrv start= disabled

echo Disabling WWAN AutoConfig...
sc stop WwanSvc
sc config WwanSvc start= disabled

echo Disabling Web Account Manager...
sc stop TokenBroker
sc config TokenBroker start= disabled

echo Disabling WebClient...
sc stop WebClient
sc config WebClient start= disabled

echo Disabling Wi-Fi Direct Services Connection Manager Service...
sc stop WFDSConMgrSvc
sc config WFDSConMgrSvc start= disabled

echo Disabling Windows Backup...
sc stop SDRSVC
sc config SDRSVC start= disabled

echo Disabling Windows Biometric Service...
sc stop WbioSrvc
sc config WbioSrvc start= disabled

echo Disabling Windows Camera Frame Server...
sc stop FrameServer
sc config FrameServer start= disabled

echo Disabling Windows Connect Now - Config Registrar...
sc stop wcncsvc
sc config wcncsvc start= disabled

echo Disabling Windows Defender Advanced Threat Protection Service...
sc stop Sense
sc config Sense start= disabled

echo Disabling Windows Defender Antivirus Network Inspection Service...
sc stop WdNisSvc
sc config WdNisSvc start= disabled

echo Disabling Windows Defender Antivirus Service...
sc stop WinDefend
sc config WinDefend start= disabled

echo Disabling Windows Defender Security Center Service...
sc stop SecurityHealthService
sc config SecurityHealthService start= disabled

echo Disabling Windows Encryption Provider Host Service...
sc stop WEPHOSTSVC
sc config WEPHOSTSVC start= disabled

echo Disabling Windows Error Reporting Service...
sc stop WerSvc
sc config WerSvc start= disabled

echo Disabling Windows Event Collector...
sc stop Wecsvc
sc config Wecsvc start= disabled

echo Disabling Windows Font Cache Service...
sc stop FontCache
sc config FontCache start= disabled

echo Disabling Windows Image Acquisition (WIA)...
sc stop StiSvc
sc config StiSvc start= disabled

echo Disabling Windows Insider Service...
sc stop wisvc
sc config wisvc start= disabled

echo Disabling Windows License Manager Service...
sc stop LicenseManager
sc config LicenseManager start= disabled

echo Disabling Windows Mobile Hotspot Service...
sc stop icssvc
sc config icssvc start= disabled

echo Disabling Windows Media Player Network Sharing Service...
sc stop WMPNetworkSvc
sc config WMPNetworkSvc start= disabled

echo Disabling Windows Presentation Foundation Font Cache 3.0.0.0...
sc stop FontCache3.0.0.0
sc config FontCache3.0.0.0 start= disabled

echo Disabling Windows Push Notifications System Service...
sc stop WpnService
sc config WpnService start= disabled

echo Disabling Windows Perception Simulation Service...
sc stop perceptionsimulation
sc config perceptionsimulation start= disabled

echo Disabling Windows Perception Service...
sc stop spectrum
sc config spectrum start= disabled

echo Disabling Windows Remote Management (WS-Management)...
sc stop WinRM
sc config WinRM start= disabled

echo Disabling Windows Search...
sc stop WSearch
sc config WSearch start= disabled

echo Disabling Windows Security Service...
sc stop SecurityHealthService
sc config SecurityHealthService start= disabled

echo Disabling Windows Time...
sc stop W32Time
sc config W32Time start= disabled

echo Disabling Windows Update...
sc stop wuauserv
sc config wuauserv start= disabled

echo Disabling Windows Update Medic Service...
sc stop WaaSMedicSvc
sc config WaaSMedicSvc start= disabled

echo Disabling Workstation...
sc stop LanmanWorkstation
sc config LanmanWorkstation start= disabled

echo Disabling Xbox Accessory Management Service...
sc stop XboxGipSvc
sc config XboxGipSvc start= disabled

echo Disabling Xbox Game Monitoring...
sc stop xbgm
sc config xbgm start= disabled

echo Disabling Xbox Live Auth Manager...
sc stop XblAuthManager
sc config XblAuthManager start= disabled

echo Disabling Xbox Live Game Save...
sc stop XblGameSave
sc config XblGameSave start= disabled

echo Disabling Xbox Live Networking Service...
sc stop XboxNetApiSvc
sc config XboxNetApiSvc start= disabled
cls

echo.
echo.

net stop "SysMain"
net stop "DiagTrack"
net stop "WSearch"
net stop "WerSvc"
net stop "dmwappushservice"
net stop "Fax"
net stop "TermService"
net stop "wlidsvc"
net stop "MapsBroker"
net stop "RetailDemo"
net stop "PhoneSvc"
net stop "WMPNetworkSvc"
net stop "TrkWks"
net stop "RemoteRegistry"
net stop "WbioSrvc"
net stop "TabletInputService"
net stop "iphlpsvc"
net stop "SharedAccess"
net stop "PrintSpooler"
net stop "BthAvctpSvc"
exit
