# ==============================================================================
# Z-LAG OS - Desktop context toolbox + classic sound backend
# ------------------------------------------------------------------------------
# Removes the old visible Start Menu "Classic Sound Manager" folder and the old
# standalone Sound Manager desktop submenu. Replaces them with one top-positioned
# "Z LAG" submenu on desktop/folder backgrounds. The first commands are RAM
# Trim / Clean and Temp Clean, followed by a small set of useful maintenance and
# native classic-sound tools.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $logDir 'context_menu.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-MENU] ' + $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-ZLagLog 'ERROR: Administrator privileges are required.'
    exit 1
}

function Set-ZLagRegistryValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Name,
        [Parameter(Mandatory = $true)][AllowEmptyString()]$Value,
        [Parameter(Mandatory = $true)][ValidateSet('String', 'ExpandString', 'DWord')][string]$Type
    )

    New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    if ($Name -eq '') {
        # Registry providers represent a key's unnamed/default value via Set-Item.
        Set-Item -Path $Path -Value ([Environment]::ExpandEnvironmentVariables([string]$Value)) -Force -ErrorAction SilentlyContinue
    } else {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# ------------------------------------------------------------------------------
# 1. Remove every artifact created by the previous visible Classic Sound menu.
# ------------------------------------------------------------------------------
Write-ZLagLog 'Removing the old Classic Sound Start Menu and context-menu entries...'
$commandStore = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell'
$legacyCommandIds = @(
    'ZLAG.Sound.Playback',
    'ZLAG.Sound.Recording',
    'ZLAG.Sound.Sounds',
    'ZLAG.Sound.Communications',
    'ZLAG.Sound.Mixer',
    'ZLAG.Tools.RamTrim',
    'ZLAG.Tools.TempClean',
    'ZLAG.Tools.RecycleBin',
    'ZLAG.Tools.FlushDns',
    'ZLAG.Tools.RestartExplorer',
    'ZLAG.Tools.Sound',
    'ZLAG.Tools.Mixer'
)
Remove-Item -Path 'HKLM:\SOFTWARE\Classes\DesktopBackground\Shell\ZLAG.ClassicSound' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'HKLM:\SOFTWARE\Classes\Directory\Background\shell\ZLAG.ClassicSound' -Recurse -Force -ErrorAction SilentlyContinue
foreach ($id in $legacyCommandIds) {
    Remove-Item -Path (Join-Path $commandStore $id) -Recurse -Force -ErrorAction SilentlyContinue
}

# The old task created this all-user folder. Also remove per-user copies in case
# a previous version or manual repair copied the links into individual profiles.
$startMenuRoots = @(
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Z-LAG OS'),
    (Join-Path $env:SystemDrive 'Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Z-LAG OS')
)
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $profilePath = (Get-ItemProperty -Path $_.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profilePath) {
            $profilePath = [Environment]::ExpandEnvironmentVariables($profilePath)
            $startMenuRoots += (Join-Path $profilePath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Z-LAG OS')
        }
    }
foreach ($startMenuRoot in ($startMenuRoots | Select-Object -Unique)) {
    Remove-Item -LiteralPath $startMenuRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
# 2. Keep the classic native sound backend without adding visible Start entries.
# ------------------------------------------------------------------------------
Write-ZLagLog 'Keeping the native classic sound backend enabled...'
foreach ($service in @('AudioEndpointBuilder', 'Audiosrv')) {
    & sc.exe config $service start= auto 2>$null | Out-Null
    Start-Service -Name $service -ErrorAction SilentlyContinue
}
foreach ($path in @(
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\MTCUVC'
)) {
    Set-ZLagRegistryValue -Path $path -Name 'EnableMtcUvc' -Value 0 -Type DWord
}
Set-ZLagRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAVolume' -Value 0 -Type DWord

# ------------------------------------------------------------------------------
# 3. Install the action script in a stable, read-only location.
# ------------------------------------------------------------------------------
$toolSource = Join-Path $PSScriptRoot 'zlag_context_tools.ps1'
$toolDestination = Join-Path $logDir 'zlag_context_tools.ps1'
if (-not (Test-Path -LiteralPath $toolSource -PathType Leaf)) {
    Write-ZLagLog ('ERROR: context action script is missing: ' + $toolSource)
    exit 2
}
Copy-Item -LiteralPath $toolSource -Destination $toolDestination -Force -ErrorAction Stop
& icacls.exe $toolDestination /inheritance:r /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' '*S-1-5-32-545:RX' /q 2>$null | Out-Null

$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
function New-ZLagToolCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Icon
    )

    $entryRoot = Join-Path $commandStore $Id
    Remove-Item -Path $entryRoot -Recurse -Force -ErrorAction SilentlyContinue
    # Set both the unnamed value and MUIVerb so every Explorer build uses the
    # clean user-facing label. CommandStore key names also contain spaces only.
    Set-ZLagRegistryValue -Path $entryRoot -Name '' -Value $Label -Type String
    Set-ZLagRegistryValue -Path $entryRoot -Name 'MUIVerb' -Value $Label -Type String
    Set-ZLagRegistryValue -Path $entryRoot -Name 'Icon' -Value $Icon -Type ExpandString
    $command = '"' + $powerShell + '" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "' + $toolDestination + '" -Action ' + $Action
    Set-ZLagRegistryValue -Path (Join-Path $entryRoot 'command') -Name '' -Value $command -Type String
}

