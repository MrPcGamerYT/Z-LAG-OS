# ==============================================================================
# Z-LAG OS - Microsoft Edge COMPLETE Remover (production / idempotent / no hang)
# ------------------------------------------------------------------------------
# Removes the Edge BROWSER completely while PRESERVING the WebView2 Runtime, so
# WebView2-dependent apps (Discord, Teams v2, Office, etc.) never break.
#
# Based on the proven technique from ShadowWhisperer/Remove-MS-Edge:
#   * official setup.exe --uninstall --system-level --force-uninstall
#   * Edge AppX + provisioned-package removal (WebView2/WebExperience excluded)
#   * Edge update services / scheduled tasks / registry cleanup
#     (WebView2 update-client GUID {F3017226-FE2A-4295-8BDF-00C3A9A7E4C5} kept)
#   * shortcut + start-tile removal from EVERY user profile
#
# Safe to run as Administrator / TrustedInstaller. Never pauses or prompts.
# Logs to C:\ProgramData\Z-LAG-OS\remove_edge.log
# ==============================================================================

$ErrorActionPreference = "Continue"

# --- 0. Persistent logging + elevation guard ---
$logDir = Join-Path $env:ProgramData "Z-LAG-OS"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "remove_edge.log"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output "[Z-LAG-EDGE] ERROR: Administrator privileges required. Run from an elevated session."
    exit 1
}

function Log([string]$m) {
    $line = "[Z-LAG-EDGE] $m"
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

$EdgeBrowserGuid = "{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"   # Edge browser update client (removed)
$WebView2Guid     = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"   # WebView2 update client (kept)

# --- 1. Close Edge browser processes (msedgewebview2.exe untouched) ---
Log "Closing Edge browser processes (WebView2 untouched)..."
foreach ($p in @("msedge","msedge_proxy","MicrosoftEdgeUpdate","MicrosoftEdgeCP","MicrosoftEdgeSH")) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}

# --- 2. Run the official uninstaller(s) ---
Log "Running official Edge uninstaller if available..."
$setupCandidates = @()
foreach ($base in @("$env:ProgramFiles(x86)\Microsoft\Edge\Application",
                    "$env:ProgramFiles\Microsoft\Edge\Application",
                    "$env:ProgramFiles(x86)\Microsoft\EdgeCore",
                    "$env:ProgramFiles\Microsoft\EdgeCore")) {
    if (Test-Path $base) {
        $setupCandidates += Get-ChildItem -Path $base -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue
    }
}
$ranUninstaller = $false
foreach ($setup in ($setupCandidates | Select-Object -Unique)) {
    if (Test-Path $setup.FullName) {
        Log ("  uninstaller: " + $setup.FullName)
        Start-Process -FilePath $setup.FullName -ArgumentList "--uninstall","--system-level","--force-uninstall","--verbose-logging" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        $ranUninstaller = $true
    }
}
if (-not $ranUninstaller) { Log "  No official uninstaller found - proceeding with manual removal." }
Start-Sleep -Seconds 2

# --- 3. Remove Edge AppX + provisioned packages (WebView2/WebExperience kept) ---
Log "Removing Edge AppX packages (WebView2/WebExperience preserved)..."
$edgeAppx = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*Edge*" -and $_.Name -notlike "*WebView*" -and $_.Name -notlike "*WebExperience*"
}
foreach ($pkg in $edgeAppx) {
    Log ("  appx: " + $pkg.PackageFullName)
    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
}
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {
    $_.DisplayName -like "*Edge*" -and $_.DisplayName -notlike "*WebView*" -and $_.DisplayName -notlike "*WebExperience*"
} | ForEach-Object {
    Log ("  deprovision: " + $_.DisplayName)
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
}

# --- 4. Remove Edge update services ---
Log "Removing Edge update services..."
foreach ($svc in @("edgeupdate","edgeupdatem","MicrosoftEdgeElevationService")) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        sc.exe delete $svc | Out-Null
    }
}

