# TCP-only preferences; these do not tune UDP or guarantee lower game latency.
$ErrorActionPreference = 'Continue'
$root = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
$failed = $false
foreach ($adapter in @(Get-NetAdapter -ErrorAction Stop)) {
    $interfaceGuid = [Guid]::Empty
    if (-not [Guid]::TryParse([string]$adapter.InterfaceGuid, [ref]$interfaceGuid)) {
        Write-Warning ("[Z-LAG] Invalid interface GUID; skipping " + $adapter.Name)
        continue
    }
    # Windows uses brace-wrapped GUID keys. A bare GUID creates an unused key.
    $path = Join-Path $root $interfaceGuid.ToString('B')
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning ("[Z-LAG] No existing TCP/IP interface key; skipping " + $adapter.Name)
        continue
    }
    try {
        New-ItemProperty -LiteralPath $path -Name TcpAckFrequency -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -LiteralPath $path -Name TCPNoDelay -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning ("[Z-LAG] TCP interface tuning failed for " + $adapter.Name + ': ' + $_.Exception.Message)
        $failed = $true
    }
}
if ($failed) { exit 1 }
