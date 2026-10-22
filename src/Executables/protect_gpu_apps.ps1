# ==============================================================================
# Z-LAG OS - GPU Vendor App Protection Engine (NVIDIA App / AMD / Intel)
# ------------------------------------------------------------------------------
# WHY THIS SCRIPT EXISTS (user-reported: "NVIDIA App not working"):
#   The new NVIDIA App (GeForce Experience successor) is a WinUI3 MSIX package.
#   The old playbook applied GLOBAL background bans to every packaged app
#   (LetAppsRunInBackground=2 machine policy + GlobalUserDisabled=1 user switch).
#   That killed the NVIDIA App's background container, so its in-game overlay
#   and background features stopped working. It also starved the Windows
#   Security (SecHealthUI) app of its background pre-load, which made
#   "Defender protection" appear broken/slow when Defender was kept.
#
# WHAT IT DOES:
#   1. Removes the GLOBAL background kill switches (machine policy + user
#      switch) so no single policy can ever ban a specific GPU app again.
#   2. Builds a per-app background policy for EVERY installed package:
#        * GPU vendor packages (NVIDIA / AMD / Intel - publisher or name match)
#          and the Windows Security app get Disabled=0  (background allowed)
#        * every other package gets Disabled=1          (background banned)
#      Same footprint as before, but the GPU apps keep their overlay +
#      background container alive.
#   3. Applies the policy to every real user profile (HKU per-SID), not just
#      the current session.
#
# Idempotent. Never prompts. Logs to C:\ProgramData\Z-LAG-OS\gpu_app_protection.log
# ==============================================================================
$ErrorActionPreference = 'Continue'

$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir 'gpu_app_protection.log'

function Log {
    param([string]$m)
    $line = '[{0}] [Z-LAG-GPU] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Log 'ERROR: Administrator privileges required.'
    exit 1
}

# --- 1. Vendor + protection detection ------------------------------------------
# A package is PROTECTED when its publisher or name belongs to a GPU vendor,
# or it is part of the Windows Security / packaged-app runtime stack.
# Publisher is the strongest signal (avoids false positives on names).
function Test-ZLagProtectedPackage {
    param([object]$Pkg)
    $name = [string]$Pkg.Name + ' ' + [string]$Pkg.PackageFamilyName + ' ' + [string]$Pkg.DisplayName
    $publisher = [string]$Pkg.Publisher
    if ($publisher -match 'nvidia|advanced micro devices|\bamd\b|intel corporation') { return $true }
    if ($name -match 'nvidia|amd|intel') { return $true }
    # Windows Security UI (Defender status app) - its background pre-load must
    # keep working so the Windows Security app opens instantly.
    if ($name -match 'sechealthui|windowsdefender') { return $true }
    # MSIX runtime frameworks (no background activity anyway; never ban them).
    if ($name -match 'windowsappruntime|vclibs|ui\.xaml|net\.native|desktopappinstaller') { return $true }
    return $false
}

# --- 2. Resolve every real user profile (SID + hive path) ----------------------
$profiles = @()
$profileListRoot = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
if (Test-Path $profileListRoot) {
    foreach ($key in (Get-ChildItem -Path $profileListRoot -ErrorAction SilentlyContinue)) {
        $sid = $key.PSChildName
        # Real interactive user SIDs look like S-1-5-21-...-1001 (or 1000+).
        if ($sid -notmatch '^S-1-5-21-') { continue }
        $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
        if (-not $props -or -not $props.ProfileImagePath) { continue }
        $profiles += [pscustomobject]@{
            Sid  = $sid
            Path = [Environment]::ExpandEnvironmentVariables($props.ProfileImagePath)
        }
    }
}
if ($profiles.Count -eq 0) {
    Log 'WARNING: no real user profiles found; applying policy to HKLM-only scope.'
}
Log ('Resolved ' + $profiles.Count + ' user profile(s).')

# --- 3. Remove the GLOBAL background kill switches ------------------------------
# Machine policy (wins over every per-app key - the old bug):
$bgPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
if (Test-Path $bgPolicyPath) {
    Remove-ItemProperty -Path $bgPolicyPath -Name 'LetAppsRunInBackground' -Force -ErrorAction SilentlyContinue
}
Log 'Global LetAppsRunInBackground machine policy removed.'

# User-level master switch (per profile + current admin hive):
$bgRootTemplate = 'Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
$hives = @()
foreach ($p in $profiles) {
    $hiveRoot = 'Registry::HKEY_USERS\' + $p.Sid
    if (Test-Path $hiveRoot) { $hives += $hiveRoot }
}
# Also cover a live HKCU (when this runs in an admin session of a real user).
$hives += 'Registry::HKEY_CURRENT_USER'

foreach ($hive in ($hives | Select-Object -Unique)) {
    $bgRoot = $hive + '\' + $bgRootTemplate
    if (-not (Test-Path $bgRoot)) {
        New-Item -Path $bgRoot -Force -ErrorAction SilentlyContinue | Out-Null
    }
    # Remove the master switch so per-app keys decide individually.
    Remove-ItemProperty -Path $bgRoot -Name 'GlobalUserDisabled' -Force -ErrorAction SilentlyContinue
}
Log 'Global GlobalUserDisabled switches removed (per-app policy takes over).'

# --- 4. Per-app background policy ------------------------------------------------
$protectedCount = 0
$bannedCount = 0
$packages = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_ -and $_.PackageFamilyName })

foreach ($hive in ($hives | Select-Object -Unique)) {
    $bgRoot = $hive + '\' + $bgRootTemplate
    if (-not (Test-Path $bgRoot)) {
        New-Item -Path $bgRoot -Force -ErrorAction SilentlyContinue | Out-Null
    }

    foreach ($pkg in $packages) {
        $family = $pkg.PackageFamilyName
        if (-not $family) { continue }
        $appPath = Join-Path $bgRoot $family
        if (-not (Test-Path $appPath)) {
            New-Item -Path $appPath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        if (Test-ZLagProtectedPackage -Pkg $pkg) {
            Set-ItemProperty -Path $appPath -Name 'Disabled' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            $protectedCount++
        } else {
            Set-ItemProperty -Path $appPath -Name 'Disabled' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $bannedCount++
        }
    }
}
Log ('Per-app background policy applied: ' + $protectedCount + ' protected (GPU/Security), ' + $bannedCount + ' banned entries.')

# Log the protected set once for diagnostics.
foreach ($pkg in ($packages | Where-Object { Test-ZLagProtectedPackage -Pkg $_ } | Select-Object -Unique -Property PackageFamilyName)) {
    Log ('  protected: ' + $pkg.PackageFamilyName)
}

Log 'GPU vendor app protection applied. NVIDIA App (and AMD/Intel panels) keep background + overlay access.'
exit 0
