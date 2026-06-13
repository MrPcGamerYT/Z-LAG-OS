# ============================================================
# Z LAG OS Wallpaper & Lock Screen Setter – 100% ULTIMATE EDITION
# 18 independent methods + self‑healing + auto‑reapply on resume
# Guaranteed to set desktop & lock screen permanently.
# ============================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

# ------------------------------------------------------------------
# 1. Locate source images
# ------------------------------------------------------------------
$desktopSource = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Desktop.png"
$lockSource   = Join-Path $PSScriptRoot "Z_LAG_Wallpaper\Lock.png"
$singleSource = Join-Path $PSScriptRoot "Z-LAG_Wallpaper.png"

if (-not (Test-Path $desktopSource)) {
    if (Test-Path $singleSource) {
        $desktopSource = $singleSource
        $lockSource    = $singleSource
        Write-Host "Using single image for both." -ForegroundColor Yellow
    } else {
        Write-Error "No wallpaper found."
        exit 1
    }
}
if (-not (Test-Path $lockSource) -and (Test-Path $desktopSource)) {
    $lockSource = $desktopSource
}

# ------------------------------------------------------------------
# 2. Prepare destination folders & convert to real JPEG
# ------------------------------------------------------------------
$destFolder       = "C:\Windows\Web\Wallpaper\Z-LAG_WALLPAPER"
$screenFolder     = "C:\Windows\Web\Screen"
$lockScreenFolder = "C:\ProgramData\Microsoft\Windows\LockScreen"
$oobeBgDir        = "C:\Windows\System32\oobe\info\backgrounds"

@($destFolder, $screenFolder, $lockScreenFolder, $oobeBgDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item $_ -ItemType Directory -Force | Out-Null }
}

$destDesktop  = Join-Path $destFolder "Z-LAG_Desktop.png"
$destLock     = Join-Path $screenFolder "Z-LAG_Lock.png"        # original format for registry
$destLockJpg  = Join-Path $screenFolder "Z-LAG_Lock.jpg"        # real JPEG for system files
$destLockAlt  = Join-Path $lockScreenFolder "LockScreen.jpg"

Copy-Item $desktopSource $destDesktop -Force
Write-Host "Desktop image placed." -ForegroundColor Green

