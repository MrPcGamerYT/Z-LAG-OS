# ==============================================================================
# Z-LAG OS - Bluetooth option-specific service and device disabler
# Runs only when the user explicitly selects Bluetooth Disable.
# ==============================================================================

Write-Output "[Z-LAG] Disabling Bluetooth services, pairing brokers and devices..."

# Remove obsolete artifacts from the short-lived older implementation.
Unregister-ScheduledTask -TaskName 'ZLAG-RepairBluetooth' -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$env:ProgramData\Z-LAG-OS\repair_bluetooth.ps1" -Force -ErrorAction SilentlyContinue

# These dependencies are excluded from the global process floor. Only this
# explicit Bluetooth Disable option is allowed to turn them off.
$BthServices = @(
    "bthserv", "BTAGService", "bthpriv", "BluetoothUserService",
    "BthAvctpSvc", "bthHFSrv", "CDPSvc", "CDPUserSvc", "NcbService",
    "DeviceAssociationBrokerSvc", "DevicePickerUserSvc", "DevicesFlowUserSvc"
)

$serviceRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
foreach ($family in $BthServices) {
    Get-Service -Name "$family*" -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Path $serviceRoot -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -eq $family -or $_.PSChildName -like ($family + '_*') } |
        ForEach-Object {
            New-ItemProperty -Path $_.PSPath -Name Start -Value 4 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
        }
}

# Disable all Bluetooth hardware only for the opt-in removal path.
if (Get-Command Disable-PnpDevice -ErrorAction SilentlyContinue) {
    Get-PnpDevice -Class "Bluetooth" -ErrorAction SilentlyContinue |
        Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Output "[Z-LAG] Bluetooth was disabled by explicit user choice."
