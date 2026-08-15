# ==============================================================================
# Z-LAG OS - Repair AppX / UWP launch stack (self-healing, marker-aware)
#
# Keeps the Windows desktop shell + sideloaded apps working WITHOUT bringing
# back the Microsoft Store. It reads HKLM:\SOFTWARE\Z-LAG-OS\StoreRemoved:
#
#   * StoreRemoved = 1  ->  ONLY the Windows shell's own runtime is ensured
#                           (LicenseManager, ClipSVC, AppXSvc, StateRepository).
#                           Microsoft account services (wlidsvc, TokenBroker)
#                           are left demand-only so "remove MS services" sticks.
#   * StoreRemoved missing -> full chain including wlidsvc + TokenBroker for
#                           users who kept Microsoft services.
#
# Safe to re-run as Administrator on an already-applied playbook.
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Output "[Z-LAG] Repairing AppX runtime (auto-start + boot watchdog)..."

$storeRemoved = $false
$marker = Get-ItemProperty -Path "HKLM:\SOFTWARE\Z-LAG-OS" -Name "StoreRemoved" -ErrorAction SilentlyContinue
if ($marker -and $marker.StoreRemoved -eq 1) { $storeRemoved = $true }
Write-Output ("[Z-LAG] Store removed marker: " + $storeRemoved)

function Set-ServiceStartup {
    param([string]$Name, [ValidateSet("auto", "demand")][string]$Mode = "auto")

    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Output "[Z-LAG]   skip $Name (not installed)"
        return $false
    }

    & sc.exe config $Name start= $Mode | Out-Null
    & sc.exe failure $Name reset= 86400 actions= restart/3000/restart/3000/restart/3000 | Out-Null

    $reg = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    if (Test-Path $reg) {
        $dword = if ($Mode -eq "auto") { 2 } else { 3 }
        Set-ItemProperty -Path $reg -Name "Start" -Value $dword -Type DWord -Force
        if ($Mode -eq "auto") {
            Set-ItemProperty -Path $reg -Name "DelayedAutostart" -Value 1 -Type DWord -Force
        }
    }
    return $true
}

function Start-ServiceSafe {
    param([string]$Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { return }
    if ($svc.Status -eq "Running") {
        Write-Output "[Z-LAG]   $Name already running"
        return
    }
    try {
        Start-Service -Name $Name -ErrorAction Stop
        Write-Output "[Z-LAG]   started $Name"
    } catch {
        & net.exe start $Name 2>$null | Out-Null
        $after = (Get-Service -Name $Name -ErrorAction SilentlyContinue).Status
        Write-Output "[Z-LAG]   $Name -> $after  ($($_.Exception.Message))"
    }
}

# Base chain (always): Windows shell's own AppX runtime. These are NOT the Store
# and NOT Microsoft account services - they are what Windows uses to run the
# Start Menu / Search and to launch any packaged app the toolbox installs.
$BootChain = @(
    @{ Name = "RpcSs";           Mode = "auto" },
    @{ Name = "RpcEptMapper";    Mode = "auto" },
    @{ Name = "CryptSvc";        Mode = "auto" },
    @{ Name = "LicenseManager";  Mode = "auto" },
    @{ Name = "ClipSVC";         Mode = "auto" },
    @{ Name = "AppXSvc";         Mode = "demand" },
    @{ Name = "StateRepository"; Mode = "demand" },
    @{ Name = "camsvc";          Mode = "demand" }
)

# Only when Microsoft services were KEPT do we force the MS account/identity
# services back to auto-start (needed by Store-style apps the user may keep).
if (-not $storeRemoved) {
    $BootChain += @(
        @{ Name = "wlidsvc";        Mode = "auto" },
        @{ Name = "TokenBroker";    Mode = "auto" }
    )
} else {
    # Demand-only: available if a packaged app asks, but 0 processes at idle.
    $BootChain += @(
        @{ Name = "wlidsvc";        Mode = "demand" },
        @{ Name = "TokenBroker";    Mode = "demand" }
    )
}

foreach ($entry in $BootChain) {
    if (Set-ServiceStartup -Name $entry.Name -Mode $entry.Mode) {
        Start-ServiceSafe -Name $entry.Name
    }
}

# Remove any leftover policy that blocks ALL packaged apps (crash cause #1).
$storePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
if (Test-Path $storePolicy) {
    Remove-ItemProperty -Path $storePolicy -Name "DisableStoreApps" -ErrorAction SilentlyContinue
}

# Sideload policy ON so the toolbox can install apps without the Store.
$appxPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
if (-not (Test-Path $appxPolicy)) { New-Item -Path $appxPolicy -Force | Out-Null }
Set-ItemProperty -Path $appxPolicy -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $appxPolicy -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

$devUnlock = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $devUnlock)) { New-Item -Path $devUnlock -Force | Out-Null }
Set-ItemProperty -Path $devUnlock -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $devUnlock -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

