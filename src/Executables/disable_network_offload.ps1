# Apply only standard, advertised adapter settings. Keep checksum offload on.
# Disabling interrupt moderation can raise CPU/DPC load; benchmark on target NIC.
# No adapter restart during apply: settings may require a reboot to take effect.
$ErrorActionPreference = 'Continue'
$failed = $false
foreach ($adapter in @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' })) {
    try {
        $properties = @(Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction Stop)
        foreach ($keyword in @('*InterruptModeration', '*EEE')) {
            $property = $properties | Where-Object { $_.RegistryKeyword -eq $keyword } | Select-Object -First 1
            if (-not $property -or '0' -notin @($property.ValidRegistryValues)) {
                Write-Host ("[Z-LAG] NIC setting not advertised; skipping " + $adapter.Name + ' ' + $keyword)
                continue
            }
            Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword $keyword -RegistryValue 0 -NoRestart -ErrorAction Stop
        }
        if (Get-Command Disable-NetAdapterPowerManagement -ErrorAction SilentlyContinue) {
            Disable-NetAdapterPowerManagement -Name $adapter.Name -NoRestart -ErrorAction Stop
        }
        Write-Host ("[Z-LAG] NIC preferences applied without restarting " + $adapter.Name + '; reboot may be required.')
    } catch {
        Write-Warning ("[Z-LAG] NIC tuning incomplete for " + $adapter.Name + ': ' + $_.Exception.Message)
        $failed = $true
    }
}
if ($failed) { exit 1 }
