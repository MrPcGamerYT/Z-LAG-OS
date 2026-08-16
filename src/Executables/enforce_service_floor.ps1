# ==============================================================================
# Z-LAG OS - Persistent idle service/process floor
# ------------------------------------------------------------------------------
# Windows trigger-start and per-user service templates can recreate processes
# after the first boot even when their first instances were disabled during the
# playbook. This script locks the non-gaming service templates and every suffixed
# per-user instance to Start=4, stops any instance that came back, and briefly
# rechecks at boot and logon only. It NEVER runs mid-session: a periodic pass
# while a game is running caused visible FPS stutter, so enforcement happens
# exclusively before the user is in-game. It never remains resident.
#
# Core RPC (RpcSs/RpcEptMapper), networking, audio, shell/AppX, logon, security,
# GPU and boot/system-start services are not in the target list and are guarded.
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$EnforceOnly
)

$ErrorActionPreference = 'Continue'
$dataDir = Join-Path $env:ProgramData 'Z-LAG-OS'
$installDir = Join-Path $env:SystemRoot 'Z-LAG-OS'
New-Item -Path $dataDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $dataDir 'service_floor_watchdog.log'

function Write-ZLagFloorLog {
    param([string]$Message)
    $line = '[{0}] [Z-LAG-SERVICE-FLOOR] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-ZLagFloorLog 'ERROR: Administrator or SYSTEM privileges are required.'
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

# Every fixed service below was already targeted by the aggressive floor or is a
# safe demand-only legacy service explicitly reported as returning after boot.
$targetServices = @(
    # User-reported legacy/on-demand services.
    'VSS', 'SwPrv', 'RpcLocator', 'SNMPTRAP', 'vds', 'WMPNetworkSvc',
    'ssh-agent', 'sshd', 'MSDTC', 'SDRSVC', 'smphost', 'wbengine',

    # Search, telemetry, diagnostics, compatibility and maintenance.
    'SysMain', 'WSearch', 'DiagTrack', 'dmwappushservice', 'WerSvc', 'PcaSvc',
    'DPS', 'WdiServiceHost', 'WdiSystemHost', 'TroubleshootingSvc', 'DcpSvc',
    'UhsSvc', 'WEPHOSTSVC', 'wercplsupport', 'diagsvc',
    'diagnosticshub.standardcollector.service', 'InventorySvc',
    'DoSvc', 'UsoSvc', 'WaaSMedicSvc', 'wuauserv', 'defragsvc',
    'fhsvc', 'pla', 'wmiApSrv', 'AppMgmt', 'AeLookupSvc', 'AxInstSV',

    # Cloud/content/Xbox/phone and safe per-user service templates.
    'OneSyncSvc', 'UserDataSvc', 'UnistoreSvc', 'PimIndexMaintenanceSvc',
    'MessagingService', 'BcastDVRUserService', 'CaptureService',
    'CloudBackupRestoreSvc', 'AarSvc', 'cbdhsvc', 'WpnService',
    'WpnUserService', 'UdkUserSvc', 'shpamsvc', 'Ndu', 'DusmSvc',
    'NcdAutoSetup', 'wcncsvc', 'NPSMSvc', 'MapsBroker', 'PhoneSvc',
    'WalletService', 'NaturalAuthentication', 'lfsvc', 'dcsvc',
    'spectrum', 'svsvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc',
    'XboxGipSvc',

    # Printing, imaging, sensors and optional consumer hardware helpers.
    # NOTE: TabletInputService is intentionally NOT in this list - it is part
    # of the text-input stack and must stay demand-start to keep keyboard
    # input working in UWP/search surfaces.
    'Spooler', 'PrintNotify', 'PrintWorkflowUserSvc', 'StiSvc', 'WiaRpc',
    'WbioSrvc', 'SensorService', 'SensorDataService', 'SensrSvc', 'FrameServer',
    'FrameServerMonitor', 'WPDBusEnum', 'wisvc',

    # Sharing, discovery, remote management and other non-gaming extras.
    'LanmanServer', 'SharedAccess', 'SSDPSRV', 'upnphost', 'fdPHost', 'FDResPub',
    'lltdsvc', 'WebClient', 'MSiSCSI', 'Wecsvc', 'WinRM', 'NetTcpPortSharing',
    'NetTcpActivator', 'NetPipeActivator', 'NetMsmqActivator', 'ALG', 'lmhosts',
    'IpxlatCfgSvc', 'PeerDistSvc', 'QWAVE', 'TapiSrv', 'icssvc',
    'WFDSConMgrSvc', 'p2pimsvc', 'p2psvc', 'PNRPsvc', 'RemoteRegistry',
    'TrkWks', 'Fax', 'RetailDemo', 'Browser', 'workfolderssvc', 'autotimesvc',
    'tzautoupdate', 'TermService', 'SessionEnv', 'UmRdpService',

    # Optional platform/enterprise components already disabled by the floor.
    'SCardSvc', 'ScDeviceEnum', 'SCPolicySvc', 'CertPropSvc', 'EFS',
    'NfcSvc', 'SEMgrSvc', 'embeddedmode', 'vmcompute', 'HvHost', 'vmms', 'hns',
    'vmicguestinterface', 'vmicheartbeat', 'vmickvpexchange', 'vmicrdv',
    'vmicshutdown', 'vmictimesync', 'vmicvmsession', 'vmicvss', 'AJRouter',
    'LxssManager', 'WslService', 'LxssManagerUser', 'P9RdrService',
    'AppVClient', 'EntAppSvc', 'AssignedAccessManagerSvc', 'UevAgentService',
    'CscService', 'TieringEngineService', 'MixedRealityOpenXRSvc',
    'SharedRealitySvc', 'GraphicsPerfSvc', 'edgeupdate', 'edgeupdatem',
    'MicrosoftEdgeElevationService', 'ClickToRunSvc'
) | Select-Object -Unique

# Defense-in-depth: even if a future edit accidentally adds one of these names,
# the watchdog must never disable it.
$hardKeep = @(
    'RpcSs', 'RpcEptMapper', 'DcomLaunch', 'Power', 'PlugPlay', 'Schedule',
    'EventLog', 'EventSystem', 'BrokerInfrastructure', 'CoreMessagingRegistrar',
    'SystemEventsBroker', 'ProfSvc', 'UserManager', 'SamSs', 'gpsvc', 'SENS',
    'Winmgmt', 'msiserver', 'TrustedInstaller', 'CryptSvc', 'KeyIso', 'VaultSvc',
    'Dhcp', 'Dnscache', 'NlaSvc', 'nsi', 'Tcpip', 'NetBT', 'LanmanWorkstation',
    'netprofm', 'WcmSvc', 'WlanSvc', 'bthserv', 'BTAGService', 'bthpriv',
    'BluetoothUserService', 'BthAvctpSvc', 'bthHFSrv', 'RmSvc', 'BFE', 'MpsSvc',
    'EapHost', 'RasMan', 'IKEEXT', 'PolicyAgent', 'CDPSvc', 'CDPUserSvc',
    'NcbService', 'DeviceAssociationService', 'DeviceAssociationBrokerSvc',
    'DevicePickerUserSvc', 'DevicesFlowUserSvc', 'DeviceInstall', 'DsmSvc',
    'AppXSvc', 'AppReadiness', 'ClipSVC', 'LicenseManager', 'StateRepository',
    'camsvc', 'wlidsvc', 'TokenBroker', 'Audiosrv', 'AudioEndpointBuilder'
)

function Get-ZLagBaseServiceName {
    param([string]$Name)
    # Windows per-user service instances end in an underscore + LUID-like suffix.
    return ($Name -replace '_[0-9A-Fa-f]{5,}$', '')
}

# sc.exe and service state transitions are explicitly bounded. A service stuck in
# START_PENDING is marked disabled immediately and gets at most 1.5 seconds to
# stop; the floor never waits for it to finish starting.
function Invoke-ZLagScBounded {
    param([string[]]$Arguments, [int]$TimeoutMilliseconds = 750)
    try {
        $process = Start-Process -FilePath "$env:SystemRoot\System32\sc.exe" -ArgumentList $Arguments -WindowStyle Hidden -PassThru -ErrorAction Stop
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            return $false
        }
        return $true
    } catch { return $false }
}

