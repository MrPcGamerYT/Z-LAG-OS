# ==============================================================================
# Z-LAG OS - Native boot status + post-boot Welcome panel installer
# ------------------------------------------------------------------------------
# Windows' supported VerboseStatus policy supplies loading text only while the
# secure Welcome/Please wait screen is active. After Explorer has fully started,
# a short custom Z LAG welcome panel appears with no process/app/service status.
# An interactive logon task invokes the protected VBS with wscript.exe, avoiding
# a console flash while leaving the temporary script-host processes observable.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$dataDir = Join-Path $env:ProgramData 'Z-LAG-OS'
$installDir = Join-Path $env:SystemRoot 'Z-LAG-OS'
New-Item -Path $dataDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
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

function Set-ZLagRuntimeAccess {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }

    $children = Join-Path $Path '*'
    & attrib.exe -r -h -s $Path /s /d 2>$null | Out-Null
    & attrib.exe -r -h -s $children /s /d 2>$null | Out-Null
    & icacls.exe $Path /inheritance:e /t /c /q 2>$null | Out-Null
    $inheritExit = $LASTEXITCODE
    & icacls.exe $Path /reset /t /c /q 2>$null | Out-Null
    $resetExit = $LASTEXITCODE
    & icacls.exe $Path /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' '*S-1-5-11:(OI)(CI)RX' '*S-1-5-4:(OI)(CI)RX' /t /c /q 2>$null | Out-Null
    $grantExit = $LASTEXITCODE
    & attrib.exe -r -h -s $Path /s /d 2>$null | Out-Null
    & attrib.exe -r -h -s $children /s /d 2>$null | Out-Null
    return ($inheritExit -eq 0 -and $resetExit -eq 0 -and $grantExit -eq 0)
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
if (-not (Set-ZLagRuntimeAccess -Path $installDir)) {
    Write-ZLagLog ('ERROR: Could not normalize runtime folder access: ' + $installDir)
    exit 3
}
Copy-Item -LiteralPath $panelSource -Destination $panelDestination -Force -ErrorAction Stop

# WScript starts Windows PowerShell with window style 0, so after boot the custom
# panel is the only window. Both script-host processes remain visible to normal
# Windows administration while the panel runs.
$escapedPanelPath = $panelDestination.Replace('"', '""')
$launcher = @"
Option Explicit
Dim shell, command
Set shell = CreateObject("WScript.Shell")
command = "powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File ""$escapedPanelPath"""
shell.Run command, 0, False
"@
Set-Content -LiteralPath $launcherDestination -Value $launcher -Encoding Unicode -Force

# Keep the folder and every payload visible with normal attributes. Standard users
# receive read/execute access; elevated identities retain write access so scheduled
# actions work without making SYSTEM-run scripts user-modifiable.
if (-not (Set-ZLagRuntimeAccess -Path $installDir)) {
    Write-ZLagLog ('ERROR: Could not apply normal runtime folder access: ' + $installDir)
    exit 3
}

