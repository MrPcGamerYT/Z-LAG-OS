# ==============================================================================
# Z-LAG OS - Classic Sound Manager configuration
# ------------------------------------------------------------------------------
# Keeps the native Win32 sound tools front and center:
#   * mmsys.cpl for Playback, Recording, Sounds and Communications
#   * sndvol.exe for the per-application Volume Mixer
#   * classic volume flyout on Windows builds that support EnableMtcUvc
#   * an all-user Start Menu folder and desktop-background cascading menu
# ==============================================================================

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $logDir 'classic_sound.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-SOUND] ' + $Message
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
        # Store an expanded command path because Set-Item writes REG_SZ.
        Set-Item -Path $Path -Value ([Environment]::ExpandEnvironmentVariables([string]$Value)) -Force -ErrorAction SilentlyContinue
    } else {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# Make sure the classic applets have a live audio stack even after the aggressive
# service floor pass. These two services remain protected everywhere else too.
Write-ZLagLog 'Verifying Windows Audio services...'
foreach ($service in @('AudioEndpointBuilder', 'Audiosrv')) {
    & sc.exe config $service start= auto 2>$null | Out-Null
    Start-Service -Name $service -ErrorAction SilentlyContinue
}

# Windows 10 and early Windows 11 builds honor this value and use the classic
# compact volume control. New Windows 11 taskbars hard-code Quick Settings and
# may ignore it; the native shortcuts/menu below remain available on every build.
Write-ZLagLog 'Selecting the classic volume UI where supported...'
foreach ($path in @(
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MTCUVC',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\MTCUVC'
)) {
    Set-ZLagRegistryValue -Path $path -Name 'EnableMtcUvc' -Value 0 -Type DWord
}

# Never hide the speaker icon through Explorer policy.
Set-ZLagRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAVolume' -Value 0 -Type DWord

# Build a machine-wide classic Sound submenu on the desktop background.
Write-ZLagLog 'Creating the classic Sound desktop menu...'
$menuRoot = 'HKLM:\SOFTWARE\Classes\DesktopBackground\Shell\ZLAG.ClassicSound'
Set-ZLagRegistryValue -Path $menuRoot -Name 'MUIVerb' -Value 'Sound Manager (Classic)' -Type String
Set-ZLagRegistryValue -Path $menuRoot -Name 'Icon' -Value '%SystemRoot%\System32\mmsys.cpl' -Type ExpandString
Set-ZLagRegistryValue -Path $menuRoot -Name 'Position' -Value 'Top' -Type String
Set-ZLagRegistryValue -Path $menuRoot -Name 'SubCommands' -Value 'ZLAG.Sound.Playback;ZLAG.Sound.Recording;ZLAG.Sound.Sounds;ZLAG.Sound.Communications;ZLAG.Sound.Mixer' -Type String

$commandStore = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell'
$commands = @(
    [pscustomobject]@{ Id = 'ZLAG.Sound.Playback'; Label = 'Playback devices'; Command = '%SystemRoot%\System32\rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,0'; Icon = '%SystemRoot%\System32\mmsys.cpl' },
    [pscustomobject]@{ Id = 'ZLAG.Sound.Recording'; Label = 'Recording devices'; Command = '%SystemRoot%\System32\rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,1'; Icon = '%SystemRoot%\System32\mmsys.cpl' },
    [pscustomobject]@{ Id = 'ZLAG.Sound.Sounds'; Label = 'System sounds'; Command = '%SystemRoot%\System32\rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,2'; Icon = '%SystemRoot%\System32\mmsys.cpl' },
    [pscustomobject]@{ Id = 'ZLAG.Sound.Communications'; Label = 'Communications'; Command = '%SystemRoot%\System32\rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,3'; Icon = '%SystemRoot%\System32\mmsys.cpl' },
    [pscustomobject]@{ Id = 'ZLAG.Sound.Mixer'; Label = 'Volume Mixer (Classic)'; Command = '%SystemRoot%\System32\sndvol.exe'; Icon = '%SystemRoot%\System32\sndvol.exe' }
)
foreach ($entry in $commands) {
    $entryRoot = Join-Path $commandStore $entry.Id
    Set-ZLagRegistryValue -Path $entryRoot -Name 'MUIVerb' -Value $entry.Label -Type String
    Set-ZLagRegistryValue -Path $entryRoot -Name 'Icon' -Value $entry.Icon -Type ExpandString
    Set-ZLagRegistryValue -Path (Join-Path $entryRoot 'command') -Name '' -Value $entry.Command -Type ExpandString
}

# Create discoverable shortcuts for every user. No UWP Settings page or
# ms-settings URI is used: all targets are native Win32 tools.
Write-ZLagLog 'Creating all-user Classic Sound Manager shortcuts...'
$startFolder = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Z-LAG OS\Classic Sound Manager'
New-Item -Path $startFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

try {
    $shell = New-Object -ComObject WScript.Shell
    $shortcutSpecs = @(
        [pscustomobject]@{ Name = 'Playback Devices (Classic).lnk'; Target = (Join-Path $env:SystemRoot 'System32\rundll32.exe'); Arguments = 'shell32.dll,Control_RunDLL mmsys.cpl,,0'; Icon = (Join-Path $env:SystemRoot 'System32\mmsys.cpl') + ',0'; Hotkey = '' },
        [pscustomobject]@{ Name = 'Recording Devices (Classic).lnk'; Target = (Join-Path $env:SystemRoot 'System32\rundll32.exe'); Arguments = 'shell32.dll,Control_RunDLL mmsys.cpl,,1'; Icon = (Join-Path $env:SystemRoot 'System32\mmsys.cpl') + ',0'; Hotkey = '' },
        [pscustomobject]@{ Name = 'System Sounds (Classic).lnk'; Target = (Join-Path $env:SystemRoot 'System32\rundll32.exe'); Arguments = 'shell32.dll,Control_RunDLL mmsys.cpl,,2'; Icon = (Join-Path $env:SystemRoot 'System32\mmsys.cpl') + ',0'; Hotkey = '' },
        [pscustomobject]@{ Name = 'Communications (Classic).lnk'; Target = (Join-Path $env:SystemRoot 'System32\rundll32.exe'); Arguments = 'shell32.dll,Control_RunDLL mmsys.cpl,,3'; Icon = (Join-Path $env:SystemRoot 'System32\mmsys.cpl') + ',0'; Hotkey = '' },
        [pscustomobject]@{ Name = 'Volume Mixer (Classic).lnk'; Target = (Join-Path $env:SystemRoot 'System32\sndvol.exe'); Arguments = ''; Icon = (Join-Path $env:SystemRoot 'System32\sndvol.exe') + ',0'; Hotkey = 'CTRL+ALT+V' }
    )
    foreach ($spec in $shortcutSpecs) {
        $shortcut = $shell.CreateShortcut((Join-Path $startFolder $spec.Name))
        $shortcut.TargetPath = $spec.Target
        $shortcut.Arguments = $spec.Arguments
        $shortcut.WorkingDirectory = (Join-Path $env:SystemRoot 'System32')
        $shortcut.IconLocation = $spec.Icon
        if ($spec.Hotkey) { $shortcut.Hotkey = $spec.Hotkey }
        $shortcut.Description = 'Z-LAG OS native classic sound control'
        $shortcut.Save()
    }
    [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null
} catch {
    Write-ZLagLog ('Shortcut creation warning: ' + $_.Exception.Message)
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
Set-ZLagRegistryValue -Path $marker -Name 'ClassicSoundManager' -Value 1 -Type DWord
Set-ZLagRegistryValue -Path $marker -Name 'ClassicSoundConfiguredDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Type String

Write-ZLagLog 'Classic Sound Manager configured. Use Ctrl+Alt+V for the classic mixer.'
