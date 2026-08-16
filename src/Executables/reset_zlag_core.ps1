# ==============================================================================
# Z-LAG OS - clean previous runtime reset
# ------------------------------------------------------------------------------
# Runs before every other playbook task. It removes stale Z-LAG scheduled tasks,
# startup values and runtime files, including folders left with hidden/system or
# restrictive ACL state by older releases. The current AME working directory and
# the separately installed Z-LAG Toolbox application are never touched.
# ==============================================================================

$ErrorActionPreference = 'Continue'

function Write-ZLagReset {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Output ('[Z-LAG-RESET] ' + $Message)
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = ([Security.Principal.WindowsPrincipal]$identity).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
$isSystemOrTI = $identity.User.Value -eq 'S-1-5-18' -or
    $identity.User.Value -eq 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
if (-not $isAdmin -and -not $isSystemOrTI) {
    Write-ZLagReset 'ERROR: Administrator, SYSTEM or TrustedInstaller privileges are required.'
    exit 1
}

Write-ZLagReset 'Stopping old Z-LAG runtime tasks and script hosts...'
$taskNames = @(
    'Z LAG Services - Welcome',
    'Custom Welcome Panel',
    'ZLAG-EnforceServiceFloor',
    'ZLAG-StartAppXRuntime',
    'Z-LAG-LockScreen-Enforce',
    'Z LAG Opti Services - Process Floor',
    'Z LAG Opti Services - AppX Runtime',
    'Z LAG Opti Services - Lock Screen',
    'Z-LAG-LockScreen-Enforce',
    'ZLAG-RepairBluetooth'
)
foreach ($taskName in ($taskNames | Select-Object -Unique)) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}
Stop-Process -Name 'ZLAGOptiServices', 'ZLagWelcome' -Force -ErrorAction SilentlyContinue

# Stop only hosts executing an old persistent Z-LAG payload. Never match the AME
# process that is currently running this source script from its temporary folder.
$runtimeFragments = @(
    (Join-Path $env:SystemRoot 'Z-LAG-OS'),
    (Join-Path $env:ProgramData 'Z-LAG-OS'),
    (Join-Path $env:ProgramFiles 'Z-LAG-OS')
)
if (${env:ProgramFiles(x86)}) {
    $runtimeFragments += (Join-Path ${env:ProgramFiles(x86)} 'Z-LAG-OS')
}
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        if ($_.Name -notmatch '^(powershell|pwsh|wscript|cscript|cmd)\.exe$' -or -not $_.CommandLine) {
            return $false
        }
        foreach ($fragment in $runtimeFragments) {
            if ($fragment -and $_.CommandLine.IndexOf($fragment, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                return $true
            }
        }
        return $false
    } |
    ForEach-Object {
        Invoke-CimMethod -InputObject $_ -MethodName Terminate -ErrorAction SilentlyContinue | Out-Null
    }

