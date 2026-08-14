# Z-LAG OS - per-interface TCP NoDelay + ACK frequency (competitive latency)
# Applies TCPNoDelay and TcpAckFrequency to EVERY network interface so the
# tweaks take effect on first boot without relying on the global key alone.
$ErrorActionPreference = "Continue"

Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
    $guid = $_.InterfaceGuid
    if (-not $guid) { return }
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $path -Name "TCPNoDelay"      -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
}
