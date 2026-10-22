param([string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts")
$ErrorActionPreference = 'Continue'

# ==============================================================================
# Windows Update blocking (task 13_blockUpdates.yml)
# ----------------------------------------------------------------------------
# IMPORTANT (fixes: "kept Defender protections take a while to load"):
#   download.microsoft.com is the CDN that serves Windows Defender signature
#   AND engine definitions. Blocking it (as older versions of this playbook
#   did) starved Defender of updates, so Real-Time Protection appeared broken
#   and slow to start on machines that KEEPT Defender. It is therefore
#   NEVER blocked here anymore. Only the Windows Update endpoints themselves
#   are blocked.
# ==============================================================================
$entries = @(
    "0.0.0.0 update.microsoft.com",
    "0.0.0.0 windowsupdate.microsoft.com",
    "0.0.0.0 download.windowsupdate.com",
    "0.0.0.0 windowsupdate.com"
)
. (Join-Path $PSScriptRoot 'hosts_file_utils.ps1')
$blockedHosts = @($entries | ForEach-Object { ($_ -split '\s+')[1] })
$defenderEndpoints = @('download.microsoft.com', 'defender.microsoft.com', 'www.microsoft.com', 'ctldl.microsoft.com')
try {
    $changed = Update-ZLagHostsFile -Path $HostsPath -BlockedHosts $blockedHosts -UnblockedHosts $defenderEndpoints
    Write-Output ("[Z-LAG] Hosts entries verified; file changed: " + $changed)
} catch {
    Write-Error ("[Z-LAG] Hosts update failed; original file preserved: " + $_.Exception.Message)
    exit 1
}
