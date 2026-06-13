param(
    [string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
)
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

foreach ($entry in $entries) {
    if (-not (Select-String -Path $HostsPath -Pattern $entry -Quiet)) {
        Add-Content -Path $HostsPath -Value $entry
    }
}