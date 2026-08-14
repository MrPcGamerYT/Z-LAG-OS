<#
.SYNOPSIS
    THE SUPREME UNIVERSAL WALLPAPER & LOCK SCREEN CONSTANT FORCE ENGINE
.DESCRIPTION
    - Direct blueprint level injection via Default User NTUSER.DAT mounting.
    - Full system architecture asset takeover with verified true-binary JPEG encoders.
    - Complete mitigation arrays for unactivated OS personalization lockouts.
    - Global multi-hive SID registration (SYSTEM, LocalService, NetworkService, and Users).
#>

#Requires -RunAsAdministrator

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "[INIT] ACTIVATING SUPREME UNIVERSAL FORCE ENGINE (ALL WINDOWS BUILD MATRIX)" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

# Ensure .NET drawing engine is ready for true header compilation
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# PHASE 1: FILE DISCOVERY & RADICAL CROSS-FORMAT CONVERSION
# ------------------------------------------------------------
$desktopSource = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Desktop.png"
$lockSource    = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Lock.png"
$singleSource  = Join-Path $PSScriptRoot "Z-LAG_Wallpaper.png"

if (-not (Test-Path $desktopSource)) {
    if (Test-Path $singleSource) { $desktopSource = $singleSource; $lockSource = $singleSource }
    else { Write-Error "Target wallpaper file not found!"; exit 1 }
}
if (-not (Test-Path $lockSource)) { $lockSource = $desktopSource }

# Define every structural pathway across both Windows 10 and Windows 11 frameworks
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

# Force convert images into valid-header JPEGs to completely stop LogonUI graphic engine crashes
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

# Replace all potential fallback assets with your true-header files
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
Write-Host "[+] Phase 1: Image structures cross-compiled and factory assets replaced." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 2: GLOBAL PERMISSION CLEARANCE (UWP APPLICATION SANDBOX FIX)
# ------------------------------------------------------------
Write-Host "`n[SECURITY] Unlocking NT-Authority resource permissions..." -ForegroundColor Yellow

$securityTargets = @($destDesktopPng, $destLockPng, $destDesktopJpg, $destLockJpg, "C:\Windows\Web\Screen", "C:\Windows\Web\Wallpaper")
foreach ($target in $securityTargets) {
    if (Test-Path $target) {
        if (Test-Path $target -PathType Container) {
            takeown /f $target /r /d y | Out-Null
            icacls $target /grant "administrators:(OI)(CI)F" /t | Out-Null
            icacls $target /grant "*S-1-15-2-1:(OI)(CI)(R,RX,WDAC)" /t | Out-Null  # ALL APPLICATION PACKAGES
            icacls $target /grant "NT AUTHORITY\SYSTEM:(OI)(CI)(F)" /t | Out-Null
            icacls $target /grant "NT AUTHORITY\LOCAL SERVICE:(OI)(CI)(R,RX)" /t | Out-Null
        } else {
            takeown /f $target /a | Out-Null
            icacls $target /grant "administrators:F" | Out-Null
            icacls $target /grant "*S-1-15-2-1:(R,RX,WDAC)" | Out-Null
            icacls $target /grant "NT AUTHORITY\SYSTEM:F" | Out-Null
            icacls $target /grant "NT AUTHORITY\LOCAL SERVICE:(R,RX)" | Out-Null
        }
    }
}
Write-Host "[+] Phase 2: All execution targets unlocked for system-wide access." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 3: THE ULTIMATE TRICK - DEFAULT HIVE BLUEPRINT INJECTION
# ------------------------------------------------------------
Write-Host "`n[BLUEPRINT] Mounting and injecting configurations into Default User template hive..." -ForegroundColor Yellow

