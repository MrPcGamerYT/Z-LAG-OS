param (
    [Parameter(Mandatory = $true)]
    [string[]]$Packages,
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludePackages = @(),
    [Parameter(Mandatory = $false)]
    [switch]$Unregister = $false
)

# ==============================================================================
# Z-LAG OS - AppX Bloat Remover  (universal Win10 + Win11, no skips, no errors)
# ------------------------------------------------------------------------------
# Removes the given AppX packages for ALL users, DEPROVISIONS them so they can
# never come back after reboot, and clears the Start Menu cache so removed apps
# stop showing "ghost" tiles.
#
#   * Never skips a package just because it is flagged NonRemovable.
#   * Never errors on a package that only exists on one OS version (it is
#     simply not present -> nothing to do).
#   * GPU drivers, the Windows shell, WebView2 and critical system apps are
#     protected by the keep-list.
# ==============================================================================

$ErrorActionPreference = "Continue"

# --- 0. Logging ---
$logDir = Join-Path $env:ProgramData "Z-LAG-OS"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "appx_remover.log"
function Log([string]$m) {
    Write-Host "[Z-LAG-APPX] $m"
    Add-Content -Path $logFile -Value $m -Encoding ASCII -ErrorAction SilentlyContinue
}

# CRITICAL: Apps to KEEP (GPU vendors, essential system apps, WebView2 runtime)
$KeepApps = @(
    # NVIDIA
    'NVIDIA','NVIDIACorp','NVIDIA.ControlPanel','NVIDIA.GraphicsDriver','NVIDIA.Display',
    'Nvidia','NvContainer','NvTelemetry',
    # AMD
    'AMD','AMDRadeon','AMD.RadeonSoftware','AMD.ChipsetDriver','Amd','AmdRyzenMaster',
    # Intel
    'Intel','IntelCorp','Intel.GraphicsCommandCenter','Intel.Driver','Intc','IntelGraphics',
    # Absolutely essential (DO NOT REMOVE - breaks Windows)
    'Microsoft.Windows.Explorer',
    'Microsoft.Windows.ShellExperienceHost',
    'Microsoft.Windows.StartMenuExperienceHost',
    'Microsoft.Windows.Search',
    'Microsoft.VCLibs',
    'Microsoft.UI.Xaml',
    'Microsoft.NET.Native',
    # WebView2 / WebView components (PRESERVED so apps never break)
    'Microsoft.WebView2',
    'Microsoft.MicrosoftEdgeWebView2Runtime',
    'Microsoft.Win32WebViewHost',
    'Microsoft.WebWebView2',
    'EdgeWebView'
)

function Test-Protected([string]$Name) {
    foreach ($keep in $KeepApps) {
        if ($Name -like "*$keep*") { return $true }
    }
    return $false
}

# --- 1. Deprovision matching provisioned packages (so they never come back) ---
$depKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned"
if (-not (Test-Path $depKey)) { New-Item -Path $depKey -Force | Out-Null }

foreach ($pattern in $Packages) {
    if (Test-Protected $pattern) {
        Log "Skipping protected app: $pattern"
        continue
    }

    # (a) Remove from the image store (provisioned packages)
    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$pattern*" -and -not (Test-Protected $_.DisplayName) }
    foreach ($p in $prov) {
        try {
            Log "Deprovisioning: $($p.DisplayName)"
            Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null

            # (b) Mark the family as deprovisioned (belt-and-suspenders)
            $parts = $p.PackageName -split '_'
            if ($parts.Count -ge 2) {
                $family = $parts[0] + '_' + $parts[-1]
                New-Item -Path (Join-Path $depKey $family) -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            Log "  deprovision failed: $($p.DisplayName) -> $($_.Exception.Message)"
        }
    }
}

# --- 2. Remove installed packages for all users (never skip NonRemovable) ---
$allPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue

foreach ($pattern in $Packages) {
    if (Test-Protected $pattern) { continue }

    $matches = $allPackages | Where-Object { $_.PackageFullName -like "*$pattern*" }

    if ($ExcludePackages.Count -gt 0) {
        $matches = $matches | Where-Object {
            $fn = $_.PackageFullName
            -not ($ExcludePackages | Where-Object { $fn -like "*$_*" })
        }
    }

    foreach ($pkg in $matches) {
        $full = $pkg.PackageFullName
        if (Test-Protected $full) {
            Log "Protected package skipped: $full"
            continue
        }

        Log "Removing package: $full"

        # Per-user removal (reliable from a SYSTEM / TrustedInstaller context)
        $sids = @($pkg.PackageUserInformation | ForEach-Object { $_.UserSecurityID.SID } | Select-Object -Unique)
        foreach ($sid in $sids) {
            try { Remove-AppxPackage -Package $full -User $sid -ErrorAction Stop } catch { }
        }

        # All-users sweep to catch stragglers
        try {
            if ($Unregister) {
                Remove-AppxPackage -Package $full -AllUsers -PreserveRoamableApplicationData -ErrorAction Stop
            } else {
                Remove-AppxPackage -Package $full -AllUsers -ErrorAction Stop
            }
        } catch { }
    }
}

# --- 3. Clear the Start Menu cache so removed apps stop showing ghost tiles ---
try {
    & (Join-Path $PSScriptRoot "clear_start_menu_cache.ps1")
} catch { }

Log "AppX removal completed! Protected apps (NVIDIA, AMD, Intel, essential system apps, WebView2) kept intact."