# SubCommands preserves this exact order. RAM and Temp are intentionally first.
$toolEntries = @(
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX RAM TRIM'; Label = 'RAM Trim / Clean'; Action = 'RamTrim'; Icon = '%SystemRoot%\System32\taskmgr.exe' },
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX TEMP CLEAN'; Label = 'Temp Clean'; Action = 'TempClean'; Icon = '%SystemRoot%\System32\cleanmgr.exe' },
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX RECYCLE BIN'; Label = 'Recycle Bin Clean'; Action = 'RecycleBin'; Icon = '%SystemRoot%\System32\imageres.dll,-55' },
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX FLUSH DNS'; Label = 'Flush DNS Cache'; Action = 'FlushDns'; Icon = '%SystemRoot%\System32\ipconfig.exe' },
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX RESTART EXPLORER'; Label = 'Restart Explorer'; Action = 'RestartExplorer'; Icon = '%SystemRoot%\explorer.exe' },
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX SOUND MANAGER'; Label = 'Sound Manager (Classic)'; Action = 'SoundManager'; Icon = '%SystemRoot%\System32\mmsys.cpl' },
    [pscustomobject]@{ Id = 'Z LAG TOOLBOX VOLUME MIXER'; Label = 'Volume Mixer (Classic)'; Action = 'VolumeMixer'; Icon = '%SystemRoot%\System32\sndvol.exe' }
)
foreach ($entry in $toolEntries) {
    New-ZLagToolCommand -Id $entry.Id -Label $entry.Label -Action $entry.Action -Icon $entry.Icon
}

# ------------------------------------------------------------------------------
# 4. Add one first-position "Z LAG TOOLBOX" submenu to desktop/folder backgrounds.
# ------------------------------------------------------------------------------
Write-ZLagLog 'Creating the first-position Z LAG TOOLBOX context submenu...'
$subCommands = ($toolEntries | ForEach-Object { $_.Id }) -join ';'
$backgroundShellRoots = @(
    'HKLM:\SOFTWARE\Classes\DesktopBackground\Shell',
    'HKLM:\SOFTWARE\Classes\Directory\Background\shell'
)

# Delete every key name used by previous builds, including the internal-looking
# 00_ZLAG.Tools / 00_ZLAG.TOOLBOX names reported by users.
$oldMenuNames = @(
    'ZLAG.Tools', '00_ZLAG.Tools', 'ZLAG.Toolbox', 'ZLAG.TOOLBOX',
    '00_ZLAG.Toolbox', '00_ZLAG.TOOLBOX', 'Z LAG', 'Z LAG TOOLBOX'
)
foreach ($shellRoot in $backgroundShellRoots) {
    foreach ($oldName in $oldMenuNames) {
        Remove-Item -Path (Join-Path $shellRoot $oldName) -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# The registry key itself also uses the clean spaced name. Both the default value
# and MUIVerb are set so Explorer can never fall back to dots or underscores.
foreach ($shellRoot in $backgroundShellRoots) {
    $menuRoot = Join-Path $shellRoot 'Z LAG TOOLBOX'
    Set-ZLagRegistryValue -Path $menuRoot -Name '' -Value 'Z LAG TOOLBOX' -Type String
    Set-ZLagRegistryValue -Path $menuRoot -Name 'MUIVerb' -Value 'Z LAG TOOLBOX' -Type String
    Set-ZLagRegistryValue -Path $menuRoot -Name 'Icon' -Value '%SystemRoot%\System32\taskmgr.exe' -Type ExpandString
    Set-ZLagRegistryValue -Path $menuRoot -Name 'Position' -Value 'Top' -Type String
    Set-ZLagRegistryValue -Path $menuRoot -Name 'SubCommands' -Value $subCommands -Type String
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
Set-ZLagRegistryValue -Path $marker -Name 'ClassicSoundManager' -Value 1 -Type DWord
Set-ZLagRegistryValue -Path $marker -Name 'ZLagContextMenu' -Value 1 -Type DWord
Set-ZLagRegistryValue -Path $marker -Name 'ZLagContextMenuDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Type String

Write-ZLagLog 'Z LAG TOOLBOX context menu configured with clean spaced labels; visible Classic Sound Start Menu folder removed.'