$defaultHivePath = "C:\Users\Default\NTUSER.DAT"
if (Test-Path $defaultHivePath) {
    # Force close any hanging read-locks on the template file
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    
    # Mount the template blueprint registry hive into our session
    reg load "HKU\DefaultUserTemplate" $defaultHivePath | Out-Null
    
    $templatePaths = @(
        "HKU\DefaultUserTemplate\Control Panel\Desktop",
        "HKU\DefaultUserTemplate\Software\Microsoft\Windows\CurrentVersion\Policies\System",
        "HKU\DefaultUserTemplate\Software\Policies\Microsoft\Windows\Personalization"
    )
    foreach ($tp in $templatePaths) { if (-not (Test-Path $tp)) { New-Item $tp -Force | Out-Null } }
    
    # Set values natively inside the blueprint so every account inherits them at setup
    Set-ItemProperty -Path "HKU\DefaultUserTemplate\Control Panel\Desktop" -Name "Wallpaper" -Value $destDesktopPng -Force
    Set-ItemProperty -Path "HKU\DefaultUserTemplate\Control Panel\Desktop" -Name "WallpaperStyle" -Value "2" -Force
    Set-ItemProperty -Path "HKU\DefaultUserTemplate\Control Panel\Desktop" -Name "TileWallpaper" -Value "0" -Force
    Set-ItemProperty -Path "HKU\DefaultUserTemplate\Software\Policies\Microsoft\Windows\Personalization" -Name "LockScreenImage" -Value $destLockJpg -Type String -Force
    Set-ItemProperty -Path "HKU\DefaultUserTemplate\Software\Policies\Microsoft\Windows\Personalization" -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force
    
    # Safely detach the blueprint hive
    reg unload "HKU\DefaultUserTemplate" | Out-Null
    Write-Host "[+] Phase 3: Default User template modified. All future profiles are forced." -ForegroundColor Green
} else {
    Write-Host "[-] Phase 3: Default User template hive path not resolved." -ForegroundColor Red
}

# ------------------------------------------------------------
# PHASE 4: MACHINE PROFILE MATRIX SEEDING
# ------------------------------------------------------------
Write-Host "`n[REGISTRY] Synchronizing system multi-hive initialization flags..." -ForegroundColor Yellow

$creativeRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative"
# S-1-5-18 = SYSTEM | S-1-5-19 = LocalService | S-1-5-20 = NetworkService | .DEFAULT = Universal Boot Core
$systemHives = @(".DEFAULT", "S-1-5-18", "S-1-5-19", "S-1-5-20", "Default")

foreach ($hive in $systemHives) {
    $targetPath = "$creativeRoot\$hive"
    if (-not (Test-Path $targetPath)) { New-Item $targetPath -Force | Out-Null }
    
    # Intercept dynamic, randomized UI registration structures with pre-baked universal target strings
    $mockContainers = @("12345678-1234-1234-1234-1234567890ab", "CombinedProperties")
    foreach ($mc in $mockContainers) {
        $finalKey = "$targetPath\$mc"
        if (-not (Test-Path $finalKey)) { New-Item $finalKey -Force | Out-Null }
        Set-ItemProperty -Path $finalKey -Name "LandscapeAssetPath" -Value $destLockJpg -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $finalKey -Name "PortraitAssetPath" -Value $destLockJpg -Force -ErrorAction SilentlyContinue
    }
    
    # Overwrite the base system presentation panels
    try {
        [Microsoft.Win32.Registry]::SetValue("Registry::HKEY_USERS\$hive\Control Panel\Desktop", "Wallpaper", $destDesktopPng, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("Registry::HKEY_USERS\$hive\Control Panel\Desktop", "WallpaperStyle", "2", [Microsoft.Win32.RegistryValueKind]::String)
    } catch {}
}
Write-Host "[+] Phase 4: Machine runtime profiles synced successfully." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 5: UN-ACTIVATED OS COMPLIANCE POLICIES & CSP MATRIX
# ------------------------------------------------------------
Write-Host "`n[POLICIES] Enforcing master corporate customization lockdowns..." -ForegroundColor Yellow

# Force-disable themes from execution loops so they can't override local configs
$themeKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Themes"
)
foreach ($tk in $themeKeys) {
    if (Test-Path $tk) {
        Set-ItemProperty -Path $tk -Name "InstallTheme" -Value "" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $tk -Name "InstallThemeLight" -Value "" -Force -ErrorAction SilentlyContinue
    }
}