# Remove every legacy Run/Startup entry. Scheduled Task is used so the panel is
# not listed under Task Manager > Startup apps.
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$approvalKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)
$legacyValueNames = @('ZLAGStartupStatus', 'ZLAGWelcomePanel', 'Z LAG Services', 'Z LAG Opti Services')
New-Item -Path $runKey -Force -ErrorAction SilentlyContinue | Out-Null
foreach ($valueName in $legacyValueNames) {
    Remove-ItemProperty -Path $runKey -Name $valueName -Force -ErrorAction SilentlyContinue
    foreach ($approvalKey in $approvalKeys) {
        Remove-ItemProperty -Path $approvalKey -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}
$remainingStartupValues = @()
foreach ($startupKey in @($runKey) + $approvalKeys) {
    if (-not (Test-Path -LiteralPath $startupKey)) { continue }
    try {
        $propertyNames = (Get-ItemProperty -LiteralPath $startupKey -ErrorAction Stop).PSObject.Properties.Name
        foreach ($valueName in $legacyValueNames) {
            if ($propertyNames -contains $valueName) { $remainingStartupValues += ($startupKey + '::' + $valueName) }
        }
    } catch {
        Write-ZLagLog ('ERROR: Could not inspect legacy startup values in ' + $startupKey + ': ' + $_.Exception.Message)
        exit 4
    }
}
if ($remainingStartupValues.Count -gt 0) {
    Write-ZLagLog ('ERROR: Legacy startup values remain: ' + ($remainingStartupValues -join ', '))
    exit 4
}
Remove-Item -LiteralPath (Join-Path $installDir 'show_startup_status.ps1') -Force -ErrorAction SilentlyContinue
foreach ($oldFile in @('show_startup_status.ps1', 'show_welcome_panel.ps1', 'launch_welcome_panel.vbs')) {
    Remove-Item -LiteralPath (Join-Path $dataDir $oldFile) -Force -ErrorAction SilentlyContinue
}

function Get-ZLagInteractiveUserSid {
    $accounts = @()
    try {
        $computerUser = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).UserName
        if ($computerUser) { $accounts += $computerUser }
    } catch { }
    Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $owner = Invoke-CimMethod -InputObject $_ -MethodName GetOwner -ErrorAction Stop
            if ($owner.User) {
                if ($owner.Domain) { $accounts += ($owner.Domain + '\' + $owner.User) }
                else { $accounts += $owner.User }
            }
        } catch { }
    }
    foreach ($account in ($accounts | Where-Object { $_ } | Select-Object -Unique)) {
        try {
            $sid = ([Security.Principal.NTAccount]$account).Translate([Security.Principal.SecurityIdentifier]).Value
            # Accept classic local/domain identities and Microsoft Entra identities.
            if ($sid -match '^S-1-(?:5-21|12-1)-') { return $sid }
        } catch { }
    }
    return $null
}

$interactiveSid = Get-ZLagInteractiveUserSid
if (-not $interactiveSid) {
    Write-ZLagLog 'ERROR: No interactive user SID was found for the Welcome task.'
    exit 5
}

$taskName = 'Z LAG Services - Welcome'
Unregister-ScheduledTask -TaskName 'Custom Welcome Panel' -Confirm:$false -ErrorAction SilentlyContinue
$wscriptPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
$xmlWscript = [Security.SecurityElement]::Escape($wscriptPath)
$xmlLauncher = [Security.SecurityElement]::Escape($launcherDestination)
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Z LAG post-boot Welcome panel</Description></RegistrationInfo>
  <Triggers><LogonTrigger><Enabled>true</Enabled><UserId>$interactiveSid</UserId><Delay>PT2S</Delay></LogonTrigger></Triggers>
  <Principals><Principal id="Author"><UserId>$interactiveSid</UserId><LogonType>InteractiveToken</LogonType><RunLevel>LeastPrivilege</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings><StopOnIdleEnd>false</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author"><Exec><Command>$xmlWscript</Command><Arguments>&quot;$xmlLauncher&quot;</Arguments></Exec></Actions>
</Task>
"@
try {
    Register-ScheduledTask -TaskName $taskName -Xml $taskXml -Force -ErrorAction Stop | Out-Null
} catch {
    Write-ZLagLog ('ERROR: Could not register interactive Welcome task: ' + $_.Exception.Message)
    exit 6
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'VerboseBootStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'PostBootWelcomePanel' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'WelcomeTaskName' -Value $taskName -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'WelcomeTaskUserSid' -Value $interactiveSid -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'BootWelcomeInstalledDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'VerboseStartupStatus' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $marker -Name 'StartupStatusInstalledDate' -ErrorAction SilentlyContinue

Write-ZLagLog ('Scheduled interactive Welcome panel configured: ' + $taskName + ' for ' + $interactiveSid)
