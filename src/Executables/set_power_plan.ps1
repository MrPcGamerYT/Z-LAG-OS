# ==============================================================================
# Z-LAG OS - "Maximum FPS" power plan: create ONCE, tune, ACTIVATE, VERIFY.
# ------------------------------------------------------------------------------
# Production rules implemented here:
#   * Idempotent: an existing "Maximum FPS" plan is reused, never duplicated.
#     Stale extra copies (from older playbook versions) are deleted.
#   * The plan is tuned by its EXPLICIT GUID (never SCHEME_CURRENT guessing).
#   * Activation happens AFTER tuning and is VERIFIED with /getactivescheme;
#     one retry is attempted before reporting a warning.
#   * Locale-safe: powercfg output is parsed with a GUID regex only - no
#     dependency on English "Power Scheme GUID:" text.
#   * Universal Win10/Win11: Ultimate Performance template -> High Performance
#     template -> tune the currently active scheme as a last resort.
#   * A marker (HKLM\SOFTWARE\Z-LAG-OS\MaxFpsPlanGuid) records the plan GUID
#     so the context-menu "Activate Max FPS Power Plan" tool targets the
#     exact same plan.
# ==============================================================================
$ErrorActionPreference = 'Continue'

$UltimateTemplate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$HighPerformance  = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
$PlanName         = 'Maximum FPS'
$PlanDescription  = 'Optimized for zero-lag gaming (Z-LAG OS)'
$GuidPattern      = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

function Get-ZLagPowerSchemes {
    # Returns @{ Guid; Name; Active } for every installed scheme, locale-safe.
    $schemes = @()
    foreach ($line in ((& powercfg.exe /list 2>$null | Out-String) -split "`r?`n")) {
        if ($line -match ('(' + $GuidPattern + ')\s+\((.*?)\)')) {
            $schemes += [pscustomobject]@{
                Guid   = $Matches[1]
                Name   = $Matches[2].Trim()
                Active = ($line.TrimEnd().EndsWith('*'))
            }
        }
    }
    return $schemes
}

function Get-ZLagActiveSchemeGuid {
    $text = (& powercfg.exe /getactivescheme 2>$null | Out-String)
    $match = [regex]::Match($text, $GuidPattern)
    if ($match.Success) { return $match.Value }
    return $null
}

Write-Output '[Z-LAG] Locating or creating the Maximum FPS power plan...'
$targetGuid = $null
$schemes = Get-ZLagPowerSchemes

# --- 1. Reuse an existing "Maximum FPS" plan; remove stale duplicates. -------
$existing = @($schemes | Where-Object { $_.Name -eq $PlanName })
if ($existing.Count -gt 0) {
    $targetGuid = $existing[0].Guid
    foreach ($stale in ($existing | Select-Object -Skip 1)) {
        & powercfg.exe /delete $stale.Guid 2>$null | Out-Null
        Write-Output ('[Z-LAG] Removed stale duplicate Maximum FPS plan: ' + $stale.Guid)
    }
    Write-Output ('[Z-LAG] Reusing existing Maximum FPS plan: ' + $targetGuid)
}

# --- 2. Otherwise duplicate Ultimate Performance, then High Performance. -----
if (-not $targetGuid) {
    foreach ($template in @($UltimateTemplate, $HighPerformance)) {
        $duplicateOutput = (& powercfg.exe /duplicatescheme $template 2>$null | Out-String)
        $match = [regex]::Match($duplicateOutput, $GuidPattern)
        if ($match.Success) {
            $targetGuid = $match.Value
            & powercfg.exe /changename $targetGuid $PlanName $PlanDescription 2>$null | Out-Null
            Write-Output ('[Z-LAG] Created Maximum FPS plan ' + $targetGuid + ' from template ' + $template)
            break
        }
    }
}

# --- 3. Last resort: tune whatever plan is currently active. -----------------
if (-not $targetGuid) {
    $targetGuid = Get-ZLagActiveSchemeGuid
    Write-Output '[Z-LAG] Plan creation unavailable; tuning the active scheme in place.'
}

