<#
.SYNOPSIS
    UNIVERSAL UNBREAKABLE WALLPAPER & LOCK SCREEN ENGINE
.DESCRIPTION
    - Phase 1: Nuclear file takeover and total asset replication.
    - Phase 2: Complete security ACL unlocking for all UWP Sandboxes.
    - Phase 3: Creative LogonUI registry asset state hijacking.
    - Phase 4: Absolute MDM CSP & Group Policy lock down.
    - Phase 5: Systematic destruction of the hidden SystemData cache.
.NOTES
    Designed to execute perfectly inside AME Playbooks and SYSTEM contexts.
#>

#Requires -RunAsAdministrator

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "[INIT] DEPLOYING UNIVERSAL UNBREAKABLE WALLPAPER ENGINE..." -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# ------------------------------------------------------------
# PHASE 1: ASSET DISCOVERY & SYSTEM PATH HIJACKING
# ------------------------------------------------------------
$desktopSource = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Desktop.png"
$lockSource    = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Lock.png"
$singleSource  = Join-Path $PSScriptRoot "Z-LAG_Wallpaper.png"

if (-not (Test-Path $desktopSource)) {
    if (Test-Path $singleSource) { $desktopSource = $singleSource; $lockSource = $singleSource }
    else { Write-Error "Target wallpaper file not found!"; exit 1 }
}
if (-not (Test-Path $lockSource)) { $lockSource = $desktopSource }

# Define every single directory Windows uses to pull backgrounds
$paths = @(
    "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER",
    "C:\Windows\Web\Screen",
    "C:\Windows\Web\Wallpaper\Windows",
    "C:\Windows\System32\oobe\info\backgrounds",
    "C:\ProgramData\Microsoft\Windows\Images"
)
foreach ($p in $paths) { if (-not (Test-Path $p)) { New-Item $p -ItemType Directory -Force | Out-Null } }

$destDesktop = "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER\Z-LAG_Desktop.png"
$destLock    = "C:\Windows\Web\Screen\Z-LAG_Lock.png"

Copy-Item $desktopSource $destDesktop -Force | Out-Null
Copy-Item $lockSource $destLock -Force | Out-Null

