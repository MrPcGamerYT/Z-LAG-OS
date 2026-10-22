# ==============================================================================
# Z-LAG OS - Windows Defender Guard (the "keep Defender" contract)
# ------------------------------------------------------------------------------
# WHY THIS SCRIPT EXISTS (user-reported: "I chose NOT to remove Defender but
# it is still broken - the protections take a while loading"):
#   When the user picks defender-keep, other playbook passes used to interfere:
#     * add_update_hosts.ps1 blocked download.microsoft.com - the CDN that
#       serves Defender signature/engine definitions, so protection could not
#       update and appeared broken/slow.
#     * process_floor.ps1 disabled wscsvc (Windows Security Center) - the
#       service the Windows Security app queries, so the app loaded slowly
#       and showed stale/broken protection status.
#     * 15_notifications.yml + final_push.ps1 suppressed Defender Security
#       Center notifications (including security alerts) unconditionally.
#     * final_push.ps1 set the Defender-for-Endpoint ShowAlertWindow=0 policy
#       and killed SecurityHealthSystray unconditionally.
#
# THIS SCRIPT IS THE KEEP-SIDE ENFORCEMENT POINT. It runs LATE in the playbook
# (after all hosts/service/notification passes) and, ONLY when the
# defender-disable option was NOT selected (no DefenderRemoved marker):
#   1. Removes stale Defender-disable policies left by older runs.
#   2. Re-enables + starts WinDefend, WdNisSvc, SecurityHealthService, wscsvc.
#   3. Cleans the hosts file of any block against Defender update endpoints
#      (download.microsoft.com etc. - legacy entries from older versions).
#   4. Re-enables the Windows Defender scheduled tasks (scans/maintenance).
#   5. Re-enables Defender Security Center notifications (security alerts).
#   6. Triggers a signature update so protection is current right away.
#
# When DefenderRemoved=1 the script exits immediately - the user CHOSE the
# removal path and nothing may re-enable Defender.
#
# Idempotent. Never prompts. Logs to C:\ProgramData\Z-LAG-OS\defender_guard.log
# ==============================================================================
$ErrorActionPreference = 'Continue'

$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir 'defender_guard.log'

function Log {
    param([string]$m)
    $line = '[{0}] [Z-LAG-DEFENDER-GUARD] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Log 'ERROR: Administrator privileges required.'
    exit 1
}

# --- 0. Option gate: did the user choose the Defender removal path? -------------
$defenderRemoved = $false
$marker = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Z-LAG-OS' -Name 'DefenderRemoved' -ErrorAction SilentlyContinue).DefenderRemoved
if ($marker -eq 1) { $defenderRemoved = $true }
if ($defenderRemoved) {
    Log 'Defender removal was selected (DefenderRemoved=1). Guard stays out of the way.'
    exit 0
}

Log 'Defender KEEP mode: re-establishing a fully functional Windows Defender...'

# --- 1. Remove stale Defender-disable policies (left by older Z-LAG runs) -------
$policyRoot = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
if (Test-Path $policyRoot) {
    foreach ($stale in @('DisableAntiSpyware', 'DisableAntiVirus')) {
        Remove-ItemProperty -Path $policyRoot -Name $stale -Force -ErrorAction SilentlyContinue
    }
}
$rtPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection'
if (Test-Path $rtPolicy) {
    foreach ($stale in @('DisableRealtimeMonitoring', 'DisableBehaviorMonitoring', 'DisableIOAVProtection', 'DisableOnAccessProtection')) {
        Remove-ItemProperty -Path $rtPolicy -Name $stale -Force -ErrorAction SilentlyContinue
    }
}
Log 'Stale Defender-disable policies cleared.'

# --- 2. Service health: enabled + running ---------------------------------------
# wscsvc (Windows Security Center) is required by the Windows Security app.
$defenderServices = @('WinDefend', 'WdNisSvc', 'SecurityHealthService', 'wscsvc')
foreach ($svc in $defenderServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if (-not $service) {
        Log ('  skip: ' + $svc + ' (not installed)')
        continue
    }
    # Start=2 automatic. sc.exe first (handles services Set-Service struggles
    # with), then the registry value as the persistent source of truth.
    & sc.exe config $svc start= auto 2>$null | Out-Null
    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $svc
    if (Test-Path $regPath) {
        New-ItemProperty -Path $regPath -Name 'Start' -Value 2 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    }
    if ($service.Status -ne 'Running') {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        $newStatus = (Get-Service -Name $svc -ErrorAction SilentlyContinue).Status
        Log ('  service ' + $svc + ' -> ' + $newStatus)
    } else {
        Log ('  service ' + $svc + ' already running')
    }
}

# --- 3. Hosts cleanup: never block Defender update endpoints --------------------
# Legacy versions of this playbook blocked download.microsoft.com (the CDN that
# serves Defender definitions). Remove ANY 0.0.0.0 entry for Defender-critical
# endpoints, on a fresh file (backed up first).
$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$defenderEndpoints = @(
    'download.microsoft.com',
    'defender.microsoft.com',
    'www.microsoft.com',
    'ctldl.microsoft.com'
)
. (Join-Path $PSScriptRoot 'hosts_file_utils.ps1')
try {
    $changed = Update-ZLagHostsFile -Path $hostsPath -UnblockedHosts $defenderEndpoints
    Log ('Defender hosts cleanup verified; changed: ' + $changed)
} catch {
    Log ('ERROR: Could not clean Defender endpoint blocks: ' + $_.Exception.Message)
}

# --- 4. Defender scheduled tasks: enabled (on-demand scans + maintenance) -------
$defTasks = @(Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender' -ErrorAction SilentlyContinue)
if (-not $defTasks) {
    $defTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskPath -like '\Microsoft\Windows\Windows Defender\*' })
}
$taskCount = 0
foreach ($t in $defTasks) {
    if ($t.State -ne 'Ready') {
        Enable-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null
        $taskCount++
    }
}
Log ('Defender scheduled tasks enabled (' + $taskCount + ' re-enabled of ' + $defTasks.Count + ' total).')

# --- 5. Defender Security Center notifications: security alerts must show -------
$scNotif = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
if (Test-Path $scNotif) {
    Remove-ItemProperty -Path $scNotif -Name 'DisableNotifications' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $scNotif -Name 'DisableEnhancedNotifications' -Force -ErrorAction SilentlyContinue
}
# The Windows Security Center alert policy (Defender for Endpoint) must not be
# suppressed on a machine that keeps Defender.
$atp = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection'
if (Test-Path $atp) {
    Remove-ItemProperty -Path $atp -Name 'ShowAlertWindow' -Force -ErrorAction SilentlyContinue
}
Log 'Defender Security Center notifications restored (security alerts visible).'

# --- 6. Force a signature update so protection is current immediately -----------
try {
    Log 'Requesting Defender signature update (Update-MpSignature)...'
    Update-MpSignature
    Log 'Signature update requested successfully.'
} catch {
    Log ('Signature update request failed (non-fatal, will retry in background): ' + $_.Exception.Message)
}

Log 'Defender KEEP mode enforced: services running, signatures updating, alerts enabled.'
exit 0
