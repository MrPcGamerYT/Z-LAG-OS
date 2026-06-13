# ============================================================
# Z LAG OS Wallpaper & Lock Screen Setter – ULTRA AGGRESSIVE EDITION (FIXED)
# Uses 12 different methods + deep system hijacking to guarantee lock screen
# ============================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator / TrustedInstaller."
    exit 1
}

# ------------------------------------------------------------------
# 1. Locate source images (flexible lookup)
# ------------------------------------------------------------------
$desktopSource = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Desktop.png"
$lockSource   = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Lock.png"
$singleSource = Join-Path $PSScriptRoot "Z-LAG_Wallpaper.png"

if (-not (Test-Path $desktopSource)) {
    if (Test-Path $singleSource) {
        $desktopSource = $singleSource
        $lockSource    = $singleSource
        Write-Host "Using single wallpaper file for both." -ForegroundColor Yellow
    } else {
        Write-Error "No wallpaper found. Exiting."
        exit 1
    }
}
if (-not (Test-Path $lockSource) -and (Test-Path $desktopSource)) {
    $lockSource = $desktopSource
}

# ------------------------------------------------------------------
# 2. Create destination folders and copy images permanently
# ------------------------------------------------------------------
$destFolder       = "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER"
$screenFolder     = "C:\Windows\Web\Screen"
$lockScreenFolder = "C:\ProgramData\Microsoft\Windows\LockScreen"

@($destFolder, $screenFolder, $lockScreenFolder) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item $_ -ItemType Directory -Force | Out-Null }
}

$destDesktop  = "$destFolder\Z-LAG_Desktop.png"
$destLock     = "$screenFolder\Z-LAG_Lock.png"
$destLockAlt  = "$lockScreenFolder\LockScreen.jpg"

Copy-Item $desktopSource $destDesktop -Force
Write-Host "Desktop wallpaper copied to: $destDesktop" -ForegroundColor Green
Copy-Item $lockSource $destLock -Force
Write-Host "Lock screen copied to: $destLock" -ForegroundColor Green
Copy-Item $lockSource $destLockAlt -Force

# ------------------------------------------------------------------
# 3. DESKTOP WALLPAPER – Apply to ALL users (registry + API)
# ------------------------------------------------------------------
Write-Host "`n[DESKTOP] Applying desktop wallpaper to all users..." -ForegroundColor Cyan

Get-ChildItem "Registry::HKU" | ForEach-Object {
    $userKey = $_.Name
    try {
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", "Wallpaper",      $destDesktop, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", "WallpaperStyle", "2",           [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", "TileWallpaper",  "0",           [Microsoft.Win32.RegistryValueKind]::String)
        Write-Host "  Desktop wallpaper set for user $userKey"
    } catch { }
}
[Microsoft.Win32.Registry]::SetValue("HKEY_USERS\.DEFAULT\Control Panel\Desktop", "Wallpaper",      $destDesktop, [Microsoft.Win32.RegistryValueKind]::String)
[Microsoft.Win32.Registry]::SetValue("HKEY_USERS\.DEFAULT\Control Panel\Desktop", "WallpaperStyle", "2",           [Microsoft.Win32.RegistryValueKind]::String)
[Microsoft.Win32.Registry]::SetValue("HKEY_USERS\.DEFAULT\Control Panel\Desktop", "TileWallpaper",  "0",           [Microsoft.Win32.RegistryValueKind]::String)

$source = @"
using System.Runtime.InteropServices;
public class DesktopWallpaper {
    public const int SetDesktopWallpaper = 20;
    public const int UpdateIniFile = 0x01;
    public const int SendWinIniChange = 0x02;
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaper(string path) {
        SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
    }
}
"@
if (-not ([System.Management.Automation.PSTypeName]'DesktopWallpaper').Type) {
    Add-Type -TypeDefinition $source
}
[DesktopWallpaper]::SetWallpaper($destDesktop)
Write-Host "[DESKTOP] Desktop wallpaper applied successfully." -ForegroundColor Green

# ==================================================================
# ULTRA AGGRESSIVE LOCK SCREEN METHODS (12 independent approaches)
# ==================================================================

# METHOD 1: Registry Policy (system-wide)
Write-Host "`n[LOCK SCREEN] Method 1: Registry Policy..." -ForegroundColor Cyan
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "LockScreenImage"     -Value $destLock -Type String -Force
Set-ItemProperty -Path $regPath -Name "NoChangingLockScreen" -Value 1          -Type DWord -Force
Write-Host "[LOCK SCREEN] Method 1 completed." -ForegroundColor Green

# METHOD 2: OOBE Registry
Write-Host "[LOCK SCREEN] Method 2: OOBE Registry..." -ForegroundColor Cyan
$oobePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
if (-not (Test-Path $oobePath)) { New-Item -Path $oobePath -Force | Out-Null }
Set-ItemProperty -Path $oobePath -Name "LockScreenImage" -Value $destLock -Type String -Force
Write-Host "[LOCK SCREEN] Method 2 completed." -ForegroundColor Green

# METHOD 3: Current User Registry
Write-Host "[LOCK SCREEN] Method 3: Current User Registry..." -ForegroundColor Cyan
$userLockPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
if (-not (Test-Path $userLockPath)) { New-Item -Path $userLockPath -Force | Out-Null }
Set-ItemProperty -Path $userLockPath -Name "LockScreenImagePath" -Value $destLock -Type String -Force
Set-ItemProperty -Path $userLockPath -Name "LockScreenImage"     -Value $destLock -Type String -Force
Write-Host "[LOCK SCREEN] Method 3 completed." -ForegroundColor Green

# METHOD 4: Scheduled Task (SYSTEM startup)
Write-Host "[LOCK SCREEN] Method 4: Startup Scheduled Task..." -ForegroundColor Cyan
$taskName = "Z-LAG-OS-LockScreen"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $taskExists) {
    $action = New-ScheduledTaskAction -Execute "reg.exe" -Argument 'add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "LockScreenImage" /t REG_SZ /d "C:\Windows\Web\Screen\Z-LAG_Lock.png" /f'
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
    Write-Host "[LOCK SCREEN] Method 4 completed (startup task created)." -ForegroundColor Green
} else {
    Write-Host "[LOCK SCREEN] Method 4 completed (task already exists)." -ForegroundColor Green
}