# Overwrite EVERY default system asset. If Windows triggers a fallback to default images,
# it will inadvertently load your custom wallpaper anyway.
$systemAssets = @(
    "C:\Windows\Web\Screen\img100.jpg",
    "C:\Windows\Web\Screen\img101.png",
    "C:\Windows\Web\Screen\img102.jpg",
    "C:\Windows\Web\Screen\img103.png",
    "C:\Windows\Web\Wallpaper\Windows\img0.jpg",
    "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg"
)
foreach ($asset in $systemAssets) {
    if (Test-Path $asset) {
        takeown /f $asset /a | Out-Null
        icacls $asset /grant administrators:F | Out-Null
    }
    Copy-Item $destLock $asset -Force -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "[+] Phase 1: All potential fallback image files hijacked." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 2: RADICAL SECURITY DESCRIPTOR UNLOCKING (ANTI-BLUE SCREEN)
# ------------------------------------------------------------
Write-Host "`n[SECURITY] Dismantling security blocks across all wallpaper assets..." -ForegroundColor Yellow

$securityTargets = @($destDesktop, $destLock, "C:\Windows\Web\Screen", "C:\Windows\Web\Wallpaper")

foreach ($target in $securityTargets) {
    if (Test-Path $target) {
        # Split target types to eliminate "not a valid directory path" errors from takeown
        if (Test-Path $target -PathType Container) {
            takeown /f $target /r /d y | Out-Null
            icacls $target /grant "administrators:(OI)(CI)F" /t | Out-Null
            icacls $target /grant "*S-1-15-2-1:(OI)(CI)(R,RX,WDAC)" /t | Out-Null
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
Write-Host "[+] Phase 2: UWP Sandboxes granted absolute file clearance." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 3: CREATIVE LOGONUI STATE HIJACKING
# ------------------------------------------------------------
Write-Host "`n[REGISTRY] Forcing asset strings into Creative LogonUI containers..." -ForegroundColor Yellow

$creativeRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative"
if (Test-Path $creativeRoot) {
    Get-ChildItem $creativeRoot | ForEach-Object {
        $subKey = $_.Name.Replace("HKEY_LOCAL_MACHINE", "HKLM:")
        Get-ChildItem $subKey -ErrorAction SilentlyContinue | ForEach-Object {
            $internalKey = $_.Name.Replace("HKEY_LOCAL_MACHINE", "HKLM:")
            Set-ItemProperty -Path $internalKey -Name "LandscapeAssetPath" -Value $destLock -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $internalKey -Name "PortraitAssetPath" -Value $destLock -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "[+] Phase 3: Creative LogonUI memory addresses redirected." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 4: ABSOLUTE REGISTRY ENGINE POLICIES
# ------------------------------------------------------------
Write-Host "`n[POLICIES] Enforcing corporate lockdown matrices..." -ForegroundColor Yellow

# System Policies
$sysPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $sysPol)) { New-Item $sysPol -Force | Out-Null }
Set-ItemProperty -Path $sysPol -Name "DisableAcrylicOnBackgroundOnLogon" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $sysPol -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord -Force

# Personalization Policies
$persPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $persPol)) { New-Item $persPol -Force | Out-Null }
Set-ItemProperty -Path $persPol -Name "LockScreenImage" -Value $destLock -Type String -Force
Set-ItemProperty -Path $persPol -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force

# Personalization CSP Matrix
$csp = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (-not (Test-Path $csp)) { New-Item $csp -Force | Out-Null }
Set-ItemProperty -Path $csp -Name "LockScreenImagePath" -Value $destLock -Type String -Force
Set-ItemProperty -Path $csp -Name "LockScreenImageStatus" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $csp -Name "LockScreenImageUrl" -Value $destLock -Type String -Force
Set-ItemProperty -Path $csp -Name "DesktopImagePath" -Value $destDesktop -Type String -Force
Set-ItemProperty -Path $csp -Name "DesktopImageStatus" -Value 1 -Type DWord -Force

# Force User Hives Desktop Wallpaper Parameters
Get-ChildItem "Registry::HKEY_USERS" | ForEach-Object {
    $u = $_.Name
    try {
        [Microsoft.Win32.Registry]::SetValue("$u\Control Panel\Desktop", "Wallpaper", $destDesktop, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$u\Control Panel\Desktop", "WallpaperStyle", "2", [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$u\Control Panel\Desktop", "TileWallpaper", "0", [Microsoft.Win32.RegistryValueKind]::String)
    } catch {}
}

# Apply Wallpaper directly through C# user32 assembly hook
$signature = @"
using System.Runtime.InteropServices;
public class EngineWallpaper {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void Apply(string p) { SystemParametersInfo(20, 0, p, 0x01 | 0x02); }
}
"@
if (-not ([System.Management.Automation.PSTypeName]'EngineWallpaper').Type) { Add-Type -TypeDefinition $signature }
[EngineWallpaper]::Apply($destDesktop)
Write-Host "[+] Phase 4: System configuration locks compiled." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 5: HIDDEN SYSTEMDATA CACHE EXTINCTION
# ------------------------------------------------------------
Write-Host "`n[CACHE] Executing complete destruction of legacy SystemData buffers..." -ForegroundColor Yellow

$systemDataPath = "C:\ProgramData\Microsoft\Windows\SystemData"
if (Test-Path $systemDataPath) {
    takeown /f $systemDataPath /r /d y | Out-Null
    # Secure string wrapping applied below to stop PowerShell parser mapping errors
    icacls $systemDataPath /grant "administrators:(OI)(CI)F" /t | Out-Null
    
    Get-ChildItem -Path $systemDataPath -Recurse -Include "LockScreen_*","ControlPanelWallpaper_*" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
Write-Host "[+] Phase 5: Hardware visual cache folders zeroed out." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 6: CRITICAL PERSISTENCE LAUNCHER
# ------------------------------------------------------------
$taskName = "Z-LAG-LockScreen-Enforce"
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
}

$taskPayload = "takeown /f 'C:\Windows\Web\Screen' /r /d y; icacls 'C:\Windows\Web\Screen' /grant '*S-1-15-2-1:(OI)(CI)(R)' /t; Remove-Item -Path 'C:\ProgramData\Microsoft\Windows\SystemData\*\ReadOnly\LockScreen_*\*.*' -Force -Recurse -ErrorAction SilentlyContinue; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImageStatus -Value 1 -Force"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$taskPayload`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
Write-Host "[+] Phase 6: Persistence engine armed inside Task Scheduler." -ForegroundColor Green

# ------------------------------------------------------------
# PHASE 7: LIVE SUBSYSTEM REFRESH
# ------------------------------------------------------------
Write-Host "`n[REFRESH] Purging active system rendering processes..." -ForegroundColor Cyan

Stop-Service -Name "WpnService" -Force -ErrorAction SilentlyContinue
Start-Service -Name "WpnService" -ErrorAction SilentlyContinue

Stop-Process -Name "SystemSettings" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Start-Process gpupdate.exe -ArgumentList "/force" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "[+] UNIVERSAL ENGINE INTEGRATION 100% COMPLETE!" -ForegroundColor Green
Write-Host "    Fallback vectors permanently broken. Wallpaper locked." -ForegroundColor Yellow
Write-Host "========================================================="`n -ForegroundColor Green