# --- Watchdog: persists the correct startup state across reboots ---
# Executable scripts live under protected Program Files; ProgramData remains for
# logs, markers and backups only.
$dataDir = Join-Path $env:ProgramData "Z-LAG-OS"
$coreRoot = Join-Path $env:SystemRoot "Z-LAG-OS"
$coreDir = Join-Path $coreRoot "Core"
if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $coreDir)) { New-Item -Path $coreDir -ItemType Directory -Force | Out-Null }

# A previous run may have already locked this folder. Temporarily grant the
# current elevated/TI token write access before updating watchdog files.
& attrib.exe -h -s $coreRoot 2>$null
& takeown.exe /f $coreRoot /a /r /d y 2>$null | Out-Null
$currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$currentGrant = '*' + $currentSid + ':(OI)(CI)F'
& icacls.exe $coreRoot /inheritance:e /grant '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' $currentGrant /t /c /q 2>$null | Out-Null

# The watchdog honours the StoreRemoved marker: it never re-enables Microsoft
# account services on a machine where the user chose to remove them.
$starter = Join-Path $coreDir "start_appx_runtime.cmd"
$starterContent = @"
@echo off
rem Z-LAG OS watchdog: keep packaged-app launch stack alive (Store UI not required)
reg query "HKLM\SOFTWARE\Z-LAG-OS" /v StoreRemoved >nul 2>&1
if %errorlevel%==0 (
    rem Microsoft services were removed - only ensure the Windows shell runtime
    sc config wlidsvc start= demand >nul 2>&1
    sc config TokenBroker start= demand >nul 2>&1
) else (
    rem Microsoft services kept - full chain
    sc config wlidsvc start= auto >nul 2>&1
    sc config TokenBroker start= auto >nul 2>&1
)
sc config LicenseManager start= auto >nul 2>&1
sc config ClipSVC start= auto >nul 2>&1
sc config CryptSvc start= auto >nul 2>&1
sc config AppXSvc start= demand >nul 2>&1
sc config StateRepository start= demand >nul 2>&1
net start RpcSs >nul 2>&1
net start CryptSvc >nul 2>&1
net start LicenseManager >nul 2>&1
net start ClipSVC >nul 2>&1
net start AppXSvc >nul 2>&1
reg query "HKLM\SOFTWARE\Z-LAG-OS" /v StoreRemoved >nul 2>&1
if not %errorlevel%==0 (
    net start wlidsvc >nul 2>&1
    net start TokenBroker >nul 2>&1
)
"@
Set-Content -Path $starter -Value $starterContent -Encoding ASCII

# Persist a protected copy next to the watchdog and remove old ProgramData code.
try {
    Copy-Item -Path $PSCommandPath -Destination (Join-Path $coreDir "repair_appx_runtime.ps1") -Force
} catch {}
foreach ($oldRoot in @($dataDir, (Join-Path $env:ProgramFiles "Z-LAG-OS\Core"))) {
    foreach ($oldFile in @("start_appx_runtime.cmd", "repair_appx_runtime.ps1")) {
        Remove-Item -LiteralPath (Join-Path $oldRoot $oldFile) -Force -ErrorAction SilentlyContinue
    }
}
& icacls.exe $coreRoot /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' '*S-1-5-11:(OI)(CI)RX' '*S-1-5-4:(OI)(CI)RX' /t /c /q 2>$null | Out-Null
& attrib.exe +h +s $coreRoot 2>$null

$taskName = "Z LAG Opti Services - AppX Runtime"
foreach ($oldTaskName in @("ZLAG-StartAppXRuntime", $taskName)) {
    Unregister-ScheduledTask -TaskName $oldTaskName -Confirm:$false -ErrorAction SilentlyContinue
}

$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$starter`""
$triggerBoot = New-ScheduledTaskTrigger -AtStartup
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
# Re-arm a few minutes after boot in case something disabled the services during apply
$triggerDelay = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 3650)

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($triggerBoot, $triggerLogon, $triggerDelay) -Principal $principal -Settings $settings -Force | Out-Null

& $env:ComSpec /d /c ('"' + $starter + '"') 2>$null | Out-Null

Write-Output "[Z-LAG] AppX runtime is self-healing (task: $taskName)."
if ($storeRemoved) {
    Write-Output "[Z-LAG] Store removed -> Microsoft account services left demand-only (no idle footprint)."
} else {
    Write-Output "[Z-LAG] Store kept -> wlidsvc + ClipSVC + LicenseManager + TokenBroker auto-start."
}
