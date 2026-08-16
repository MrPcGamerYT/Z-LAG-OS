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
        # PROCTHROTTLEMIN stays LOW on purpose: locking the minimum processor
        # state at 100% keeps the CPU at max clocks even at idle, heat-soaks
        # the machine and causes thermal throttling (FPS drops) mid-game.
        # 5% minimum + 100% maximum + aggressive boost gives the same peak
        # clocks with far more thermal headroom for long gaming sessions.
        @('SUB_PROCESSOR','PROCTHROTTLEMIN','5'),
        @('SUB_PROCESSOR','PROCTHROTTLEMAX','100'),
        @('SUB_PROCESSOR','PERFBOOSTMODE','2'),
        @('SUB_DISK','DISKIDLE','0'),
        @('SUB_VIDEO','VIDEOIDLE','0'),
        @('SUB_SLEEP','STANDBYIDLE','0'),
        # Core parking OFF (100% min cores online): parked cores waking up
        # mid-game is a classic cause of sudden frame-time spikes.
        @('SUB_PROCESSOR','CPMINCORES','100'),
        # USB selective suspend OFF: Windows suspending the USB hub that hosts
        # the mouse/keyboard causes input freezes, stutter and missed clicks
        # mid-game. This is the #1 fix for "mouse randomly hitches" reports.
        @('2a737441-1930-4402-8d77-b2bebba308a3','48e6b7a6-50f5-4782-a5d4-53bb8f07e226','0'),
        # USB 3 link power management OFF (no U1/U2 low-power transitions).
        @('2a737441-1930-4402-8d77-b2bebba308a3','d4e98f31-5ffe-4ce1-be31-1b38b384c009','0'),
        # PCI Express link state power management OFF: ASPM on the GPU link
        # adds wake-up latency and frame-time jitter.
        @('SUB_PCIEXPRESS','ASPM','0')
    )) {
        & powercfg.exe ('-' + $scope) SCHEME_CURRENT $setting[0] $setting[1] $setting[2] 2>$null | Out-Null
    }
}

# Belt-and-braces: also strip 'Allow the computer to turn off this device to
# save power' from USB Root Hubs and HID devices via their power management
# registry flags, so input devices can never be power-gated mid-game.
try {
    Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceName -match '^USB\\|^HID\\' } |
        ForEach-Object {
            try { Set-CimInstance -InputObject $_ -Property @{ Enable = $false } -ErrorAction SilentlyContinue } catch { }
        }
} catch { }
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
