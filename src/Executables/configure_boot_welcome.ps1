# ==============================================================================
# Z-LAG OS - Native boot status + post-boot Welcome panel installer
# ------------------------------------------------------------------------------
# Windows' supported VerboseStatus policy supplies loading text only while the
# secure Welcome/Please wait screen is active. After Explorer has fully started,
# a short custom Z LAG welcome panel appears with no process/app/service status.
# A hidden WScript launcher prevents a PowerShell console from flashing at logon.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$dataDir = Join-Path $env:ProgramData 'Z-LAG-OS'
$coreRoot = Join-Path $env:SystemRoot 'Z-LAG-OS'
$coreDir = Join-Path $coreRoot 'Core'
New-Item -Path $dataDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $coreDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $dataDir 'boot_welcome_install.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-WELCOME] ' + $Message
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

# Keep status messages inside the real secure Windows boot/sign-in screen.
Write-ZLagLog 'Enabling native status text for the secure Welcome/loading screen...'
$systemPolicy = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
New-Item -Path $systemPolicy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'VerboseStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'DisableStatusMessages' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'EnableFirstLogonAnimation' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

$panelSource = Join-Path $PSScriptRoot 'show_welcome_panel.ps1'
$panelDestination = Join-Path $coreDir 'show_welcome_panel.ps1'
$launcherDestination = Join-Path $coreDir 'Z LAG Services.vbs'
if (-not (Test-Path -LiteralPath $panelSource -PathType Leaf)) {
    Write-ZLagLog ('ERROR: Welcome panel source was not found: ' + $panelSource)
    exit 2
}

# The core may already be locked by a previous run. Temporarily grant the
# current elevated/TI token write access before replacing panel files.
& attrib.exe -h -s $coreRoot 2>$null
& takeown.exe /f $coreRoot /a /r /d y 2>$null | Out-Null
$currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$currentGrant = '*' + $currentSid + ':(OI)(CI)F'
& icacls.exe $coreRoot /inheritance:e /grant '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' $currentGrant /t /c /q 2>$null | Out-Null
Copy-Item -LiteralPath $panelSource -Destination $panelDestination -Force -ErrorAction Stop

# WScript starts Windows PowerShell with window style 0, so after boot the custom
# panel is the only visible window - there is no console and no startup-status UI.
$escapedPanelPath = $panelDestination.Replace('"', '""')
$launcher = @"
Option Explicit
Dim shell, command
Set shell = CreateObject("WScript.Shell")
command = "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File ""$escapedPanelPath"""
shell.Run command, 0, False
Set shell = Nothing
WScript.Quit 0
"@
Set-Content -LiteralPath $launcherDestination -Value $launcher -Encoding Unicode -Force

# The Windows core folder is the protected code location; ProgramData contains logs
# only. Users can execute these files but cannot replace them.
& icacls.exe $coreRoot /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' /t /c /q 2>$null | Out-Null
& attrib.exe +h +s $coreRoot 2>$null
& attrib.exe +h $dataDir 2>$null

# Remove previous ProgramData script copies and the live status implementation.
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
New-Item -Path $runKey -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $runKey -Name 'ZLAGStartupStatus' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $runKey -Name 'ZLAGWelcomePanel' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $runKey -Name 'Z LAG Opti Services' -Force -ErrorAction SilentlyContinue
foreach ($oldFile in @('show_startup_status.ps1', 'show_welcome_panel.ps1', 'launch_welcome_panel.vbs', 'Z LAG Services.vbs', 'ZLAGOptiServices.exe', 'ZLagWelcome.exe')) {
    Remove-Item -LiteralPath (Join-Path $dataDir $oldFile) -Force -ErrorAction SilentlyContinue
}
foreach ($oldFile in @('show_startup_status.ps1', 'launch_welcome_panel.vbs', 'ZLAGOptiServices.exe', 'ZLagWelcome.exe')) {
    Remove-Item -LiteralPath (Join-Path $coreDir $oldFile) -Force -ErrorAction SilentlyContinue
}
Remove-Item -LiteralPath (Join-Path $env:ProgramFiles 'Z-LAG-OS') -Recurse -Force -ErrorAction SilentlyContinue

# Register the silent launcher after all startup-purge tasks have already run.
$runCommand = '"' + (Join-Path $env:SystemRoot 'System32\wscript.exe') + '" "' + $launcherDestination + '"'
New-ItemProperty -Path $runKey -Name 'Z LAG Services' -Value $runCommand -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

# Remove stale StartupApproved blocks for both the old and new value names.
foreach ($approvalKey in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)) {
    foreach ($valueName in @('ZLAGStartupStatus', 'ZLAGWelcomePanel', 'Z LAG Opti Services', 'Z LAG Services')) {
        Remove-ItemProperty -Path $approvalKey -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'VerboseBootStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'PostBootWelcomePanel' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'WelcomePanelHost' -Value $launcherDestination -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'OptiServicesHost' -ErrorAction SilentlyContinue
New-ItemProperty -Path $marker -Name 'BootWelcomeInstalledDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'VerboseStartupStatus' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $marker -Name 'StartupStatusInstalledDate' -ErrorAction SilentlyContinue

Write-ZLagLog 'VBS Welcome panel configured (Startup name: Z LAG Services).'
