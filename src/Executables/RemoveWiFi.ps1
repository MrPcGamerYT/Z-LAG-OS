# ==============================================================================
# Z-LAG OS - Safe Wi-Fi / WLAN Adapter Disabler
# ==============================================================================

Write-Output "[Z-LAG] Disabling Wi-Fi adapters and services for zero network latency overhead..."

# 1. Disable Wi-Fi Network Adapters
if (Get-Command Disable-NetAdapter -ErrorAction SilentlyContinue) {
    Get-NetAdapter -ErrorAction SilentlyContinue | 
        Where-Object { $_.PhysicalMediaType -match "Wireless" -or $_.Name -match "Wi-Fi|Wireless" } | 
        Disable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue
}

# 2. Stop and Disable WLAN Services
$WifiServices = @("WlanSvc", "vwififlt", "vwifibus", "vwifimp")

foreach ($Svc in $WifiServices) {
    Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# 3. Disable Wireless PnP Hardware Devices
if (Get-Command Disable-PnpDevice -ErrorAction SilentlyContinue) {
    Get-PnpDevice -Class "Net" -ErrorAction SilentlyContinue | 
        Where-Object { $_.FriendlyName -match "Wi-Fi|Wireless|802.11|WLAN" } | 
        Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Output "[Z-LAG] Wi-Fi services and adapters successfully disabled."