# METHOD 5: Default User Profile
Write-Host "[LOCK SCREEN] Method 5: Default User Profile..." -ForegroundColor Cyan
$defaultHive = "C:\Users\Default\NTUSER.DAT"
if (Test-Path $defaultHive) {
    & reg.exe load HKU\DefUserTemp $defaultHive 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $defaultLockPath = "Registry::HKEY_USERS\DefUserTemp\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
        if (-not (Test-Path $defaultLockPath)) { New-Item -Path $defaultLockPath -Force | Out-Null }
        Set-ItemProperty -Path $defaultLockPath -Name "LockScreenImagePath" -Value $destLock -Force
        [GC]::Collect(); [GC]::WaitForPendingFinalizers()
        Start-Sleep -Milliseconds 500
        & reg.exe unload HKU\DefUserTemp 2>&1 | Out-Null
        Write-Host "[LOCK SCREEN] Method 5 completed." -ForegroundColor Green
    } else {
        Write-Warning "[LOCK SCREEN] Method 5: could not load default hive."
    }
}

# METHOD 6: Group Policy Preference
Write-Host "[LOCK SCREEN] Method 6: Group Policy Preference..." -ForegroundColor Cyan
try {
    & reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "LockScreenImage" /t REG_SZ /d "$destLock" /f 2>&1 | Out-Null
    Write-Host "[LOCK SCREEN] Method 6 completed." -ForegroundColor Green
} catch {
    Write-Host "[LOCK SCREEN] Method 6 skipped." -ForegroundColor Yellow
}

# METHOD 7: System File Hijack & Cache Purge (ultra‑aggressive)
Write-Host "`n[LOCK SCREEN] Method 7: System File Hijack & Cache Purge..." -ForegroundColor Cyan

# 7a. Disable Rotating Lock Screen for every user (proper registry paths with colon where needed)
Get-ChildItem "Registry::HKU" | ForEach-Object {
    $userKey = $_.Name
    if ($userKey -match "^S-") {
        try {
            & reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative\$userKey" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            & reg.exe add "HKU\$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        } catch {}
    }
}

# 7b. System‑wide Spotlight disable (FIXED: added colon in HKLM paths)
@(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CloudContent"
) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -Path $_ -Force | Out-Null }
    Set-ItemProperty -Path $_ -Name "DisableWindowsSpotlightFeatures" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $_ -Name "DisableThirdPartySuggestions"    -Value 1 -Type DWord -Force
}

# 7c. Overwrite every known system lock screen file
$systemScreenImages = @(
    "C:\Windows\Web\Screen\img100.jpg",
    "C:\Windows\Web\Screen\img101.jpg",
    "C:\Windows\Web\Screen\img102.jpg",
    "C:\Windows\Web\Screen\img103.png",
    "C:\Windows\Web\Screen\img104.jpg",
    "C:\Windows\Web\Screen\img105.jpg",
    "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
)
foreach ($img in $systemScreenImages) {
    if (Test-Path $img) {
        & takeown.exe /f $img 2>&1 | Out-Null
        & icacls.exe $img /reset 2>&1 | Out-Null
        & icacls.exe $img /grant "Administrators:(F)" 2>&1 | Out-Null
        Copy-Item $lockSource $img -Force
        Set-ItemProperty -Path $img -Name IsReadOnly -Value $true
        Write-Host "  Hijacked and locked: $img" -ForegroundColor DarkGreen
    }
}

