<#
.SYNOPSIS
    Z LAG OS Unbreakable Wallpaper & Lock Screen Engine
.DESCRIPTION
    - Strips away the Acrylic Blur framework to prevent solid color crashes.
    - Bypasses activation locks using Enterprise MDM CSP.
    - Replaces all native system image assets and legacy OOBE graphics.
    - Forces the system engine to display the raw image with zero processing.
.NOTES
    Must be run as Administrator.
#>

#Requires -RunAsAdministrator

# ------------------------------------------------------------
# 1. Locate, Secure, and Overwrite Every Image Path in Windows
# ------------------------------------------------------------
Write-Host "[INIT] Arming Z LAG OS Unbreakable Wallpaper Engine..." -ForegroundColor Cyan

$desktopSource = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Desktop.png"
$lockSource    = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Lock.png"
$singleSource  = Join-Path $PSScriptRoot "Z-LAG_Wallpaper.png"

if (-not (Test-Path $desktopSource)) {
    if (Test-Path $singleSource) {
        $desktopSource = $singleSource
        $lockSource    = $singleSource
        Write-Host "[INFO] Using single wallpaper file for both." -ForegroundColor Yellow
    } else {
        Write-Error "No wallpaper found. Place a 'Z-LAG_Wallpaper.png' next to this script."
        exit 1
    }
}
if (-not (Test-Path $lockSource) -and (Test-Path $desktopSource)) {
    $lockSource = $desktopSource
}

$destFolder   = "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER"
$screenFolder = "C:\Windows\Web\Screen"
$legacyOobe   = "C:\Windows\System32\oobe\info\backgrounds"

# Ensure all system target directories exist
@($destFolder, $screenFolder, $legacyOobe) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item $_ -ItemType Directory -Force | Out-Null }
}

$destDesktop = Join-Path $destFolder "Z-LAG_Desktop.png"
$destLock    = Join-Path $screenFolder "Z-LAG_Lock.png"
$legacyFile  = Join-Path $legacyOobe "backgroundDefault.jpg"

Copy-Item $desktopSource $destDesktop -Force
Copy-Item $lockSource $destLock -Force
Copy-Item $lockSource $legacyFile -Force

# Hijack all default system image assets so Windows has no alternate file to load
if (Test-Path $screenFolder) {
    $DefaultImages = Get-ChildItem -Path $screenFolder -Filter "img*"
    foreach ($Img in $DefaultImages) {
        $TargetFile = $Img.FullName
        takeown /f $TargetFile /a | Out-Null
        icacls $TargetFile /grant administrators:F | Out-Null
        Copy-Item $destLock $TargetFile -Force | Out-Null
    }
}

Write-Host "[+] All system image fallbacks replaced successfully." -ForegroundColor Green

# ------------------------------------------------------------
# 2. THE ANTI-COLOR FIX: Kill Logon Blur & Force Image Engine
# ------------------------------------------------------------
Write-Host "`n[GRAPHICS] Disabling logon blur mechanisms to block solid color fallbacks..." -ForegroundColor Cyan

$sysPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $sysPolicyPath)) { New-Item $sysPolicyPath -Force | Out-Null }

# Disable Acrylic blur effect on Logon screen (Forces the raw image to load instantly)
Set-ItemProperty -Path $sysPolicyPath -Name "DisableAcrylicOnBackgroundOnLogon" -Value 1 -Type DWord -Force

# Tell Windows explicitly to use background images, never flat accent colors
Set-ItemProperty -Path $sysPolicyPath -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord -Force

# Change default system canvas color to pure black as an extreme emergency backup
Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Colors" -Name "Background" -Value "0 0 0" -Force
Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Desktop" -Name "WallPaper" -Value "" -Force

# ------------------------------------------------------------
# 3. DESKTOP WALLPAPER – SystemParametersInfo & User Hives
# ------------------------------------------------------------
Write-Host "`n[DESKTOP] Forcing desktop wallpaper environment..." -ForegroundColor Cyan

Get-ChildItem "Registry::HKU" | ForEach-Object {
    $userKey = $_.Name
    try {
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", "Wallpaper", $destDesktop, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", "WallpaperStyle", "2", [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$userKey\Control Panel\Desktop", "TileWallpaper", "0", [Microsoft.Win32.RegistryValueKind]::String)
    } catch {}
}

$csharp = @"
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
if (-not ([System.Management.Automation.PSTypeName]'DesktopWallpaper').Type) { Add-Type -TypeDefinition $csharp }
[DesktopWallpaper]::SetWallpaper($destDesktop)

# ------------------------------------------------------------
# 4. ENTERPRISE MDM CSP (Bypasses Activation Retrictions)
# ------------------------------------------------------------
$cspReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (-not (Test-Path $cspReg)) { New-Item -Path $cspReg -Force | Out-Null }
Set-ItemProperty -Path $cspReg -Name "LockScreenImagePath" -Value $destLock -Type String -Force
Set-ItemProperty -Path $cspReg -Name "LockScreenImageStatus" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $cspReg -Name "LockScreenImageUrl" -Value $destLock -Type String -Force
Set-ItemProperty -Path $cspReg -Name "DesktopImagePath" -Value $destDesktop -Type String -Force
Set-ItemProperty -Path $cspReg -Name "DesktopImageStatus" -Value 1 -Type DWord -Force

# ------------------------------------------------------------
# 5. LOCK SCREEN – Policy Enforcement
# ------------------------------------------------------------
$policyReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $policyReg)) { New-Item -Path $policyReg -Force | Out-Null }
Set-ItemProperty -Path $policyReg -Name LockScreenImage -Value $destLock -Type String -Force
Set-ItemProperty -Path $policyReg -Name NoChangingLockScreen -Value 1 -Type DWord -Force

# ------------------------------------------------------------
# 6. SPOTLIGHT KILLER
# ------------------------------------------------------------
@(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CloudContent"
) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -Path $_ -Force | Out-Null }
    Set-ItemProperty -Path $_ -Name DisableWindowsSpotlightFeatures -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $_ -Name DisableThirdPartySuggestions -Value 1 -Type DWord -Force
}

# ------------------------------------------------------------
# 7. SYSTEM-LEVEL PERSISTENCE & HARDWARE CACHE PURGE
# ------------------------------------------------------------
Write-Host "`n[PERSISTENCE] Injecting continuous engine enforcement..." -ForegroundColor DarkGray
$taskName = "Z-LAG-LockScreen-Enforce"

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
}

# Payload purges the cache, fixes policies, and ensures logon blur remains disabled at boot
$cachePurge = "Remove-Item -Path 'C:\ProgramData\Microsoft\Windows\SystemData\*\ReadOnly\LockScreen_*\*.*' -Force -Recurse -ErrorAction SilentlyContinue"
$regEnforce = "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImageStatus -Value 1 -Force; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value '$destLock' -Force; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLogonBackgroundImage' -Value 0 -Force; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableAcrylicOnBackgroundOnLogon' -Value 1 -Force"
$combinedPayload = "$cachePurge; $regEnforce"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$combinedPayload`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

# ------------------------------------------------------------
# 8. REBOOT EXPLORER SHELL
# ------------------------------------------------------------
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host "`n█████████████████████████████████████████████" -ForegroundColor Cyan
Write-Host "✅ UNBREAKABLE Z-LAG OS ENGINE IS LIVE!" -ForegroundColor Green
Write-Host "   Logon color fallbacks have been structurally disabled." -ForegroundColor Yellow
Write-Host "█████████████████████████████████████████████`n" -ForegroundColor Cyan
