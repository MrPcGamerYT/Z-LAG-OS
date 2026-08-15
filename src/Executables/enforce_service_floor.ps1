# ==============================================================================
# Z-LAG OS - Persistent idle service/process floor
# ------------------------------------------------------------------------------
# Windows trigger-start and per-user service templates can recreate processes
# after the first boot even when their first instances were disabled during the
# playbook. This script locks the non-gaming service templates and every suffixed
# per-user instance to Start=4, stops any instance that came back, and briefly
# rechecks at boot, logon, and every 15 minutes. It never remains resident.
#
# Core RPC (RpcSs/RpcEptMapper), networking, audio, shell/AppX, logon, security,
# GPU and boot/system-start services are not in the target list and are guarded.
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$EnforceOnly
)

$ErrorActionPreference = 'Continue'
$installDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $installDir 'service_floor_watchdog.log'

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

# Every fixed service below was already targeted by the aggressive floor or is a
# safe demand-only legacy service explicitly reported as returning after boot.
$targetServices = @(
    # User-reported legacy/on-demand services.
    'VSS', 'SwPrv', 'RpcLocator', 'SNMPTRAP', 'vds', 'WMPNetworkSvc',
    'ssh-agent', 'sshd', 'MSDTC', 'SDRSVC', 'smphost', 'wbengine',

    # Search, telemetry, diagnostics, compatibility and maintenance.
    'SysMain', 'WSearch', 'DiagTrack', 'dmwappushservice', 'WerSvc', 'PcaSvc',
    'DPS', 'WdiServiceHost', 'WdiSystemHost', 'TroubleshootingSvc', 'DcpSvc',
    'UhsSvc', 'DoSvc', 'UsoSvc', 'WaaSMedicSvc', 'wuauserv', 'defragsvc',
    'fhsvc', 'pla', 'wmiApSrv',

    # Cloud/content/Xbox/phone and safe per-user service templates.
    'OneSyncSvc', 'UserDataSvc', 'UnistoreSvc', 'PimIndexMaintenanceSvc',
    'MessagingService', 'BcastDVRUserService', 'CaptureService', 'CDPSvc',
    'CDPUserSvc', 'CloudBackupRestoreSvc', 'AarSvc', 'cbdhsvc', 'WpnService',
    'WpnUserService', 'UdkUserSvc', 'shpamsvc', 'Ndu', 'MapsBroker', 'PhoneSvc',
    'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc',

    # Printing, imaging, sensors and optional consumer hardware helpers.
    'Spooler', 'PrintNotify', 'PrintWorkflowUserSvc', 'StiSvc', 'WiaRpc',
    'WbioSrvc', 'SensorService', 'SensorDataService', 'SensrSvc', 'FrameServer',
    'WPDBusEnum', 'TabletInputService', 'wisvc',

    # Sharing, discovery, remote management and other non-gaming extras.
    'LanmanServer', 'SharedAccess', 'SSDPSRV', 'upnphost', 'fdPHost', 'FDResPub',
    'lltdsvc', 'WebClient', 'MSiSCSI', 'Wecsvc', 'WinRM', 'NetTcpPortSharing',
    'p2pimsvc', 'p2psvc', 'PNRPsvc', 'RemoteRegistry', 'TrkWks', 'Fax',
    'RetailDemo', 'Browser', 'workfolderssvc', 'autotimesvc',

    # Optional platform/enterprise components already disabled by the floor.
    'SCardSvc', 'ScDeviceEnum', 'SCPolicySvc', 'NfcSvc', 'SEMgrSvc',
    'embeddedmode', 'vmcompute', 'HvHost', 'vmms', 'hns', 'AJRouter',
    'AppVClient', 'AssignedAccessManagerSvc', 'UevAgentService', 'CscService',
    'TieringEngineService', 'MixedRealityOpenXRSvc', 'GraphicsPerfSvc'
) | Select-Object -Unique

# Defense-in-depth: even if a future edit accidentally adds one of these names,
# the watchdog must never disable it.
$hardKeep = @(
    'RpcSs', 'RpcEptMapper', 'DcomLaunch', 'Power', 'PlugPlay', 'Schedule',
    'EventLog', 'EventSystem', 'BrokerInfrastructure', 'CoreMessagingRegistrar',
    'SystemEventsBroker', 'ProfSvc', 'UserManager', 'SamSs', 'gpsvc', 'SENS',
    'Winmgmt', 'msiserver', 'TrustedInstaller', 'CryptSvc', 'KeyIso', 'VaultSvc',
    'Dhcp', 'Dnscache', 'NlaSvc', 'nsi', 'Tcpip', 'NetBT', 'LanmanWorkstation',
    'netprofm', 'WcmSvc', 'WlanSvc', 'bthserv', 'BTAGService', 'BFE', 'MpsSvc',
    'EapHost', 'RasMan', 'IKEEXT', 'PolicyAgent',
    'AppXSvc', 'AppReadiness', 'ClipSVC', 'LicenseManager', 'StateRepository',
    'camsvc', 'wlidsvc', 'TokenBroker', 'Audiosrv', 'AudioEndpointBuilder'
)

function Get-ZLagBaseServiceName {
    param([string]$Name)
    # Windows per-user service instances end in an underscore + LUID-like suffix.
    return ($Name -replace '_[0-9A-Fa-f]{5,}$', '')
}

function Invoke-ZLagFloorEnforcement {
    $changedStartup = 0
    $stopped = 0
    $skippedCritical = 0
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

            $service = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($service -and $service.Status -ne 'Stopped') {
                Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 40
                if ((Get-Service -Name $name -ErrorAction SilentlyContinue).Status -eq 'Stopped') {
                    $stopped++
                }
            }

            if ($null -eq $properties.Start -or [int]$properties.Start -ne 4) {
                & sc.exe config $name start= disabled 2>$null | Out-Null
                New-ItemProperty -Path $key.PSPath -Name Start -Value 4 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
                $changedStartup++
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

    Write-ZLagFloorLog ('Enforced {0} target families: startup corrected={1}, running stopped={2}, boot/system skipped={3}.' -f $targetServices.Count, $changedStartup, $stopped, $skippedCritical)
}

if ($EnforceOnly) {
    Invoke-ZLagFloorEnforcement
    exit 0
}

# Install a protected permanent copy and schedule brief non-resident rechecks.
$installedScript = Join-Path $installDir 'enforce_service_floor.ps1'
Copy-Item -LiteralPath $PSCommandPath -Destination $installedScript -Force -ErrorAction Stop
& icacls.exe $installedScript /inheritance:r /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' '*S-1-5-32-545:RX' /q 2>$null | Out-Null

$taskName = 'ZLAG-EnforceServiceFloor'
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $installedScript + '" -EnforceOnly'
$action = New-ScheduledTaskAction -Execute $powerShell -Argument $arguments
$triggerBoot = New-ScheduledTaskTrigger -AtStartup
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
try { $triggerBoot.Delay = 'PT20S' } catch { }
try { $triggerLogon.Delay = 'PT12S' } catch { }
$triggerPeriodic = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(3) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650)
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 3)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($triggerBoot, $triggerLogon, $triggerPeriodic) -Principal $principal -Settings $settings -Force | Out-Null

Invoke-ZLagFloorEnforcement
Write-ZLagFloorLog ('Persistent non-resident watchdog installed as scheduled task: ' + $taskName)
