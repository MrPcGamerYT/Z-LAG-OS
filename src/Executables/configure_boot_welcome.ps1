# ==============================================================================
# Z-LAG OS - Native boot status + post-boot Welcome panel installer
# ------------------------------------------------------------------------------
# Windows' supported VerboseStatus policy supplies loading text only while the
# secure Welcome/Please wait screen is active. After Explorer has fully started,
# a short custom Z LAG welcome panel appears with no process/app/service status.
# A hidden WScript launcher prevents a PowerShell console from flashing at logon.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$installDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $installDir 'boot_welcome_install.log'

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
$panelDestination = Join-Path $installDir 'show_welcome_panel.ps1'
$launcherDestination = Join-Path $installDir 'launch_welcome_panel.vbs'
if (-not (Test-Path -LiteralPath $panelSource -PathType Leaf)) {
    Write-ZLagLog ('ERROR: Welcome panel source was not found: ' + $panelSource)
    exit 2
}
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
"@
Set-Content -LiteralPath $launcherDestination -Value $launcher -Encoding Unicode -Force

# Standard users may read/execute the installed files but cannot replace them.
foreach ($file in @($panelDestination, $launcherDestination)) {
    & icacls.exe $file /inheritance:r /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' '*S-1-5-32-545:RX' /q 2>$null | Out-Null
}

# Remove the previous live startup-status implementation and its permanent copy.
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
New-Item -Path $runKey -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $runKey -Name 'ZLAGStartupStatus' -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $installDir 'show_startup_status.ps1') -Force -ErrorAction SilentlyContinue

# Register the silent launcher after all startup-purge tasks have already run.
$runCommand = '"' + (Join-Path $env:SystemRoot 'System32\wscript.exe') + '" "' + $launcherDestination + '"'
New-ItemProperty -Path $runKey -Name 'ZLAGWelcomePanel' -Value $runCommand -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

# Remove stale StartupApproved blocks for both the old and new value names.
foreach ($approvalKey in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)) {
    foreach ($valueName in @('ZLAGStartupStatus', 'ZLAGWelcomePanel')) {
        Remove-ItemProperty -Path $approvalKey -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'VerboseBootStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'PostBootWelcomePanel' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'BootWelcomeInstalledDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'VerboseStartupStatus' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $marker -Name 'StartupStatusInstalledDate' -ErrorAction SilentlyContinue

Write-ZLagLog 'Native lock-screen loading status and post-boot Welcome-only panel configured.'