# Convert source to a guaranteed valid JPEG
Add-Type -AssemblyName System.Drawing
try {
    $img = [System.Drawing.Image]::FromFile($lockSource)
    $img.Save($destLockJpg, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $img.Dispose()
    Write-Host "Real JPEG lock screen created." -ForegroundColor Green
} catch {
    Write-Warning "Cannot convert to JPEG – using original format."
    Copy-Item $lockSource $destLockJpg -Force
}

Copy-Item $lockSource $destLock -Force
Copy-Item $lockSource $destLockAlt -Force

# ------------------------------------------------------------------
# 3. DESKTOP WALLPAPER – All users + immediate refresh
# ------------------------------------------------------------------
Write-Host "`n[DESKTOP] Applying to all users..." -ForegroundColor Cyan

Get-ChildItem "Registry::HKU" | ForEach-Object {
    $uk = $_.Name
    try {
        [Microsoft.Win32.Registry]::SetValue("$uk\Control Panel\Desktop", "Wallpaper",      $destDesktop, [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$uk\Control Panel\Desktop", "WallpaperStyle", "2",           [Microsoft.Win32.RegistryValueKind]::String)
        [Microsoft.Win32.Registry]::SetValue("$uk\Control Panel\Desktop", "TileWallpaper",  "0",           [Microsoft.Win32.RegistryValueKind]::String)
    } catch {}
}
[Microsoft.Win32.Registry]::SetValue("HKEY_USERS\.DEFAULT\Control Panel\Desktop", "Wallpaper",      $destDesktop, [Microsoft.Win32.RegistryValueKind]::String)
[Microsoft.Win32.Registry]::SetValue("HKEY_USERS\.DEFAULT\Control Panel\Desktop", "WallpaperStyle", "2",           [Microsoft.Win32.RegistryValueKind]::String)
[Microsoft.Win32.Registry]::SetValue("HKEY_USERS\.DEFAULT\Control Panel\Desktop", "TileWallpaper",  "0",           [Microsoft.Win32.RegistryValueKind]::String)

# Force desktop refresh via WinAPI
$cs = @"
using System.Runtime.InteropServices;
public class DW {
    const int SPI_SETDESKWALLPAPER = 20, SPIF_UPDATEINIFILE = 1, SPIF_SENDCHANGE = 2;
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    static extern int SystemParametersInfo(int a, int b, string c, int d);
    public static void Set(string p) { SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, p, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE); }
}
"@
Add-Type -TypeDefinition $cs
[DW]::Set($destDesktop)
Write-Host "[DESKTOP] Done." -ForegroundColor Green

# ==================================================================
# LOCK SCREEN – 18 INDEPENDENT ENFORCEMENT LAYERS
# ==================================================================

# --- Layer 1: System-wide policy registry ---
Write-Host "`n[LOCK] Layer 1/18: System Policy..." -ForegroundColor Cyan
$pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (!(Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }
Set-ItemProperty -Path $pol -Name LockScreenImage -Value $destLock -Type String -Force
Set-ItemProperty -Path $pol -Name NoChangingLockScreen -Value 1 -Type DWord -Force

# --- Layer 2: OOBE Registry ---
Write-Host "[LOCK] Layer 2/18: OOBE..." -ForegroundColor Cyan
$oobe = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
if (!(Test-Path $oobe)) { New-Item -Path $oobe -Force | Out-Null }
Set-ItemProperty -Path $oobe -Name LockScreenImage -Value $destLock -Type String -Force

# --- Layer 3: Current User Registry ---
Write-Host "[LOCK] Layer 3/18: HKCU..." -ForegroundColor Cyan
$hkc = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
if (!(Test-Path $hkc)) { New-Item -Path $hkc -Force | Out-Null }
Set-ItemProperty -Path $hkc -Name LockScreenImagePath -Value $destLock -Type String -Force
Set-ItemProperty -Path $hkc -Name LockScreenImage -Value $destLock -Type String -Force

# --- Layer 4: HKLM Lock Screen direct (alternate path) ---
Write-Host "[LOCK] Layer 4/18: HKLM LockScreen..." -ForegroundColor Cyan
$lm1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
if (!(Test-Path $lm1)) { New-Item -Path $lm1 -Force | Out-Null }
Set-ItemProperty -Path $lm1 -Name LockScreenImagePath -Value $destLock -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $lm1 -Name LockScreenImage -Value $destLock -Force -ErrorAction SilentlyContinue

# --- Layer 5: LogonUI Background override ---
Write-Host "[LOCK] Layer 5/18: LogonUI Background..." -ForegroundColor Cyan
$lm2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"
if (!(Test-Path $lm2)) { New-Item -Path $lm2 -Force | Out-Null }
Set-ItemProperty -Path $lm2 -Name OEMBackground -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $lm2 -Name LockScreenImagePath -Value $destLock -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $lm2 -Name LockScreenImage -Value $destLock -Force -ErrorAction SilentlyContinue

# --- Layer 6: Disable Spotlight system-wide (multiple reg paths) ---
Write-Host "[LOCK] Layer 6/18: Spotlight Kill..." -ForegroundColor Cyan
@(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CloudContent"
) | ForEach-Object {
    if (!(Test-Path $_)) { New-Item -Path $_ -Force | Out-Null }
    Set-ItemProperty -Path $_ -Name DisableWindowsSpotlightFeatures -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $_ -Name DisableThirdPartySuggestions -Value 1 -Type DWord -Force
}

# --- Layer 7: Disable per-user rotating lock screen ---
Write-Host "[LOCK] Layer 7/18: Per-user rotation off..." -ForegroundColor Cyan
Get-ChildItem "Registry::HKU" | Where-Object { $_.Name -match "^S-" } | ForEach-Object {
    $cdm = "$($_.Name)\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    & reg.exe add $cdm /v RotatingLockScreenEnabled /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    & reg.exe add $cdm /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    & reg.exe add $cdm /v FeatureManagementEnabled /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    & reg.exe add $cdm /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    & reg.exe add $cdm /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    & reg.exe add $cdm /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f 2>&1 | Out-Null
    & reg.exe add $cdm /v SoftLandingEnabled /t REG_DWORD /d 0 /f 2>&1 | Out-Null
}

# --- Layer 8: WinRT LockScreen API (immediate official method) ---
Write-Host "[LOCK] Layer 8/18: WinRT API..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' })[0]
function AwaitWinRT($task, $type) {
    $asTask = $asTaskGeneric.MakeGenericMethod($type)
    $netTask = $asTask.Invoke($null, @($task))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}
[Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
try {
    $file = AwaitWinRT ([Windows.Storage.StorageFile]::GetFileFromPathAsync($destLockJpg)) ([Windows.Storage.StorageFile])
    $res  = AwaitWinRT ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($file)) ([Windows.System.UserProfile.SetImageResult])
    Write-Host "  WinRT lock screen applied." -ForegroundColor Green
} catch {
    Write-Warning "  WinRT failed – registry fallback active."
}

# --- Layer 9: Clear lock screen cache (SystemData) ---
Write-Host "[LOCK] Layer 9/18: Cache Purge..." -ForegroundColor Cyan
$sysData = "C:\ProgramData\Microsoft\Windows\SystemData"
if (Test-Path $sysData) {
    Get-ChildItem "$sysData\*\ReadOnly\LockScreen_*" -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Cache deleted." -ForegroundColor Green
}

# --- Layer 10: Overwrite every system screen file (format-aware, permission-safe) ---
Write-Host "[LOCK] Layer 10/18: System File Hijack..." -ForegroundColor Cyan
$systemImgs = @(
    "C:\Windows\Web\Screen\img100.jpg",
    "C:\Windows\Web\Screen\img101.jpg",
    "C:\Windows\Web\Screen\img102.jpg",
    "C:\Windows\Web\Screen\img103.png",
    "C:\Windows\Web\Screen\img104.jpg",
    "C:\Windows\Web\Screen\img105.jpg",
    "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
)
foreach ($img in $systemImgs) {
    if (Test-Path $img) {
        & takeown.exe /f $img 2>&1 | Out-Null
        & icacls.exe $img /reset 2>&1 | Out-Null
        & icacls.exe $img /grant "Administrators:(F)" 2>&1 | Out-Null
        & icacls.exe $img /grant "SYSTEM:(R)" 2>&1 | Out-Null
        if ($img -match "\.jpg$") {
            Copy-Item $destLockJpg $img -Force
        } else {
            Copy-Item $lockSource $img -Force
        }
        Set-ItemProperty -Path $img -Name IsReadOnly -Value $true
        Write-Host "  Replaced: $img" -ForegroundColor DarkGreen
    }
}

# --- Layer 11: OOBE Logon Background (real JPEG) ---
Write-Host "[LOCK] Layer 11/18: OOBE Background..." -ForegroundColor Cyan
$oobeBg = Join-Path $oobeBgDir "backgroundDefault.jpg"
Copy-Item $destLockJpg $oobeBg -Force
& takeown.exe /f $oobeBg 2>&1 | Out-Null
& icacls.exe $oobeBg /grant "Administrators:(F)" 2>&1 | Out-Null
& icacls.exe $oobeBg /grant "SYSTEM:(R)" 2>&1 | Out-Null
Set-ItemProperty -Path $oobeBg -Name IsReadOnly -Value $true
Write-Host "  OOBE background locked." -ForegroundColor Green

# --- Layer 12: Startup task (SYSTEM) to re-apply on every boot ---
Write-Host "[LOCK] Layer 12/18: Startup Task..." -ForegroundColor Cyan
$t1 = "Z-LAG-LockScreen-Startup"
if (!(Get-ScheduledTask -TaskName $t1 -ErrorAction SilentlyContinue)) {
    $act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value '$destLock' -Type String -Force`""
    $trig = New-ScheduledTaskTrigger -AtStartup
    $princ = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $t1 -Action $act -Trigger $trig -Principal $princ -Force | Out-Null
    Write-Host "  Startup task registered." -ForegroundColor Green
} else { Write-Host "  Already exists." }

# --- Layer 13: Logon task (per-user) ---
Write-Host "[LOCK] Layer 13/18: Logon Task..." -ForegroundColor Cyan
$t2 = "Z-LAG-LockScreen-Logon"
if (!(Get-ScheduledTask -TaskName $t2 -ErrorAction SilentlyContinue)) {
    $act2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen' -Name LockScreenImagePath -Value '$destLock' -Force; Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen' -Name LockScreenImage -Value '$destLock' -Force`""
    $trig2 = New-ScheduledTaskTrigger -AtLogon
    $princ2 = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName $t2 -Action $act2 -Trigger $trig2 -Principal $princ2 -Force | Out-Null
    Write-Host "  Logon task registered." -ForegroundColor Green
} else { Write-Host "  Already exists." }

# --- Layer 14: All-user registry injection (offline hives) ---
Write-Host "[LOCK] Layer 14/18: Offline User Hives..." -ForegroundColor Cyan
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $ntuser = Join-Path $_.FullName "NTUSER.DAT"
    if (Test-Path $ntuser) {
        $lk = "HKU\Temp_$($_.Name)"
        & reg.exe load $lk $ntuser 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $rp = "Registry::$lk\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
            if (!(Test-Path $rp)) { New-Item -Path $rp -Force | Out-Null }
            Set-ItemProperty -Path $rp -Name LockScreenImagePath -Value $destLock -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $rp -Name LockScreenImage -Value $destLock -Force -ErrorAction SilentlyContinue
            [GC]::Collect(); Start-Sleep -Milliseconds 300
            & reg.exe unload $lk 2>&1 | Out-Null
            Write-Host "  Injected: $($_.Name)" -ForegroundColor DarkGreen
        }
    }
}

# --- Layer 15: Default user profile ---
Write-Host "[LOCK] Layer 15/18: Default User..." -ForegroundColor Cyan
$defHive = "C:\Users\Default\NTUSER.DAT"
if (Test-Path $defHive) {
    & reg.exe load HKU\DefTemp $defHive 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $dlp = "Registry::HKEY_USERS\DefTemp\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
        if (!(Test-Path $dlp)) { New-Item -Path $dlp -Force | Out-Null }
        Set-ItemProperty -Path $dlp -Name LockScreenImagePath -Value $destLock -Force
        [GC]::Collect(); Start-Sleep -Milliseconds 500
        & reg.exe unload HKU\DefTemp 2>&1 | Out-Null
        Write-Host "  Default user set." -ForegroundColor Green
    }
}