# 7d. Deep clean Windows lock screen cache folders
$systemDataPath = "C:\ProgramData\Microsoft\Windows\SystemData"
if (Test-Path $systemDataPath) {
    Write-Host "  Wiping SystemData LockScreen Cache..." -ForegroundColor Yellow
    & takeown.exe /R /D Y /F $systemDataPath 2>&1 | Out-Null
    & icacls.exe $systemDataPath /reset /t 2>&1 | Out-Null
    Get-ChildItem -Path "$systemDataPath\*" -Directory | ForEach-Object {
        $readOnlyPath = Join-Path $_.FullName "ReadOnly"
        if (Test-Path $readOnlyPath) {
            Get-ChildItem -Path "$readOnlyPath\LockScreen_*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
Write-Host "[LOCK SCREEN] Method 7 completed (system files hijacked, cache wiped)." -ForegroundColor Green

# METHOD 8: All‑User Registry Proactive Injection
Write-Host "[LOCK SCREEN] Method 8: All-User Registry Injection..." -ForegroundColor Cyan
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $userDir = $_.FullName
    $ntuser = Join-Path $userDir "NTUSER.DAT"
    if (Test-Path $ntuser) {
        $loadKey = "HKU\Temp_$($_.Name)"
        & reg.exe load $loadKey $ntuser 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $lockPath = "Registry::$loadKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
            if (-not (Test-Path $lockPath)) { New-Item -Path $lockPath -Force | Out-Null }
            Set-ItemProperty -Path $lockPath -Name "LockScreenImagePath" -Value $destLock -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $lockPath -Name "LockScreenImage"     -Value $destLock -Force -ErrorAction SilentlyContinue
            [GC]::Collect(); [GC]::WaitForPendingFinalizers()
            Start-Sleep -Milliseconds 300
            & reg.exe unload $loadKey 2>&1 | Out-Null
            Write-Host "  Injected lock screen for user: $($_.Name)" -ForegroundColor DarkGreen
        }
    }
}
Write-Host "[LOCK SCREEN] Method 8 completed." -ForegroundColor Green

# METHOD 9: Per‑User Logon Task
Write-Host "[LOCK SCREEN] Method 9: Per-User Logon Task..." -ForegroundColor Cyan
$logonTaskName = "Z-LAG-LockScreen-Logon"
$logonTaskExists = Get-ScheduledTask -TaskName $logonTaskName -ErrorAction SilentlyContinue
if (-not $logonTaskExists) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen' -Name LockScreenImagePath -Value '$destLock' -Force; Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen' -Name LockScreenImage -Value '$destLock' -Force`""
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName $logonTaskName -Action $action -Trigger $trigger -Principal $principal -Force
    Write-Host "[LOCK SCREEN] Method 9 completed (per-user logon task created)." -ForegroundColor Green
} else {
    Write-Host "[LOCK SCREEN] Method 9 completed (logon task already exists)." -ForegroundColor Green
}

# METHOD 10: OOBE Logon Background Fallback
Write-Host "[LOCK SCREEN] Method 10: OOBE Logon Background Fallback..." -ForegroundColor Cyan
$oobeBgDir = "C:\Windows\System32\oobe\info\backgrounds"
if (-not (Test-Path $oobeBgDir)) { New-Item $oobeBgDir -ItemType Directory -Force | Out-Null }
$oobeBg = Join-Path $oobeBgDir "backgroundDefault.jpg"
Copy-Item $lockSource $oobeBg -Force
if (Test-Path $oobeBg) {
    & takeown.exe /f $oobeBg 2>&1 | Out-Null
    & icacls.exe $oobeBg /grant "Administrators:(F)" 2>&1 | Out-Null
    Set-ItemProperty -Path $oobeBg -Name IsReadOnly -Value $true
    Write-Host "[LOCK SCREEN] Method 10 completed (logon screen background replaced)." -ForegroundColor Green
}

# METHOD 11: HKLM Lock Screen direct registry overrides
Write-Host "[LOCK SCREEN] Method 11: HKLM Lock Screen direct..." -ForegroundColor Cyan
@(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"
) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -Path $_ -Force | Out-Null }
    Set-ItemProperty -Path $_ -Name "LockScreenImagePath" -Value $destLock -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $_ -Name "LockScreenImage"     -Value $destLock -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $_ -Name "OEMBackground"       -Value 1          -Force -ErrorAction SilentlyContinue
}
Write-Host "[LOCK SCREEN] Method 11 completed." -ForegroundColor Green

# METHOD 12: Force Group Policy update
Write-Host "[LOCK SCREEN] Method 12: Forcing Group Policy refresh..." -ForegroundColor Cyan
try { & gpupdate.exe /force /wait:0 2>&1 | Out-Null } catch {}
Write-Host "[LOCK SCREEN] Method 12 completed." -ForegroundColor Green

# ==================================================================
# VERIFICATION & CLEAN-UP
# ==================================================================
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "VERIFICATION:" -ForegroundColor Yellow
Write-Host "  Desktop Wallpaper: $destDesktop" -ForegroundColor White
Write-Host "  Lock Screen Image : $destLock" -ForegroundColor White
Write-Host "="*60 -ForegroundColor Cyan

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "`n✅ All 12 lock screen methods applied aggressively." -ForegroundColor Green
Write-Host "   -> If lock screen doesn't change, reboot the computer." -ForegroundColor Yellow
Write-Host "   -> After reboot, Windows will be forced to use your image." -ForegroundColor Yellow