if (-not $targetGuid) {
    Write-Output '[Z-LAG] WARNING: no power scheme could be resolved; skipping plan tuning.'
} else {
    # --- 4. Tune the plan BY GUID (AC + DC). Never SCHEME_CURRENT: if another
    #        tool changes the active plan mid-run, SCHEME_CURRENT would tune
    #        the wrong scheme and the Maximum FPS plan would stay stock.
    Write-Output ('[Z-LAG] Applying Maximum FPS tuning to ' + $targetGuid + ' (AC + DC)...')
    foreach ($scope in @('setacvalueindex', 'setdcvalueindex')) {
        foreach ($setting in @(
            # PROCTHROTTLEMIN stays LOW on purpose: locking the minimum
            # processor state at 100% keeps the CPU at max clocks even at
            # idle, heat-soaks the machine and causes thermal throttling
            # (FPS drops) mid-game. 5% min + 100% max + aggressive boost
            # gives identical peak clocks with far more thermal headroom.
            @('SUB_PROCESSOR','PROCTHROTTLEMIN','5'),
            @('SUB_PROCESSOR','PROCTHROTTLEMAX','100'),
            @('SUB_PROCESSOR','PERFBOOSTMODE','2'),
            @('SUB_DISK','DISKIDLE','0'),
            @('SUB_VIDEO','VIDEOIDLE','0'),
            @('SUB_SLEEP','STANDBYIDLE','0'),
            # Core parking OFF (100% min cores online): parked cores waking
            # mid-game cause sudden frame-time spikes.
            @('SUB_PROCESSOR','CPMINCORES','100'),
            # USB selective suspend OFF: suspending the hub that hosts the
            # mouse/keyboard causes input freezes and missed clicks mid-game.
            @('2a737441-1930-4402-8d77-b2bebba308a3','48e6b7a6-50f5-4782-a5d4-53bb8f07e226','0'),
            # USB 3 link power management OFF (no U1/U2 transitions).
            @('2a737441-1930-4402-8d77-b2bebba308a3','d4e98f31-5ffe-4ce1-be31-1b38b384c009','0'),
            # PCI Express ASPM OFF: link-state power management on the GPU
            # lane adds wake-up latency and frame-time jitter.
            @('SUB_PCIEXPRESS','ASPM','0')
        )) {
            & powercfg.exe ('/' + $scope) $targetGuid $setting[0] $setting[1] $setting[2] 2>$null | Out-Null
        }
    }

    # --- 5. ACTIVATE the tuned plan and VERIFY (this was the missing step:
    #        older builds created and tuned the plan but never confirmed the
    #        switch, so Balanced could silently stay active). ----------------
    & powercfg.exe /setactive $targetGuid 2>$null | Out-Null
    $activeGuid = Get-ZLagActiveSchemeGuid
    if ($activeGuid -ne $targetGuid) {
        Start-Sleep -Milliseconds 500
        & powercfg.exe /setactive $targetGuid 2>$null | Out-Null
        $activeGuid = Get-ZLagActiveSchemeGuid
    }
    if ($activeGuid -eq $targetGuid) {
        Write-Output ('[Z-LAG] VERIFIED: Maximum FPS plan is ACTIVE (' + $targetGuid + ').')
    } else {
        Write-Output ('[Z-LAG] WARNING: active scheme is ' + $activeGuid + ', expected ' + $targetGuid + '.')
    }

    # --- 6. Record the plan GUID so the context-menu tool re-activates the
    #        exact same plan later. ------------------------------------------
    try {
        New-Item -Path 'HKLM:\SOFTWARE\Z-LAG-OS' -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Z-LAG-OS' -Name 'MaxFpsPlanGuid' -Value $targetGuid -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    } catch { }
}

# --- 7. Device-level power gating OFF for USB/HID (input can never sleep). ---
try {
    Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceName -match '^USB\\|^HID\\' } |
        ForEach-Object {
            try { Set-CimInstance -InputObject $_ -Property @{ Enable = $false } -ErrorAction SilentlyContinue } catch { }
        }
} catch { }
& powercfg.exe /hibernate off 2>$null | Out-Null

# Missing BCDEdit values are expected on many systems. Capture every stream so
# harmless "Element not found" text does not appear as a playbook failure.
Write-Output '[Z-LAG] Applying BCDEdit timing tweaks...'
$null = & bcdedit.exe /deletevalue useplatformclock 2>&1
$null = & bcdedit.exe /set tscsyncpolicy Enhanced 2>&1
$null = & bcdedit.exe /set disabledynamictick yes 2>&1

Write-Output '[Z-LAG] Power plan and timing optimizations complete.'
exit 0