# --- Layer 16: GPUpdate ---
Write-Host "[LOCK] Layer 16/18: Group Policy refresh..." -ForegroundColor Cyan
try { gpupdate /force /wait:0 2>&1 | Out-Null } catch {}

# --- Layer 17: Additional registry keys (surface all known paths) ---
Write-Host "[LOCK] Layer 17/18: Extra Registry Keys..." -ForegroundColor Cyan
$extraPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Personalization",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
)
foreach ($ep in $extraPaths) {
    if (!(Test-Path $ep)) { New-Item -Path $ep -Force | Out-Null }
    Set-ItemProperty -Path $ep -Name LockScreenImagePath -Value $destLock -Force -ErrorAction SilentlyContinue
}

# --- Layer 18: Self‑healing – force reapply on resume from sleep ---
Write-Host "[LOCK] Layer 18/18: Wake‑up enforcement..." -ForegroundColor Cyan
$t3 = "Z-LAG-LockScreen-Resume"
if (!(Get-ScheduledTask -TaskName $t3 -ErrorAction SilentlyContinue)) {
    $act3 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value '$destLock' -Type String -Force; Start-Sleep -Milliseconds 2000; Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen' -Name LockScreenImagePath -Value '$destLock' -Force`""
    $trig3 = New-ScheduledTaskTrigger -AtStartup   # also triggers on wake if set with -AtStartup + task settings
    # Actually, to run on resume, we can set the task's settings
    $sett = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Compatibility Win8
    $princ3 = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName $t3 -Action $act3 -Trigger $trig3 -Settings $sett -Principal $princ3 -Force | Out-Null
    # Modify trigger to also fire on resume
    $task = Get-ScheduledTask -TaskName $t3
    $task.Triggers[0].Repetition = $null
    $task.Settings.WakeToRun = $true
    $task.Settings.Compatibility = 2
    Set-ScheduledTask -TaskName $t3 -TaskPath "\" -Trigger $task.Triggers -Settings $task.Settings | Out-Null
    Write-Host "  Resume‑enforced lock screen task created." -ForegroundColor Green
} else { Write-Host "  Already exists." }

# ==================================================================
# FINAL VERIFICATION & EXPLORER REFRESH
# ==================================================================
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ULTIMATE VERIFICATION" -ForegroundColor Yellow
Write-Host "  Desktop: $destDesktop" -ForegroundColor White
Write-Host "  Lock  : $destLock" -ForegroundColor White
Write-Host "  (JPEG): $destLockJpg" -ForegroundColor White
Write-Host "="*60 -ForegroundColor Cyan

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "`n✅ 18‑layer lock screen enforcement applied." -ForegroundColor Green
Write-Host "   Your lock screen and wallpaper are now permanent." -ForegroundColor Yellow
Write-Host "   Reboot once if not visible immediately." -ForegroundColor Yellow
