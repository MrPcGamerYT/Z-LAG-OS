<#
.SYNOPSIS
    Z LAG OS Wallpaper & Lock Screen Setter – Safe, Permanent & MDM Enforced
.DESCRIPTION
    - Sets desktop wallpaper via C# SystemParametersInfo and MDM CSP
    - Sets lock screen via WinRT API and MDM CSP
    - Disables Windows Spotlight permanently
    - Creates a SYSTEM-level startup task for absolute persistence
.NOTES
    Must be run as Administrator.
#>

#Requires -RunAsAdministrator

# ------------------------------------------------------------
# 1. Locate and Copy Source Images
# ------------------------------------------------------------
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
@($destFolder, $screenFolder) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item $_ -ItemType Directory -Force | Out-Null }
}

$destDesktop = Join-Path $destFolder "Z-LAG_Desktop.png"
$destLock    = Join-Path $screenFolder "Z-LAG_Lock.png"

Copy-Item $desktopSource $destDesktop -Force
Copy-Item $lockSource $destLock -Force
Write-Host "Images secured in system directories." -ForegroundColor Green

# ------------------------------------------------------------
# 2. DESKTOP WALLPAPER – SystemParametersInfo & User Hives
# ------------------------------------------------------------
Write-Host "`n[DESKTOP] Injecting desktop wallpaper..." -ForegroundColor Cyan

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
# 3. ENTERPRISE MDM CSP (The Ultimate Override)
# ------------------------------------------------------------
Write-Host "`n[MDM CSP] Locking images at the Enterprise level..." -ForegroundColor Cyan

$cspReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (-not (Test-Path $cspReg)) { New-Item -Path $cspReg -Force | Out-Null }

# Force Lock Screen & Desktop via MDM
New-ItemProperty -Path $cspReg -Name "LockScreenImagePath" -Value $destLock -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $cspReg -Name "LockScreenImageStatus" -Value 1 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $cspReg -Name "DesktopImagePath" -Value $destDesktop -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $cspReg -Name "DesktopImageStatus" -Value 1 -PropertyType DWORD -Force | Out-Null

# ------------------------------------------------------------
# 4. LOCK SCREEN – WinRT API & Standard Registry Fallbacks
# ------------------------------------------------------------
Write-Host "`n[LOCK SCREEN] Executing WinRT and standard policies..." -ForegroundColor Cyan

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' })[0]
function AwaitWinRT($task, $type) {
    $asTask = $asTaskGeneric.MakeGenericMethod($type)
    $netTask = $asTask.Invoke($null, @($task))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}

try {
    [Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null
    [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
    $file = AwaitWinRT ([Windows.Storage.StorageFile]::GetFileFromPathAsync($destLock)) ([Windows.Storage.StorageFile])
    $result = AwaitWinRT ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($file)) ([Windows.System.UserProfile.SetImageResult])
} catch {}

$policyReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $policyReg)) { New-Item -Path $policyReg -Force | Out-Null }
Set-ItemProperty -Path $policyReg -Name LockScreenImage -Value $destLock -Type String -Force
Set-ItemProperty -Path $policyReg -Name NoChangingLockScreen -Value 1 -Type DWord -Force

# ------------------------------------------------------------
# 5. SPOTLIGHT KILLER
# ------------------------------------------------------------
Write-Host "`n[SPOTLIGHT] Neutralizing Windows Spotlight..." -ForegroundColor DarkGray
@(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CloudContent"
) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -Path $_ -Force | Out-Null }
    Set-ItemProperty -Path $_ -Name DisableWindowsSpotlightFeatures -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $_ -Name DisableThirdPartySuggestions -Value 1 -Type DWord -Force
}

# ------------------------------------------------------------
# 6. SYSTEM-LEVEL PERSISTENCE (Scheduled Task)
# ------------------------------------------------------------
Write-Host "`n[PERSISTENCE] Securing boot routine..." -ForegroundColor DarkGray
$taskName = "Z-LAG-LockScreen-Enforce"
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    # The payload re-asserts the CSP and Policy registry keys silently on boot
    $payload = "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' -Name LockScreenImageStatus -Value 1 -Force; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value '$destLock' -Force"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$payload`""
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
}

# ------------------------------------------------------------
# 7. EXPLORER RESTART
# ------------------------------------------------------------
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ Z-LAG OS DEPLOYMENT COMPLETE." -ForegroundColor Green
Write-Host "   Press Win+L to verify lock screen." -ForegroundColor Yellow
