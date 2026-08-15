# ==============================================================================
# Z-LAG OS - Startup status installer
# ------------------------------------------------------------------------------
# Enables Windows' native verbose Winlogon status on the secure Welcome screen,
# then installs an all-user, post-authentication status overlay that reports the
# real processes and configured startup items appearing in the user session.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $logDir 'startup_status_install.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-STARTUP] ' + $Message
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

# Supported Windows mechanism for status text below Welcome/Please wait.
Write-ZLagLog 'Enabling native verbose startup, sign-in and shutdown status...'
$systemPolicy = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
New-Item -Path $systemPolicy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'VerboseStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'DisableStatusMessages' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

# Keep first sign-in on the same status path instead of the long animated tips.
New-ItemProperty -Path $systemPolicy -Name 'EnableFirstLogonAnimation' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

$source = Join-Path $PSScriptRoot 'show_startup_status.ps1'
$destination = Join-Path $logDir 'show_startup_status.ps1'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    Write-ZLagLog ('ERROR: startup display source was not found: ' + $source)
    exit 2
}
Copy-Item -LiteralPath $source -Destination $destination -Force -ErrorAction Stop

# ProgramData is machine-controlled so a standard user cannot replace a logon
# script and turn this Run entry into a privilege/persistence primitive.
& icacls.exe $destination /inheritance:r /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' '*S-1-5-32-545:RX' /q 2>$null | Out-Null

# HKLM Run is intentionally written after the process-floor pass has cleared
# third-party startup entries. It starts in the real interactive user session,
# unlike an AtStartup scheduled task which runs invisibly in session 0.
Write-ZLagLog 'Installing the all-user real-time startup overlay...'
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
New-Item -Path $runKey -Force -ErrorAction SilentlyContinue | Out-Null
$command = 'powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "' + $destination + '"'
New-ItemProperty -Path $runKey -Name 'ZLAGStartupStatus' -Value $command -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

# Remove stale StartupApproved blocks for this exact entry. Explorer will create
# its own enabled value when required; an old disabled value must not win.
foreach ($approvalKey in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)) {
    Remove-ItemProperty -Path $approvalKey -Name 'ZLAGStartupStatus' -Force -ErrorAction SilentlyContinue
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'VerboseStartupStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'StartupStatusInstalledDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

Write-ZLagLog 'Startup status enabled. Native Welcome status begins on the next boot.'
