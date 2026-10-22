<#
.SYNOPSIS
    Z LAG wallpaper & lock screen installer (user-changeable)
.DESCRIPTION
    - Applies the Z LAG desktop wallpaper and lock screen as defaults after install.
    - Unlocks personalization so ANY user can change wallpaper / lock screen.
    - On REINSTALL over an older locked build: clears machine + per-user locks,
      removes the old enforce scheduled task, and unlocks offline profile hives
      (users who were locked before get unlocked without needing a new account).
    - Seeds Default User so brand-new profiles also start unlocked.
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Continue'

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "[INIT] Applying Z LAG wallpaper (changeable) + unlocking existing locks" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

# Ensure .NET drawing engine is ready for true header compilation
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# Helpers: unlock personalization keys on a registry root path
# ------------------------------------------------------------
function Clear-ZLagWallpaperLocks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HiveRoot  # e.g. "Registry::HKEY_USERS\S-1-5-21-..." or "HKLM:"
    )

    $targets = @(
        @{ Path = "$HiveRoot\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"; Names = @('NoChangingWallPaper') },
        @{ Path = "$HiveRoot\Software\Policies\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop"; Names = @('NoChangingWallPaper') },
        @{ Path = "$HiveRoot\Software\Policies\Microsoft\Windows\Personalization"; Names = @('NoChangingLockScreen', 'NoLockScreen', 'LockScreenImage', 'LockScreenOverlaysDisabled') },
        @{ Path = "$HiveRoot\Software\Microsoft\Windows\CurrentVersion\Policies\System"; Names = @('Wallpaper', 'WallpaperStyle') }
    )

    foreach ($t in $targets) {
        if (Test-Path $t.Path) {
            foreach ($n in $t.Names) {
                Remove-ItemProperty -Path $t.Path -Name $n -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Mount-ZLagUserHive {
    param(
        [Parameter(Mandatory = $true)][string]$NtuserPath,
        [Parameter(Mandatory = $true)][string]$MountName
    )
    if (-not (Test-Path $NtuserPath)) { return $false }
    if (Test-Path "Registry::HKEY_USERS\$MountName") { return $true }
    $null = & reg.exe load "HKU\$MountName" $NtuserPath 2>$null
    return (Test-Path "Registry::HKEY_USERS\$MountName")
}

function Dismount-ZLagUserHive {
    param([Parameter(Mandatory = $true)][string]$MountName)
    if (Test-Path "Registry::HKEY_USERS\$MountName") {
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        $null = & reg.exe unload "HKU\$MountName" 2>$null
    }
}

# ------------------------------------------------------------
# PHASE 0 (FIRST): strip old locks + enforce task before anything else
# So a reinstall on an already-locked PC unlocks immediately.
# ------------------------------------------------------------
Write-Host "`n[UNLOCK] Clearing machine-wide wallpaper locks from previous installs..." -ForegroundColor Yellow

# Old force-lock scheduled tasks
$taskNames = @(
    'Z-LAG-LockScreen-Enforce',
    'Z LAG Opti Services - Lock Screen'
)
foreach ($taskName in $taskNames) {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  [-] Removed lock task: $taskName" -ForegroundColor Green
    }
}

# Machine GPO / policy locks
$machinePolicyRoots = @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
)
foreach ($root in $machinePolicyRoots) {
    if (Test-Path $root) {
        foreach ($n in @(
            'NoChangingLockScreen', 'NoLockScreen', 'LockScreenImage',
            'NoChangingWallPaper', 'Wallpaper', 'WallpaperStyle'
        )) {
            Remove-ItemProperty -Path $root -Name $n -Force -ErrorAction SilentlyContinue
        }
    }
}

# PersonalizationCSP Status=1 is what greys out wallpaper in Settings
$csp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
if (Test-Path $csp) {
    foreach ($name in @(
        'DesktopImagePath', 'DesktopImageStatus', 'DesktopImageUrl',
        'LockScreenImagePath', 'LockScreenImageStatus', 'LockScreenImageUrl'
    )) {
        Remove-ItemProperty -Path $csp -Name $name -Force -ErrorAction SilentlyContinue
    }
    # If the key is empty of our forced values, leave the key; values are what lock UX
}
Write-Host "[+] Phase 0: Machine locks cleared (safe for reinstall over locked builds)." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 1: FILE DISCOVERY & CROSS-FORMAT CONVERSION
# ------------------------------------------------------------
$desktopSource = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Desktop.png"
$lockSource    = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Lock.png"
$singleSource  = Join-Path $PSScriptRoot "Z-LAG_Wallpaper.png"

if (-not (Test-Path $desktopSource)) {
    if (Test-Path $singleSource) { $desktopSource = $singleSource; $lockSource = $singleSource }
    else { Write-Error "Target wallpaper file not found!"; exit 1 }
}
if (-not (Test-Path $lockSource)) { $lockSource = $desktopSource }

$paths = @(
    "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER",
    "C:\Windows\Web\Screen",
    "C:\Windows\Web\Wallpaper\Windows",
    "C:\Windows\System32\oobe\info\backgrounds",
    "C:\ProgramData\Microsoft\Windows\Images"
)
foreach ($p in $paths) { if (-not (Test-Path $p)) { New-Item $p -ItemType Directory -Force | Out-Null } }

$destDesktopPng = "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER\Z-LAG_Desktop.png"
$destLockPng    = "C:\Windows\Web\Screen\Z-LAG_Lock.png"
$destDesktopJpg = "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER\Z-LAG_Desktop.jpg"
$destLockJpg    = "C:\Windows\Web\Screen\Z-LAG_Lock.jpg"

Copy-Item $desktopSource $destDesktopPng -Force | Out-Null
Copy-Item $lockSource $destLockPng -Force | Out-Null

function Save-AsTrueJpeg {
    param([string]$src, [string]$dest)
    try {
        $img = [System.Drawing.Image]::FromFile($src)
        $img.Save($dest, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $img.Dispose()
    } catch {
        Copy-Item $src $dest -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
Save-AsTrueJpeg -src $desktopSource -dest $destDesktopJpg
Save-AsTrueJpeg -src $lockSource -dest $destLockJpg

# Seed common fallback assets with Z LAG images (defaults only — not locked)
$jpgAssets = @(
    "C:\Windows\Web\Screen\img100.jpg",
    "C:\Windows\Web\Screen\img102.jpg",
    "C:\Windows\Web\Wallpaper\Windows\img0.jpg",
    "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg"
)
$pngAssets = @(
    "C:\Windows\Web\Screen\img101.png",
    "C:\Windows\Web\Screen\img103.png"
)

foreach ($asset in $jpgAssets) {
    if (Test-Path $asset) { takeown /f $asset /a | Out-Null; icacls $asset /grant "administrators:F" | Out-Null }
    Copy-Item $destLockJpg $asset -Force -ErrorAction SilentlyContinue | Out-Null
}
foreach ($asset in $pngAssets) {
    if (Test-Path $asset) { takeown /f $asset /a | Out-Null; icacls $asset /grant "administrators:F" | Out-Null }
    Copy-Item $destLockPng $asset -Force -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "[+] Phase 1: Desktop + lock screen image defaults prepared." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 2: PERMISSION CLEARANCE (readable — not write-locked against users)
# ------------------------------------------------------------
Write-Host "`n[SECURITY] Granting access to wallpaper assets..." -ForegroundColor Yellow

$securityTargets = @($destDesktopPng, $destLockPng, $destDesktopJpg, $destLockJpg, "C:\Windows\Web\Screen", "C:\Windows\Web\Wallpaper")
foreach ($target in $securityTargets) {
    if (Test-Path $target) {
        if (Test-Path $target -PathType Container) {
            takeown /f $target /r /d y | Out-Null
            icacls $target /grant "administrators:(OI)(CI)F" /t | Out-Null
            icacls $target /grant "*S-1-15-2-1:(OI)(CI)(R,RX)" /t | Out-Null
            icacls $target /grant "NT AUTHORITY\SYSTEM:(OI)(CI)(F)" /t | Out-Null
            icacls $target /grant "Users:(OI)(CI)(R,RX)" /t | Out-Null
            icacls $target /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(R,RX)" /t | Out-Null
        } else {
            takeown /f $target /a | Out-Null
            icacls $target /grant "administrators:F" | Out-Null
            icacls $target /grant "*S-1-15-2-1:(R,RX)" | Out-Null
            icacls $target /grant "NT AUTHORITY\SYSTEM:F" | Out-Null
            icacls $target /grant "Users:(R,RX)" | Out-Null
            icacls $target /grant "NT AUTHORITY\LOCAL SERVICE:(R,RX)" | Out-Null
        }
    }
}
Write-Host "[+] Phase 2: Assets readable system-wide." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 3: DEFAULT USER + EVERY EXISTING PROFILE (online & offline)
# ------------------------------------------------------------
Write-Host "`n[PROFILES] Seeding defaults and unlocking every user profile..." -ForegroundColor Yellow

function Set-ZLagProfileWallpaper {
    param([Parameter(Mandatory = $true)][string]$HiveRoot)

    $desktopPath = "$HiveRoot\Control Panel\Desktop"
    if (-not (Test-Path $desktopPath)) { New-Item $desktopPath -Force | Out-Null }

    Set-ItemProperty -Path $desktopPath -Name "Wallpaper" -Value $destDesktopPng -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $desktopPath -Name "WallpaperStyle" -Value "2" -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $desktopPath -Name "TileWallpaper" -Value "0" -Type String -Force -ErrorAction SilentlyContinue

    Clear-ZLagWallpaperLocks -HiveRoot $HiveRoot
}

# 3a. Default user template (future new accounts)
$defaultHivePath = "C:\Users\Default\NTUSER.DAT"
$defaultMount = "ZLagDefaultUser"
if (Test-Path $defaultHivePath) {
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
    if (Mount-ZLagUserHive -NtuserPath $defaultHivePath -MountName $defaultMount) {
        Set-ZLagProfileWallpaper -HiveRoot "Registry::HKEY_USERS\$defaultMount"
        Dismount-ZLagUserHive -MountName $defaultMount
        Write-Host "  [+] Default User template: wallpaper set, locks cleared" -ForegroundColor Green
    } else {
        Write-Host "  [-] Default User hive could not be mounted" -ForegroundColor Yellow
    }
}

# 3b. Currently loaded user hives (logged-on users — the "already locked" case)
Get-ChildItem "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | ForEach-Object {
    $sid = $_.PSChildName
    # Skip system / well-known / our temp mounts
    if ($sid -match '^(S-1-5-18|S-1-5-19|S-1-5-20|\.DEFAULT|Default|ZLag)') { return }
    if ($sid -notmatch '^S-1-5-21-') { return }
    try {
        Set-ZLagProfileWallpaper -HiveRoot "Registry::HKEY_USERS\$sid"
        Write-Host "  [+] Live profile unlocked: $sid" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Live profile skip: $sid" -ForegroundColor Yellow
    }
}

# 3c. Offline profiles (users not currently logged in — still unlock their NTUSER.DAT)
$profileList = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
if (Test-Path $profileList) {
    Get-ChildItem $profileList -ErrorAction SilentlyContinue | ForEach-Object {
        $sid = $_.PSChildName
        if ($sid -notmatch '^S-1-5-21-') { return }

        # Already handled if loaded
        if (Test-Path "Registry::HKEY_USERS\$sid") { return }

        $profilePath = $null
        try { $profilePath = (Get-ItemProperty -Path $_.PSPath -Name ProfileImagePath -ErrorAction Stop).ProfileImagePath } catch { return }
        if ([string]::IsNullOrWhiteSpace($profilePath)) { return }

        $ntuser = Join-Path $profilePath 'NTUSER.DAT'
        if (-not (Test-Path $ntuser)) { return }

        $mountName = "ZLagUnlock_$($sid.Substring([Math]::Max(0, $sid.Length - 12)))"
        if (Mount-ZLagUserHive -NtuserPath $ntuser -MountName $mountName) {
            try {
                Set-ZLagProfileWallpaper -HiveRoot "Registry::HKEY_USERS\$mountName"
                Write-Host "  [+] Offline profile unlocked: $profilePath" -ForegroundColor Green
            } finally {
                Dismount-ZLagUserHive -MountName $mountName
            }
        } else {
            Write-Host "  [-] Offline profile busy/skip: $profilePath" -ForegroundColor Yellow
        }
    }
}

# System presentation hives (lock screen LogonUI)
$creativeRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative"
$systemHives = @(".DEFAULT", "S-1-5-18", "S-1-5-19", "S-1-5-20", "Default")
foreach ($hive in $systemHives) {
    $targetPath = "$creativeRoot\$hive"
    if (-not (Test-Path $targetPath)) { New-Item $targetPath -Force | Out-Null }
    foreach ($mc in @("12345678-1234-1234-1234-1234567890ab", "CombinedProperties")) {
        $finalKey = "$targetPath\$mc"
        if (-not (Test-Path $finalKey)) { New-Item $finalKey -Force | Out-Null }
        Set-ItemProperty -Path $finalKey -Name "LandscapeAssetPath" -Value $destLockJpg -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $finalKey -Name "PortraitAssetPath" -Value $destLockJpg -Force -ErrorAction SilentlyContinue
    }
    try {
        [Microsoft.Win32.Registry]::SetValue("Registry::HKEY_USERS\$hive\Control Panel\Desktop", "Wallpaper", $destDesktopPng, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("Registry::HKEY_USERS\$hive\Control Panel\Desktop", "WallpaperStyle", "2", [Microsoft.Win32.RegistryValueKind]::String)
    } catch {}
}
Write-Host "[+] Phase 3: All reachable profiles unlocked + defaults seeded." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 4: MACHINE POLICY FINISH + LIVE APPLY
# ------------------------------------------------------------
Write-Host "`n[POLICIES] Final unlock pass + apply desktop wallpaper..." -ForegroundColor Yellow

$sysPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $sysPol)) { New-Item $sysPol -Force | Out-Null }
Set-ItemProperty -Path $sysPol -Name "DisableAcrylicOnBackgroundOnLogon" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $sysPol -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord -Force

# Re-clear CSP in case anything recreated it mid-run
if (Test-Path $csp) {
    foreach ($name in @(
        'DesktopImagePath', 'DesktopImageStatus', 'DesktopImageUrl',
        'LockScreenImagePath', 'LockScreenImageStatus', 'LockScreenImageUrl'
    )) {
        Remove-ItemProperty -Path $csp -Name $name -Force -ErrorAction SilentlyContinue
    }
}

# Live apply desktop wallpaper once (starting default)
$signature = @"
using System.Runtime.InteropServices;
public class EngineWallpaper {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void Apply(string p) { SystemParametersInfo(20, 0, p, 0x01 | 0x02); }
}
"@
if (-not ([System.Management.Automation.PSTypeName]'EngineWallpaper').Type) { Add-Type -TypeDefinition $signature }
[EngineWallpaper]::Apply($destDesktopPng)
Write-Host "[+] Phase 4: Desktop wallpaper applied; change settings remain unlocked." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 5: CACHE REFRESH
# ------------------------------------------------------------
Write-Host "`n[CACHE] Clearing stale lock-screen / wallpaper UI caches..." -ForegroundColor Yellow

$systemDataPath = "C:\ProgramData\Microsoft\Windows\SystemData"
if (Test-Path $systemDataPath) {
    takeown /f $systemDataPath /r /d y | Out-Null
    icacls $systemDataPath /grant "administrators:(OI)(CI)F" /t | Out-Null
    Get-ChildItem -Path $systemDataPath -Recurse -Include "LockScreen_*","ControlPanelWallpaper_*" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
Write-Host "[+] Phase 5: Caches cleared." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 6: REFRESH SHELL
# ------------------------------------------------------------
Write-Host "`n[REFRESH] Refreshing shell presentation..." -ForegroundColor Cyan
Stop-Process -Name "SystemSettings" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "[+] DONE" -ForegroundColor Green
Write-Host "    Desktop wallpaper  = Z LAG default (changeable)" -ForegroundColor White
Write-Host "    Lock screen        = Z LAG default (changeable)" -ForegroundColor White
Write-Host "    New users          = unlocked from first login" -ForegroundColor White
Write-Host "    Existing locked PC = unlocked on this reinstall" -ForegroundColor White
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host ""
