# ==============================================================================
# Z-LAG OS - Safe Bluetooth Service & Device Disabler
# ==============================================================================

Write-Output "[Z-LAG] Disabling Bluetooth services and devices for zero background footprint..."

# 1. Stop and Disable Bluetooth Services
$BthServices = @("bthserv", "BTAGService", "bthpriv", "BluetoothUserService")

foreach ($Svc in $BthServices) {
    Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# 2. Disable all Bluetooth Hardware PnP Devices
if (Get-Command Disable-PnpDevice -ErrorAction SilentlyContinue) {
    Get-PnpDevice -Class "Bluetooth" -ErrorAction SilentlyContinue | 
        Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Output "[Z-LAG] Bluetooth services and devices successfully disabled."