Write-ZLagReset 'Removing legacy startup registrations...'
$legacyValueNames = @('ZLAGStartupStatus', 'ZLAGWelcomePanel', 'Z LAG Services', 'Z LAG Opti Services')
$startupKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)
foreach ($key in $startupKeys) {
    foreach ($valueName in $legacyValueNames) {
        Remove-ItemProperty -LiteralPath $key -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}

# Remove shell commands that point to the old runtime. The current menu installer
# recreates only the clean spaced entries later in this same playbook run.
$shellRoots = @(
    'HKLM:\SOFTWARE\Classes\DesktopBackground\Shell',
    'HKLM:\SOFTWARE\Classes\Directory\Background\shell'
)
$menuNames = @(
    'ZLAG.ClassicSound', 'ZLAG.Tools', '00_ZLAG.Tools', 'ZLAG.Toolbox',
    'ZLAG.TOOLBOX', '00_ZLAG.Toolbox', '00_ZLAG.TOOLBOX', 'Z LAG', 'Z LAG TOOLBOX'
)
foreach ($shellRoot in $shellRoots) {
    foreach ($menuName in $menuNames) {
        Remove-Item -LiteralPath (Join-Path $shellRoot $menuName) -Recurse -Force -ErrorAction SilentlyContinue
    }
}
$commandStore = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell'
$commandIds = @(
    'ZLAG.Sound.Playback', 'ZLAG.Sound.Recording', 'ZLAG.Sound.Sounds',
    'ZLAG.Sound.Communications', 'ZLAG.Sound.Mixer', 'ZLAG.Tools.RamTrim',
    'ZLAG.Tools.TempClean', 'ZLAG.Tools.RecycleBin', 'ZLAG.Tools.FlushDns',
    'ZLAG.Tools.RestartExplorer', 'ZLAG.Tools.Sound', 'ZLAG.Tools.Mixer',
    'Z LAG TOOLBOX RAM TRIM', 'Z LAG TOOLBOX TEMP CLEAN',
    'Z LAG TOOLBOX RECYCLE BIN', 'Z LAG TOOLBOX FLUSH DNS',
    'Z LAG TOOLBOX RESTART EXPLORER', 'Z LAG TOOLBOX SOUND MANAGER',
    'Z LAG TOOLBOX VOLUME MIXER',
    'Z LAG TOOLBOX GAME BOOST', 'Z LAG TOOLBOX STANDBY CLEAR',
    'Z LAG TOOLBOX PING TEST', 'Z LAG TOOLBOX MAX FPS POWER',
    'Z LAG TOOLBOX SYSTEM INFO'
)
foreach ($commandId in $commandIds) {
    Remove-Item -LiteralPath (Join-Path $commandStore $commandId) -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-ZLagRuntimePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $true }

    Write-ZLagReset ('Clearing attributes and deleting ' + $Path)
    $children = Join-Path $Path '*'
    & attrib.exe -r -h -s $Path /s /d 2>$null | Out-Null
    & attrib.exe -r -h -s $children /s /d 2>$null | Out-Null
    & takeown.exe /f $Path /a /r /d y 2>$null | Out-Null
    & icacls.exe $Path /inheritance:e /remove:d '*S-1-1-0' '*S-1-5-32-545' '*S-1-5-11' '*S-1-5-4' /t /c /q 2>$null | Out-Null
    & icacls.exe $Path /reset /t /c /q 2>$null | Out-Null
    & icacls.exe $Path /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' /t /c /q 2>$null | Out-Null

    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Path) {
        & $env:ComSpec /d /c ('rd /s /q "' + $Path + '"') 2>$null | Out-Null
    }
    return (-not (Test-Path -LiteralPath $Path))
}

$runtimePaths = @(
    (Join-Path $env:SystemRoot 'Z-LAG-OS'),
    (Join-Path $env:ProgramData 'Z-LAG-OS'),
    (Join-Path $env:ProgramFiles 'Z-LAG-OS')
)
if (${env:ProgramFiles(x86)}) {
    $runtimePaths += (Join-Path ${env:ProgramFiles(x86)} 'Z-LAG-OS')
}
$failedPaths = @()
foreach ($path in ($runtimePaths | Where-Object { $_ } | Select-Object -Unique)) {
    if (-not (Remove-ZLagRuntimePath -Path $path)) { $failedPaths += $path }
}

# Clear stale state only after old tasks have been removed. Later playbook tasks
# recreate the marker and runtime folders from current source files.
Remove-Item -LiteralPath 'HKLM:\SOFTWARE\Z-LAG-OS' -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Z-LAG-OS') {
    Write-ZLagReset 'ERROR: The old Z-LAG registry state could not be removed.'
    exit 3
}
if ($failedPaths.Count -gt 0) {
    Write-ZLagReset ('ERROR: Old runtime paths remain: ' + ($failedPaths -join ', '))
    exit 2
}

Write-ZLagReset 'Previous runtime removed. Current files will be recreated visible with normal read/execute access.'
exit 0