function Stop-ZLagServiceBounded {
    param([string]$Name, [datetime]$PassDeadline)
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $service -or $service.Status -eq 'Stopped') { return $true }
    if ((Get-Date) -ge $PassDeadline) { return $false }

    [void](Invoke-ZLagScBounded -Arguments @('stop', $Name))
    $deadline = (Get-Date).AddMilliseconds(1500)
    if ($deadline -gt $PassDeadline) { $deadline = $PassDeadline }
    do {
        $status = (Get-Service -Name $Name -ErrorAction SilentlyContinue).Status
        if ($status -eq 'Stopped' -or $null -eq $status) { return $true }
        Start-Sleep -Milliseconds 100
    } while ((Get-Date) -lt $deadline)
    return $false
}

function Invoke-ZLagFloorEnforcement {
    $changedStartup = 0
    $stopped = 0
    $stopTimedOut = 0
    $removedTriggers = 0
    $skippedCritical = 0
    $passDeadline = (Get-Date).AddSeconds(60)
    $serviceRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    $allKeys = Get-ChildItem -Path $serviceRoot -ErrorAction SilentlyContinue

    foreach ($target in $targetServices) {
        $matchingKeys = $allKeys | Where-Object {
            $_.PSChildName -eq $target -or $_.PSChildName -like ($target + '_*')
        }
        foreach ($key in $matchingKeys) {
            $name = $key.PSChildName
            $baseName = Get-ZLagBaseServiceName -Name $name
            if ($hardKeep -contains $name -or $hardKeep -contains $baseName) { continue }

            $properties = Get-ItemProperty -Path $key.PSPath -Name Start -ErrorAction SilentlyContinue
            if ($null -ne $properties.Start -and [int]$properties.Start -le 1) {
                $skippedCritical++
                continue
            }

            # Remove service trigger metadata as well as setting Start=4. This
            # prevents network/logon/device events from resurrecting the service
            # if another component temporarily changes it back to demand-start.
            $triggerPath = Join-Path $key.PSPath 'TriggerInfo'
            if (Test-Path -LiteralPath $triggerPath) {
                Remove-Item -LiteralPath $triggerPath -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path -LiteralPath $triggerPath)) { $removedTriggers++ }
            }

            # Lock startup first so the service cannot start again even if its
            # current START_PENDING transition exceeds the bounded stop window.
            if ($null -eq $properties.Start -or [int]$properties.Start -ne 4) {
                New-ItemProperty -Path $key.PSPath -Name Start -Value 4 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                $changedStartup++
            }
            if ((Get-Date) -lt $passDeadline) {
                [void](Invoke-ZLagScBounded -Arguments @('config', $name, 'start=', 'disabled'))
            }

            $service = Get-Service -Name $name -ErrorAction SilentlyContinue
            $wasRunning = $service -and $service.Status -ne 'Stopped'
            if ($wasRunning) {
                if (Stop-ZLagServiceBounded -Name $name -PassDeadline $passDeadline) {
                    $stopped++
                } else {
                    $stopTimedOut++
                    Write-ZLagFloorLog ('Stop timeout for ' + $name + '; startup is disabled and enforcement continued.')
                }
            }
        }
    }

    # Kill only resident bloat processes already removed/disabled elsewhere.
    foreach ($processName in @(
        'OneDrive', 'msedge', 'msedgewebview2', 'MicrosoftEdgeUpdate', 'Widgets',
        'WidgetService', 'Copilot', 'Recall', 'YourPhone', 'PhoneExperienceHost',
        'Teams', 'ms-teams', 'SkypeBackgroundHost', 'GameBar', 'GameBarFTServer',
        'GameBarPresenceWriter', 'XboxApp', 'CrossDevice', 'SecurityHealthSystray',
        'SearchHost'
    )) {
        Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
    }

    $marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
    New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $marker -Name 'ServiceFloorLastRun' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $marker -Name 'ServiceFloorTargetCount' -Value $targetServices.Count -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

    Write-ZLagFloorLog ('Enforced {0} target families: startup corrected={1}, stopped={2}, stop timeouts={3}, triggers removed={4}, boot/system skipped={5}; pass cap=60s.' -f $targetServices.Count, $changedStartup, $stopped, $stopTimedOut, $removedTriggers, $skippedCritical)
}