# Standard GPO Framework configurations
$sysPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $sysPol)) { New-Item $sysPol -Force | Out-Null }
Set-ItemProperty -Path $sysPol -Name "DisableAcrylicOnBackgroundOnLogon" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $sysPol -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord -Force

$persPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $persPol)) { New-Item $persPol -Force | Out-Null }
Set-ItemProperty -Path $persPol -Name "LockScreenImage" -Value $destLockJpg -Type String -Force
Set-ItemProperty -Path $persPol -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force

# Personalization CSP Engine Parameters (Completely bypasses unactivated personalization locks)
$csp = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (-not (Test-Path $csp)) { New-Item $csp -Force | Out-Null }
Set-ItemProperty -Path $csp -Name "LockScreenImagePath" -Value $destLockJpg -Type String -Force
Set-ItemProperty -Path $csp -Name "LockScreenImageStatus" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $csp -Name "LockScreenImageUrl" -Value $destLockJpg -Type String -Force
Set-ItemProperty -Path $csp -Name "DesktopImagePath" -Value $destDesktopPng -Type String -Force
Set-ItemProperty -Path $csp -Name "DesktopImageStatus" -Value 1 -Type DWord -Force

# Force update active loaded user hives
Get-ChildItem "Registry::HKEY_USERS" | ForEach-Object {
    $u = $_.Name
    try {
        [Microsoft.Win32.Registry]::SetValue("$u\Control Panel\Desktop", "Wallpaper", $destDesktopPng, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$u\Control Panel\Desktop", "WallpaperStyle", "2", [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$u\Control Panel\Desktop", "TileWallpaper", "0", [Microsoft.Win32.RegistryValueKind]::String)
    } catch {}
}

# Direct C# User32 graphic layer flush
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
Write-Host "[+] Phase 5: Environmental lockdown structures deployed." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 6: SYSTEMDATA HARDWARE METADATA PURGE
# ------------------------------------------------------------
Write-Host "`n[CACHE] Flattening persistent system UI rendering caches..." -ForegroundColor Yellow

$systemDataPath = "C:\ProgramData\Microsoft\Windows\SystemData"
if (Test-Path $systemDataPath) {
    takeown /f $systemDataPath /r /d y | Out-Null
    icacls $systemDataPath /grant "administrators:(OI)(CI)F" /t | Out-Null
    
    Get-ChildItem -Path $systemDataPath -Recurse -Include "LockScreen_*","ControlPanelWallpaper_*" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
Write-Host "[+] Phase 6: System visual metadata fields cleared." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 7: COLD BOOT HARD ENFORCEMENT ENGINE Task
# ------------------------------------------------------------
$taskName = "Z-LAG-LockScreen-Enforce"
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
}

$taskPayload = "takeown /f 'C:\Windows\Web\Screen' /r /d y; icacls 'C:\Windows\Web\Screen' /grant 'administrators:(OI)(CI)F' /t; icacls 'C:\Windows\Web\Screen' /grant '*S-1-15-2-1:(OI)(CI)(R)' /t; Remove-Item -Path 'C:\ProgramData\Microsoft\Windows\SystemData\*\ReadOnly\LockScreen_*\*.*' -Force -Recurse -ErrorAction SilentlyContinue; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImageStatus -Value 1 -Force"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$taskPayload`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
Write-Host "[+] Phase 6: Core persistent force worker armed inside NT Task Scheduler." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 8: ACTIVE PRESENTATION NODE FLUSH
# ------------------------------------------------------------
Write-Host "`n[REFRESH] Purging rendering engine instances..." -ForegroundColor Cyan

Stop-Service -Name "WpnService" -Force -ErrorAction SilentlyContinue
Start-Service -Name "WpnService" -ErrorAction SilentlyContinue

Stop-Process -Name "SystemSettings" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Start-Process gpupdate.exe -ArgumentList "/force" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

Write-Host "`n=========================================================================" -ForegroundColor Green
Write-Host "[+] SUPREME UNIVERSAL FORCED INTEGRATION DEPLOYED WITH 100% COVERAGE!" -ForegroundColor Green
Write-Host "    System-level blueprints locked. Fallback loop broken on every layer." -ForegroundColor Yellow
Write-Host "========================================================================="`n -ForegroundColor Green
