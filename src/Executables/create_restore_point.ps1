# Z-LAG OS - bounded pre-optimization restore point.
# Re-enables VSS/System Protection when a previous Z-LAG run left it disabled.
$ErrorActionPreference = 'Continue'

$drive = $env:SystemDrive + '\'
foreach ($service in @('VSS', 'swprv')) {
    & sc.exe config $service start= demand 2>$null | Out-Null
}
foreach ($service in @('VSS', 'swprv')) {
    & sc.exe start $service 2>$null | Out-Null
}

try {
    $restoreKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    New-Item -Path $restoreKey -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $restoreKey -Name 'SystemRestorePointCreationFrequency' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    Enable-ComputerRestore -Drive $drive -ErrorAction Stop
} catch {
    Write-Output ('[Z-LAG] System Protection could not be enabled: ' + $_.Exception.Message)
    exit 0
}

$job = Start-Job -ScriptBlock {
    param($targetDrive)
    $ErrorActionPreference = 'Stop'
    Checkpoint-Computer -Description 'Z-LAG OS - Pre-Optimization' -RestorePointType MODIFY_SETTINGS | Out-Null
    return 'CREATED'
} -ArgumentList $drive

if (Wait-Job -Job $job -Timeout 45) {
    $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
    if ($result -contains 'CREATED') {
        Write-Output '[Z-LAG] Restore point created.'
    } else {
        Write-Output '[Z-LAG] Restore point unavailable; optimization will continue.'
    }
} else {
    Stop-Job -Job $job -ErrorAction SilentlyContinue
    Write-Output '[Z-LAG] Restore point timed out after 45 seconds; optimization will continue.'
}
Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
exit 0