if ($EnforceOnly) {
    Invoke-ZLagFloorEnforcement
    exit 0
}

# Install a visible Windows-folder copy and schedule brief non-resident rechecks.
$installedScript = Join-Path $installDir 'enforce_service_floor.ps1'
if (-not (Set-ZLagRuntimeAccess -Path $installDir)) {
    Write-ZLagFloorLog ('ERROR: Could not normalize runtime folder access: ' + $installDir)
    exit 3
}
Copy-Item -LiteralPath $PSCommandPath -Destination $installedScript -Force -ErrorAction Stop
Remove-Item -LiteralPath (Join-Path $dataDir 'enforce_service_floor.ps1') -Force -ErrorAction SilentlyContinue
if (-not (Set-ZLagRuntimeAccess -Path $installDir)) {
    Write-ZLagFloorLog ('ERROR: Could not apply normal runtime folder access: ' + $installDir)
    exit 3
}

$taskName = 'ZLAG-EnforceServiceFloor'
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $installedScript + '" -EnforceOnly'
$action = New-ScheduledTaskAction -Execute $powerShell -Argument $arguments
$triggerBoot = New-ScheduledTaskTrigger -AtStartup
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
try { $triggerBoot.Delay = 'PT20S' } catch { }
try { $triggerLogon.Delay = 'PT12S' } catch { }
# NO periodic trigger: the old 15-minute repetition woke a SYSTEM PowerShell
# pass (plus dozens of sc.exe children) in the middle of gaming sessions and
# caused recurring FPS stutter. Boot + logon enforcement is enough because the
# floor also deletes service TriggerInfo, so services cannot resurrect
# mid-session anyway.
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 3) -Priority 7
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($triggerBoot, $triggerLogon) -Principal $principal -Settings $settings -Force | Out-Null

Invoke-ZLagFloorEnforcement
Write-ZLagFloorLog ('Persistent non-resident watchdog installed as scheduled task: ' + $taskName)
