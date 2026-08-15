# ==============================================================================
# Z-LAG OS - Bluetooth keep-mode repair
# ------------------------------------------------------------------------------
# Runs only when bluetooth-keep was selected. The aggressive floor used to
# disable CDPSvc/CDPUserSvc/NcbService, which left the Bluetooth radio present
# but broke Windows' Add Device dialog. This restores the complete radio/pairing
# chain, enables disabled Bluetooth PnP devices, and rechecks at boot/logon.
# ==============================================================================

[CmdletBinding()]
param([switch]$RepairOnly)

$ErrorActionPreference = 'Continue'
$installDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $installDir 'bluetooth_repair.log'

function Write-ZLagBluetoothLog {
    param([string]$Message)
    $line = '[{0}] [Z-LAG-BLUETOOTH] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-ZLagBluetoothLog 'ERROR: Administrator or SYSTEM privileges are required.'
    exit 1
}

# Automatic owners keep the Settings radio and pairing broker available. The
# remaining services stay demand-start and add no permanent idle process unless
# Bluetooth pairing/audio actually needs them.
$serviceFamilies = @(
    [pscustomobject]@{ Name = 'bthserv'; Mode = 'auto'; StartNow = $true },
    [pscustomobject]@{ Name = 'RmSvc'; Mode = 'auto'; StartNow = $true },
    [pscustomobject]@{ Name = 'CDPSvc'; Mode = 'auto'; StartNow = $true },
    [pscustomobject]@{ Name = 'BluetoothUserService'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'CDPUserSvc'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'NcbService'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'BTAGService'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'BthAvctpSvc'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'bthHFSrv'; Mode = 'demand'; StartNow = $false },
    [pscustomobject]@{ Name = 'bthpriv'; Mode = 'demand'; StartNow = $false },
    [pscustomobject]@{ Name = 'DeviceAssociationService'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'DeviceAssociationBrokerSvc'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'DevicePickerUserSvc'; Mode = 'demand'; StartNow = $false },
    [pscustomobject]@{ Name = 'DevicesFlowUserSvc'; Mode = 'demand'; StartNow = $true },
    [pscustomobject]@{ Name = 'DeviceInstall'; Mode = 'demand'; StartNow = $false },
    [pscustomobject]@{ Name = 'DsmSvc'; Mode = 'demand'; StartNow = $false }
)

function Repair-ZLagServiceFamily {
    param(
        [string]$Name,
        [ValidateSet('auto', 'demand')][string]$Mode,
        [bool]$StartNow
    )

    $startValue = if ($Mode -eq 'auto') { 2 } else { 3 }
    $root = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    $keys = Get-ChildItem -Path $root -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -eq $Name -or $_.PSChildName -like ($Name + '_*') }

    foreach ($key in $keys) {
        $instanceName = $key.PSChildName
        New-ItemProperty -Path $key.PSPath -Name Start -Value $startValue -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
        & sc.exe config $instanceName start= $Mode 2>$null | Out-Null
        if ($StartNow) { Start-Service -Name $instanceName -ErrorAction SilentlyContinue }
    }
}

function Invoke-ZLagBluetoothRepair {
    foreach ($entry in $serviceFamilies) {
        Repair-ZLagServiceFamily -Name $entry.Name -Mode $entry.Mode -StartNow $entry.StartNow
    }

    # Reverse any PnP disable state left by an older Bluetooth-removal pass.
    $enabledDevices = 0
    if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {
        Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -ne 'OK' } |
            ForEach-Object {
                try {
                    Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction Stop | Out-Null
                    $enabledDevices++
                } catch { }
            }
    }
    & pnputil.exe /scan-devices 2>$null | Out-Null

    # Reassert the service owners after the PnP scan creates per-user instances.
    foreach ($name in @('RmSvc', 'bthserv', 'CDPSvc', 'NcbService', 'DeviceAssociationService')) {
        Start-Service -Name $name -ErrorAction SilentlyContinue
    }
    foreach ($pattern in @('BluetoothUserService*', 'CDPUserSvc*', 'DeviceAssociationBrokerSvc*', 'DevicesFlowUserSvc*')) {
        Get-Service -Name $pattern -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue
    }

    $marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
    New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $marker -Name 'BluetoothKeepRepaired' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $marker -Name 'BluetoothRepairLastRun' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

    $radioStatus = (Get-Service -Name bthserv -ErrorAction SilentlyContinue).Status
    $deviceCount = 0
    if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {
        $deviceCount = @(Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue).Count
    }
    Write-ZLagBluetoothLog ('Pairing chain restored; detected devices={0}, newly enabled={1}, bthserv={2}.' -f $deviceCount, $enabledDevices, $radioStatus)
}

if ($RepairOnly) {
    Invoke-ZLagBluetoothRepair
    exit 0
}

$installedScript = Join-Path $installDir 'repair_bluetooth.ps1'
Copy-Item -LiteralPath $PSCommandPath -Destination $installedScript -Force -ErrorAction Stop
& icacls.exe $installedScript /inheritance:r /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' '*S-1-5-32-545:RX' /q 2>$null | Out-Null

$taskName = 'ZLAG-RepairBluetooth'
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $installedScript + '" -RepairOnly'
$action = New-ScheduledTaskAction -Execute $powerShell -Argument $arguments
$triggerBoot = New-ScheduledTaskTrigger -AtStartup
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
try { $triggerBoot.Delay = 'PT8S' } catch { }
try { $triggerLogon.Delay = 'PT8S' } catch { }
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 3)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($triggerBoot, $triggerLogon) -Principal $principal -Settings $settings -Force | Out-Null

Invoke-ZLagBluetoothRepair
Write-ZLagBluetoothLog ('Boot/logon repair installed as scheduled task: ' + $taskName)
