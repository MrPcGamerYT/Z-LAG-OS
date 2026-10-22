param(
    [string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
)
$ErrorActionPreference = 'Continue'

$entries = @(
    "0.0.0.0 vortex.data.microsoft.com",
    "0.0.0.0 vortex-win.data.microsoft.com",
    "0.0.0.0 telecommand.telemetry.microsoft.com",
    "0.0.0.0 oca.telemetry.microsoft.com",
    "0.0.0.0 sqm.telemetry.microsoft.com",
    "0.0.0.0 watson.telemetry.microsoft.com",
    "0.0.0.0 redir.metaservices.microsoft.com",
    "0.0.0.0 choice.microsoft.com",
    "0.0.0.0 df.telemetry.microsoft.com",
    "0.0.0.0 telemetry.microsoft.com",
    "0.0.0.0 settings-sandbox.data.microsoft.com",
    "0.0.0.0 settings-win.data.microsoft.com"
)

. (Join-Path $PSScriptRoot 'hosts_file_utils.ps1')
$blockedHosts = @($entries | ForEach-Object { ($_ -split '\s+')[1] })
$defenderEndpoints = @()
try {
    $changed = Update-ZLagHostsFile -Path $HostsPath -BlockedHosts $blockedHosts -UnblockedHosts $defenderEndpoints
    Write-Output ("[Z-LAG] Hosts entries verified; file changed: " + $changed)
} catch {
    Write-Error ("[Z-LAG] Hosts update failed; original file preserved: " + $_.Exception.Message)
    exit 1
}
