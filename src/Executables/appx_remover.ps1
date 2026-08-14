param (
    [Parameter(Mandatory = $true)]
    [string[]]$Packages,
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludePackages = @(),
    [Parameter(Mandatory = $false)]
    [switch]$Unregister = $false
)

# ==============================================================================
# Z-LAG OS - AppX Bloat Remover (production / deprovisioning / first-run proof)
# ------------------------------------------------------------------------------
# Removes AppX packages for ALL users AND deprovisions them so they can never
# come back for new users (the old "skip NonRemovable" behaviour is what left
# bloat behind on the first run). NVIDIA / AMD / Intel / essential system apps
# and the WebView2 runtime are always protected.
# ==============================================================================

$ErrorActionPreference = "Continue"

# --- 0. Persistent logging ---
$logDir = Join-Path $env:ProgramData "Z-LAG-OS"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "appx_remover.log"

function Log([string]$m) {
    $line = "[Z-LAG-APPX] $m"
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
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
$deprovisioned = 0
foreach ($pattern in $Packages) {
    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$pattern*" -and -not (Test-Protected $_.DisplayName) }
    foreach ($p in $prov) {
        Log ("Deprovisioning: " + $p.DisplayName)
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null
            $deprovisioned++
        } catch {
            Log ("  deprovision failed: " + $p.DisplayName + " -> " + $_.Exception.Message)
        }
    }
}
Log ("Deprovisioned " + $deprovisioned + " inbox packages.")

# --- 2. Remove installed packages for all users ---
#     Deprovision first, then per-user removal (reliable from a SYSTEM /
#     TrustedInstaller context where -AllUsers alone often fails with
#     0x80070002 "DeStage operation ... failed"), then an -AllUsers sweep.
$removed = 0
$failed  = 0
$allPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue

foreach ($pattern in $Packages) {
    if (Test-Protected $pattern) {
        Log ("Skipping protected app: " + $pattern)
        continue
    }

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
            Log ("Protected package skipped: " + $full)
            continue
        }

        if ($pkg.NonRemovable -eq 1) {
            Log ("NonRemovable flagged (attempting removal): " + $full)
        } else {
            Log ("Removing package: " + $full)
        }

        # (a) Per-user removal - most reliable when running as SYSTEM.
        $userSids = @($pkg.PackageUserInformation | ForEach-Object { $_.UserSecurityID.SID } | Select-Object -Unique)
        foreach ($sid in $userSids) {
            try {
                Remove-AppxPackage -Package $full -User $sid -ErrorAction Stop
            } catch {
                # 0x80073CF1 = package already gone; anything else is worth logging.
                if ($_.Exception.Message -notmatch "80073CF1|not found") {
                    Log ("  per-user removal failed: " + $full + " -> " + $_.Exception.Message.Split([Environment]::NewLine)[0])
                }
            }
        }

        # (b) All-users sweep to catch stragglers.
        try {
            if ($Unregister) {
                Remove-AppxPackage -Package $full -AllUsers -PreserveRoamableApplicationData -ErrorAction Stop
            } else {
                Remove-AppxPackage -Package $full -AllUsers -ErrorAction Stop
            }
        } catch {
            # 0x80073CF1 = already gone; 0x80070002 = de-stage missing (commonly
            # means the per-user removal above already cleaned it). Only flag if
            # the package still exists afterwards.
        }

        # (c) Verify and count.
        $stillThere = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.PackageFullName -eq $full }
        if ($stillThere) {
            $failed++
            Log ("  STILL PRESENT after removal: " + $full)
        } else {
            $removed++
        }
    }
}

Log ("Removed " + $removed + " packages, " + $failed + " still present.")
Log "AppX removal completed! Protected apps (NVIDIA, AMD, Intel, essential system apps, WebView2) kept intact."

