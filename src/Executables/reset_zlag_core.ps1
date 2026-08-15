# ==============================================================================
# Z-LAG OS - Aggressive previous-core reset
# Runs first, before the playbook recreates current watchdog/context/Welcome code.
# It removes only Z-LAG executable artifacts, not Windows components or user data.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Output '[Z-LAG-RESET] Administrator privileges are required.'
    exit 1
}

Write-Output '[Z-LAG-RESET] Stopping previous Z-LAG core processes and tasks...'
Stop-Process -Name 'ZLAGOptiServices' -Force -ErrorAction SilentlyContinue

# Terminate only script hosts whose command line points at an old persistent
# Z-LAG core path. Never match the current AME playbook PowerShell process.
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^(powershell|pwsh|wscript|cscript|cmd)\.exe$' -and
        $_.CommandLine -match '(?i)(C:\\Windows\\Z-LAG-OS\\Core|C:\\Program Files\\Z-LAG-OS)'
    } |
    ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName Terminate -ErrorAction SilentlyContinue | Out-Null }

$taskNames = @(
    'Z LAG Opti Services - Process Floor',
    'Z LAG Opti Services - AppX Runtime',
    'Z LAG Opti Services - Lock Screen',
    'ZLAG-EnforceServiceFloor',
    'ZLAG-StartAppXRuntime',
    'Z-LAG-LockScreen-Enforce',
    'ZLAG-RepairBluetooth'
)
foreach ($taskName in $taskNames) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

# Remove every prior Welcome startup registration and approval override.
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
foreach ($valueName in @('ZLAGStartupStatus', 'ZLAGWelcomePanel', 'Z LAG Services', 'Z LAG Opti Services')) {
    Remove-ItemProperty -Path $runKey -Name $valueName -Force -ErrorAction SilentlyContinue
    foreach ($approvalKey in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
    )) {
        Remove-ItemProperty -Path $approvalKey -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}

function Remove-ZLagCorePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $true }

    Write-Output ('[Z-LAG-RESET] Deleting ' + $Path)
    & attrib.exe -h -s -r $Path /s /d 2>$null
    & takeown.exe /f $Path /a /r /d y 2>$null | Out-Null
    $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $currentGrant = '*' + $currentSid + ':(OI)(CI)F'
    & icacls.exe $Path /inheritance:e /grant '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' $currentGrant /t /c /q 2>$null | Out-Null

    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Path) {
        & $env:ComSpec /d /c ('rd /s /q "' + $Path + '"') 2>$null | Out-Null
    }
    $quarantine = $null
    if (Test-Path -LiteralPath $Path) {
        $quarantine = $Path + '.old-' + [Guid]::NewGuid().ToString('N')
        try { Move-Item -LiteralPath $Path -Destination $quarantine -Force -ErrorAction Stop } catch { }
        if (Test-Path -LiteralPath $quarantine) {
            Remove-Item -LiteralPath $quarantine -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $quarantine) {
                & $env:ComSpec /d /c ('rd /s /q "' + $quarantine + '"') 2>$null | Out-Null
            }
        }
    }
    $originalGone = -not (Test-Path -LiteralPath $Path)
    $quarantineGone = -not $quarantine -or -not (Test-Path -LiteralPath $quarantine)
    return ($originalGone -and $quarantineGone)
}

$paths = @(
    (Join-Path $env:SystemRoot 'Z-LAG-OS'),
    (Join-Path $env:ProgramFiles 'Z-LAG-OS')
)
if (${env:ProgramFiles(x86)}) { $paths += (Join-Path ${env:ProgramFiles(x86)} 'Z-LAG-OS') }
$paths = $paths | Where-Object { $_ } | Select-Object -Unique

$failed = @()
foreach ($path in $paths) {
    if (-not (Remove-ZLagCorePath -Path $path)) { $failed += $path }
}

# ProgramData is retained for diagnostics/backups, but executable leftovers from
# old builds are removed.
$dataDir = Join-Path $env:ProgramData 'Z-LAG-OS'
foreach ($file in @(
    'show_startup_status.ps1', 'show_welcome_panel.ps1', 'launch_welcome_panel.vbs',
    'Z LAG Services.vbs', 'ZLagWelcome.exe', 'ZLAGOptiServices.exe',
    'enforce_service_floor.ps1', 'repair_appx_runtime.ps1',
    'start_appx_runtime.cmd', 'zlag_context_tools.ps1', 'repair_bluetooth.ps1'
)) {
    Remove-Item -LiteralPath (Join-Path $dataDir $file) -Force -ErrorAction SilentlyContinue
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
foreach ($value in @('WelcomePanelHost', 'OptiServicesHost', 'PostBootWelcomePanel', 'ServiceFloorLastRun', 'BootWelcomeInstalledDate')) {
    Remove-ItemProperty -Path $marker -Name $value -ErrorAction SilentlyContinue
}
New-ItemProperty -Path $marker -Name 'CoreResetDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

if ($failed.Count -gt 0) {
    Write-Output ('[Z-LAG-RESET] WARNING: locked paths remain: ' + ($failed -join ', '))
    exit 2
}
Write-Output '[Z-LAG-RESET] Previous Z-LAG executable core removed completely.'
exit 0
