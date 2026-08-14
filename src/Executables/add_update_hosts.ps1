param([string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts")
$entries = @(
    "0.0.0.0 update.microsoft.com",
    "0.0.0.0 windowsupdate.microsoft.com",
    "0.0.0.0 download.microsoft.com",
    "0.0.0.0 download.windowsupdate.com",
    "0.0.0.0 windowsupdate.com"
)
foreach ($entry in $entries) {
    if (-not (Select-String -Path $HostsPath -Pattern $entry -Quiet)) {
        Add-Content -Path $HostsPath -Value $entry
    }
}