# --- 5. Remove Edge scheduled tasks ---
Log "Removing Edge scheduled tasks..."
foreach ($t in @("MicrosoftEdgeUpdateTaskMachineCore","MicrosoftEdgeUpdateTaskMachineUA")) {
    schtasks.exe /delete /tn $t /f 2>$null | Out-Null
}
foreach ($dir in @("$env:SystemRoot\System32\Tasks\Microsoft\Windows\EdgeUpdate",
                   "$env:SystemRoot\System32\Tasks\Microsoft\Windows\Edge")) {
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- 6. Delete Edge files/folders (EdgeWebView PRESERVED) ---
Log "Deleting Edge files/folders (WebView2 folder preserved)..."
foreach ($dir in @(
    "$env:ProgramFiles(x86)\Microsoft\Edge",
    "$env:ProgramFiles\Microsoft\Edge",
    "$env:ProgramFiles(x86)\Microsoft\EdgeCore",
    "$env:ProgramFiles\Microsoft\EdgeCore",
    "$env:ProgramFiles(x86)\Microsoft\EdgeUpdate",
    "$env:ProgramFiles\Microsoft\EdgeUpdate",
    "$env:ProgramFiles(x86)\Microsoft\Temp",
    "$env:ProgramData\Microsoft\EdgeUpdate"
)) {
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
}

# Legacy EdgeHTML leftovers (SystemApps)
foreach ($d in Get-ChildItem "$env:SystemRoot\SystemApps" -Directory -Filter "Microsoft.MicrosoftEdge*" -ErrorAction SilentlyContinue) {
    & takeown.exe /f $d.FullName /r /d y 2>$null | Out-Null
    & icacls.exe $d.FullName /grant administrators:F /t 2>$null | Out-Null
    Remove-Item $d.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($f in @("$env:SystemRoot\System32\MicrosoftEdgeCP.exe",
                 "$env:SystemRoot\System32\MicrosoftEdgeSH.exe",
                 "$env:SystemRoot\System32\MicrosoftEdge.exe")) {
    if (Test-Path $f) {
        & takeown.exe /f $f 2>$null | Out-Null
        & icacls.exe $f /grant administrators:F 2>$null | Out-Null
        Remove-Item $f -Force -ErrorAction SilentlyContinue
    }
}

# --- 7. Remove shortcuts from EVERY user profile ---
Log "Removing Edge shortcuts for all users (Desktop / Start Menu / Taskbar / Quick Launch)..."
$shortcutNames = @("Microsoft Edge.lnk","edge.lnk","Microsoft Edge (1).lnk")
$profileRoots = @()
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -ErrorAction SilentlyContinue | ForEach-Object {
    $pi = (Get-ItemProperty -Path $_.PSPath -Name "ProfileImagePath" -ErrorAction SilentlyContinue).ProfileImagePath
    if ($pi -and (Test-Path $pi)) { $profileRoots += $pi }
}
$profileRoots += $env:PUBLIC
$profileRoots = $profileRoots | Where-Object { $_ } | Select-Object -Unique

foreach ($root in $profileRoots) {
    foreach ($lnk in $shortcutNames) {
        foreach ($p in @(
            (Join-Path $root "Desktop"),
            (Join-Path $root "AppData\Roaming\Microsoft\Windows\Start Menu\Programs"),
            (Join-Path $root "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch"),
            (Join-Path $root "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")
        )) {
            $target = Join-Path $p $lnk
            if (Test-Path $target) { Remove-Item $target -Force -ErrorAction SilentlyContinue }
        }
    }
    # Clear the per-user Start tile cache so the Start Menu rebuilds without Edge
    $startBin = Join-Path $root "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start.bin"
    if (Test-Path $startBin) { Remove-Item $startBin -Force -ErrorAction SilentlyContinue }
}
# All-users Start Menu
foreach ($lnk in $shortcutNames) {
    Remove-Item (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\$lnk") -Force -ErrorAction SilentlyContinue
}

# --- 8. Registry cleanup (WebView2 client GUID preserved) ---
Log "Cleaning registry (WebView2 entries preserved)..."
foreach ($k in @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge",
    "HKLM:\SOFTWARE\Microsoft\Edge",
    "HKCU:\Software\Microsoft\Edge",
    "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
    "HKLM:\SOFTWARE\WOW6432Node\Clients\StartMenuInternet\Microsoft Edge",
    "HKLM:\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge",
    "HKCU:\Software\Clients\StartMenuInternet\Microsoft Edge",
    "HKCR:\MSEdgeHTM","HKCR:\MSEdgePDF","HKCR:\MSEdgeMHT","HKCR:\MSEdgeHTML",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe"
)) {
    Remove-Item $k -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-ItemProperty -Path "HKLM:\SOFTWARE\RegisteredApplications" -Name "Microsoft Edge" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\RegisteredApplications" -Name "Microsoft Edge" -ErrorAction SilentlyContinue

# Remove ONLY the Edge browser update client - keep the WebView2 runtime client.
foreach ($hive in @("HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients",
                    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients")) {
    $client = Join-Path $hive $EdgeBrowserGuid
    if (Test-Path $client) { Remove-Item $client -Recurse -Force -ErrorAction SilentlyContinue }
}

# Block Edge from reinstalling itself through Windows Update.
$eu = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"
if (-not (Test-Path $eu)) { New-Item -Path $eu -Force | Out-Null }
Set-ItemProperty -Path $eu -Name "DoNotUpdateToEdgeWithChromium" -Value 1 -Type DWord -Force

# Marker so later steps / diagnostics know Edge was removed.
$zk = "HKLM:\SOFTWARE\Z-LAG-OS"
if (-not (Test-Path $zk)) { New-Item -Path $zk -Force | Out-Null }
Set-ItemProperty -Path $zk -Name "EdgeRemoved" -Value 1 -Type DWord -Force

Log "Microsoft Edge removed. WebView2 runtime preserved."
