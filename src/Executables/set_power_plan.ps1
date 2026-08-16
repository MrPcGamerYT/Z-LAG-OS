# Z-LAG OS - bounded Ultimate/High Performance power configuration.
$ErrorActionPreference = 'Continue'
$ultimateTemplate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$highPerformance = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'

Write-Output '[Z-LAG] Creating/activating performance power plan...'
$activeGuid = $null
$duplicateOutput = (& powercfg.exe -duplicatescheme $ultimateTemplate 2>$null | Out-String)
$guidMatch = [regex]::Match($duplicateOutput, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
if ($guidMatch.Success) { $activeGuid = $guidMatch.Value }

if (-not $activeGuid) {
    $schemes = (& powercfg.exe -list 2>$null | Out-String)
    if ($schemes -match [regex]::Escape($highPerformance)) { $activeGuid = $highPerformance }
}

if ($activeGuid) {
    & powercfg.exe -setactive $activeGuid 2>$null | Out-Null
    if ($activeGuid -ne $highPerformance) {
        & powercfg.exe -changename $activeGuid 'Maximum FPS' 'Optimized for zero-lag gaming' 2>$null | Out-Null
        Write-Output '[Z-LAG] Maximum FPS (Ultimate Performance) activated.'
    } else {
        Write-Output '[Z-LAG] High Performance fallback activated.'
    }
} else {
    Write-Output '[Z-LAG] Performance scheme creation unavailable; tuning the current scheme.'
}

Write-Output '[Z-LAG] Applying power scheme fine-tuning (AC + DC)...'
foreach ($scope in @('setacvalueindex', 'setdcvalueindex')) {
    foreach ($setting in @(
        @('SUB_PROCESSOR','PROCTHROTTLEMIN','100'),
        @('SUB_PROCESSOR','PROCTHROTTLEMAX','100'),
        @('SUB_PROCESSOR','PERFBOOSTMODE','2'),
        @('SUB_DISK','DISKIDLE','0'),
        @('SUB_VIDEO','VIDEOIDLE','0'),
        @('SUB_SLEEP','STANDBYIDLE','0')
    )) {
        & powercfg.exe ('-' + $scope) SCHEME_CURRENT $setting[0] $setting[1] $setting[2] 2>$null | Out-Null
    }
}
& powercfg.exe -setactive SCHEME_CURRENT 2>$null | Out-Null
& powercfg.exe -hibernate off 2>$null | Out-Null

# Missing BCDEdit values are expected on many systems. Capture every stream so
# harmless "Element not found" text does not appear as a playbook failure.
Write-Output '[Z-LAG] Applying BCDEdit timing tweaks...'
$null = & bcdedit.exe /deletevalue useplatformclock 2>&1
$null = & bcdedit.exe /set tscsyncpolicy Enhanced 2>&1
$null = & bcdedit.exe /set disabledynamictick yes 2>&1

Write-Output '[Z-LAG] Power plan and timing optimizations complete.'
exit 0
