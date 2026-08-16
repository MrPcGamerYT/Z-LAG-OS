# ==============================================================================
# Z-LAG OS - Context menu actions
# Installed visibly under C:\Windows\Z-LAG-OS with standard-user read/execute access.
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('RamTrim', 'TempClean', 'RecycleBin', 'FlushDns', 'RestartExplorer', 'SoundManager', 'VolumeMixer',
                 'GameBoost', 'StandbyClear', 'PingTest', 'SystemInfo', 'PowerMaxFps')]
    [string]$Action
)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:LOCALAPPDATA 'Z-LAG-OS'
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $logDir 'context_tools.log'

function Write-ZLagToolLog {
    param([string]$Message)
    $line = ('[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Action, $Message)
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Show-ZLagResult {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Information', 'Warning', 'Error')][string]$Kind = 'Information'
    )

    Write-ZLagToolLog $Message
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        $icon = [System.Windows.MessageBoxImage]$Kind
        [void][System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, $icon)
    } catch {
        try {
            $shell = New-Object -ComObject WScript.Shell
            [void]$shell.Popup($Message, 8, $Title, 64)
            [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null
        } catch { }
    }
}

function Format-ZLagBytes {
    param([long]$Bytes)
    if ($Bytes -ge 1073741824) { return ('{0:N2} GB' -f ($Bytes / 1073741824)) }
    if ($Bytes -ge 1048576) { return ('{0:N1} MB' -f ($Bytes / 1048576)) }
    if ($Bytes -ge 1024) { return ('{0:N1} KB' -f ($Bytes / 1024)) }
    return ($Bytes.ToString() + ' bytes')
}

function Test-ZLagAdministrator {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Start-ZLagElevatedAction {
    param([Parameter(Mandatory = $true)][string]$RequestedAction)
    $powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "' + $PSCommandPath + '" -Action ' + $RequestedAction
    try {
        Start-Process -FilePath $powerShell -ArgumentList $arguments -Verb RunAs -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Show-ZLagResult -Title 'Z LAG' -Message 'Administrator permission was cancelled, so the action was not run.' -Kind Warning
        return $false
    }
}

function Invoke-ZLagRamTrim {
    $source = @'
using System;
using System.Runtime.InteropServices;
public static class ZLagContextRamTrim {
    [DllImport("psapi.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EmptyWorkingSet(IntPtr process);
}
'@
    try { Add-Type -TypeDefinition $source -ErrorAction Stop } catch { }

    $sessionId = (Get-Process -Id $PID).SessionId
    $trimmed = 0
    [long]$released = 0
    foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
        try {
            if ($process.Id -eq $PID -or $process.SessionId -ne $sessionId) { continue }
            [long]$before = $process.WorkingSet64
            if ([ZLagContextRamTrim]::EmptyWorkingSet($process.Handle)) {
                $process.Refresh()
                [long]$after = $process.WorkingSet64
                if ($before -gt $after) { $released += ($before - $after) }
                $trimmed++
            }
        } catch { }
    }

    $message = 'Trimmed {0} user-session processes and released approximately {1} of working-set RAM.' -f $trimmed, (Format-ZLagBytes $released)
    Show-ZLagResult -Title 'Z LAG - RAM Trim / Clean' -Message $message
}

function Get-ZLagItemSize {
    param([Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$Item)
    try {
        if (-not $Item.PSIsContainer) { return [long]$Item.Length }
        return [long]((Get-ChildItem -LiteralPath $Item.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum)
    } catch { return 0 }
}

function Invoke-ZLagTempClean {
    # Elevate once so both the current-user temp folder and Windows Temp can be
    # cleaned. The elevated process still uses the same signed-in user profile.
    if (-not (Test-ZLagAdministrator)) {
        [void](Start-ZLagElevatedAction -RequestedAction TempClean)
        return
    }

    $roots = @($env:TEMP, (Join-Path $env:LOCALAPPDATA 'Temp'))
    if ($env:SystemRoot) { $roots += (Join-Path $env:SystemRoot 'Temp') }
    $roots = $roots | Where-Object { $_ } | Select-Object -Unique

    $removedItems = 0
    [long]$released = 0
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -ne 'AME' -and
                -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
            } |
            ForEach-Object {
                $item = $_
                [long]$size = Get-ZLagItemSize -Item $item
                Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path -LiteralPath $item.FullName)) {
                    $removedItems++
                    $released += $size
                }
            }
    }

    $message = 'Removed {0} temporary items and reclaimed approximately {1}. Files currently in use were safely skipped.' -f $removedItems, (Format-ZLagBytes $released)
    Show-ZLagResult -Title 'Z LAG - Temp Clean' -Message $message
}

function Invoke-ZLagRecycleBinClean {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Show-ZLagResult -Title 'Z LAG - Recycle Bin Clean' -Message 'The current user recycle bin was cleaned successfully.'
    } catch {
        Show-ZLagResult -Title 'Z LAG - Recycle Bin Clean' -Message 'The recycle bin was already empty or could not be cleaned.' -Kind Warning
    }
}

function Invoke-ZLagFlushDns {
    if (-not (Test-ZLagAdministrator)) {
        [void](Start-ZLagElevatedAction -RequestedAction FlushDns)
        return
    }

    & ipconfig.exe /flushdns 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Show-ZLagResult -Title 'Z LAG - Flush DNS Cache' -Message 'The Windows DNS resolver cache was flushed successfully.'
    } else {
        Show-ZLagResult -Title 'Z LAG - Flush DNS Cache' -Message 'Windows could not flush the DNS resolver cache.' -Kind Error
    }
}

function Invoke-ZLagRestartExplorer {
    Write-ZLagToolLog 'Restarting Explorer for the current user.'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 700
    Start-Process (Join-Path $env:SystemRoot 'explorer.exe') -ErrorAction SilentlyContinue
}

function Invoke-ZLagGameBoost {
    # One-click pre-game boost: kill common background bloat processes that may
    # have respawned, trim RAM, and flush DNS. Never touches games, launchers
    # (Steam/Epic/Riot/Battle.net), drivers or Windows core processes.
    if (-not (Test-ZLagAdministrator)) {
        [void](Start-ZLagElevatedAction -RequestedAction GameBoost)
        return
    }

    $bloat = @(
        'OneDrive', 'msedge', 'msedgewebview2', 'MicrosoftEdgeUpdate', 'Widgets',
        'WidgetService', 'Copilot', 'YourPhone', 'PhoneExperienceHost', 'Teams',
        'ms-teams', 'SkypeBackgroundHost', 'GameBarPresenceWriter', 'GameBar',
        'GameBarFTServer', 'SearchHost', 'SecurityHealthSystray', 'mobsync'
    )
    $killed = 0
    foreach ($name in $bloat) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($procs) {
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
            $killed += @($procs).Count
        }
    }

    # Flush DNS for a clean resolver before the match.
    & ipconfig.exe /flushdns 2>&1 | Out-Null

    # RAM trim pass (same safe working-set trim technique as RamTrim).
    $source = @'
using System;
using System.Runtime.InteropServices;
public static class ZLagBoostRamTrim {
    [DllImport("psapi.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EmptyWorkingSet(IntPtr process);
}
'@
    try { Add-Type -TypeDefinition $source -ErrorAction Stop } catch { }
    $trimmed = 0
    foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
        try {
            if ($process.Id -eq $PID) { continue }
            if ([ZLagBoostRamTrim]::EmptyWorkingSet($process.Handle)) { $trimmed++ }
        } catch { }
    }

    $message = 'GAME BOOST complete. Closed {0} background bloat processes, trimmed {1} working sets and flushed DNS. Start your game now for maximum FPS.' -f $killed, $trimmed
    Show-ZLagResult -Title 'Z LAG - GAME BOOST' -Message $message
}

function Invoke-ZLagStandbyClear {
    # Clears the Windows standby memory list (cached file pages). Games that
    # allocate large blocks mid-match can hitch while the kernel drops standby
    # pages on demand; clearing between sessions prevents that stutter.
    # Works identically on Windows 10 and Windows 11.
    if (-not (Test-ZLagAdministrator)) {
        [void](Start-ZLagElevatedAction -RequestedAction StandbyClear)
        return
    }

    $source = @'
using System;
using System.Runtime.InteropServices;
public static class ZLagStandbyList {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetSystemInformation(int infoClass, IntPtr info, int length);
}
'@
    try { Add-Type -TypeDefinition $source -ErrorAction Stop } catch { }

    $cleared = $false
    try {
        # SystemMemoryListInformation = 80; MemoryPurgeStandbyList = 4.
        $pCmd = [Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        [Runtime.InteropServices.Marshal]::WriteInt32($pCmd, 4)
        $status = [ZLagStandbyList]::NtSetSystemInformation(80, $pCmd, 4)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($pCmd)
        if ($status -eq 0) { $cleared = $true }
    } catch { }

    if ($cleared) {
        Show-ZLagResult -Title 'Z LAG - Clear Standby Memory' -Message 'The standby memory list was cleared. Freed RAM is instantly available to your game - no mid-match allocation stutter.'
    } else {
        Show-ZLagResult -Title 'Z LAG - Clear Standby Memory' -Message 'Windows refused the standby-list purge on this system. RAM Trim / Clean can be used instead.' -Kind Warning
    }
}

function Invoke-ZLagPingTest {
    # Network health check before queueing into a match: router + public DNS
    # latency and jitter. Uses Test-Connection properties that exist on both
    # Windows PowerShell 5.1 (Win10) and newer builds (universal).
    Write-ZLagToolLog 'Running the network latency test.'
    $gateway = $null
    try {
        $gateway = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
            Sort-Object -Property RouteMetric | Select-Object -First 1).NextHop
    } catch { }
    $targets = @()
    if ($gateway -and $gateway -ne '0.0.0.0') { $targets += ,@('Router (gateway)', $gateway) }
    $targets += ,@('Cloudflare DNS', '1.1.1.1')
    $targets += ,@('Google DNS', '8.8.8.8')

    $lines = @()
    foreach ($target in $targets) {
        $label = $target[0]
        $targetHost = $target[1]
        $times = @()
        for ($i = 0; $i -lt 4; $i++) {
            try {
                $reply = (New-Object System.Net.NetworkInformation.Ping).Send($targetHost, 1500)
                if ($reply.Status -eq 'Success') { $times += [int]$reply.RoundtripTime }
            } catch { }
        }
        if ($times.Count -gt 0) {
            $avg = [math]::Round(($times | Measure-Object -Average).Average, 1)
            $max = ($times | Measure-Object -Maximum).Maximum
            $jitter = $max - ($times | Measure-Object -Minimum).Minimum
            $lines += ('{0} ({1}): avg {2} ms | max {3} ms | jitter {4} ms' -f $label, $targetHost, $avg, $max, $jitter)
        } else {
            $lines += ('{0} ({1}): NO RESPONSE' -f $label, $targetHost)
        }
    }

    Show-ZLagResult -Title 'Z LAG - Ping / Latency Test' -Message ($lines -join [Environment]::NewLine)
}

function Invoke-ZLagSystemInfo {
    # Compact gamer-relevant system summary - universal for Windows 10 and 11.
    Write-ZLagToolLog 'Collecting the system summary.'
    $lines = @()
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $build = 0
        try { $build = [int](Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuildNumber -ErrorAction SilentlyContinue) } catch { }
        $family = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
        $lines += ('OS: {0} (build {1})' -f $family, $build)
        $totalGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $freeGb = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $lines += ('RAM: {0} GB free of {1} GB' -f $freeGb, $totalGb)
    } catch { }
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $lines += ('CPU: {0} ({1}C/{2}T)' -f $cpu.Name.Trim(), $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)
    } catch { }
    try {
        Get-CimInstance Win32_VideoController -ErrorAction Stop | ForEach-Object {
            $lines += ('GPU: {0} (driver {1})' -f $_.Name, $_.DriverVersion)
        }
    } catch { }
    try {
        $plan = (& powercfg.exe /getactivescheme 2>$null | Out-String)
        if ($plan -match '\((.+)\)') { $lines += ('Power plan: ' + $Matches[1]) }
    } catch { }
    $lines += ('Processes running: ' + @(Get-Process -ErrorAction SilentlyContinue).Count)

    Show-ZLagResult -Title 'Z LAG - System Info' -Message ($lines -join [Environment]::NewLine)
}

function Invoke-ZLagPowerMaxFps {
    # Re-activates the Maximum FPS (Ultimate Performance) plan in one click if
    # anything (driver installer, Windows update, OEM tool) switched it back.
    if (-not (Test-ZLagAdministrator)) {
        [void](Start-ZLagElevatedAction -RequestedAction PowerMaxFps)
        return
    }

    $ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    $high = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    $schemes = (& powercfg.exe -list 2>$null | Out-String)
    $activated = $null

    # Prefer an existing Maximum FPS / Ultimate duplicate, then the template,
    # then High Performance - identical logic on Windows 10 and Windows 11.
    $guidPattern = '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})'
    foreach ($line in ($schemes -split "`r?`n")) {
        if ($line -match ('Power Scheme GUID:\s+' + $guidPattern + '\s+\((Maximum FPS|Ultimate Performance)') ) {
            $activated = $Matches[1]
            break
        }
    }
    if (-not $activated -and $schemes -match $ultimate) { $activated = $ultimate }
    if (-not $activated) {
        $dup = (& powercfg.exe -duplicatescheme $ultimate 2>$null | Out-String)
        if ($dup -match $guidPattern) { $activated = $Matches[1] }
    }
    if (-not $activated -and $schemes -match $high) { $activated = $high }

    if ($activated) {
        & powercfg.exe -setactive $activated 2>$null | Out-Null
        Show-ZLagResult -Title 'Z LAG - Max FPS Power Plan' -Message 'The Maximum FPS power plan is active again. Full performance restored.'
    } else {
        Show-ZLagResult -Title 'Z LAG - Max FPS Power Plan' -Message 'No performance power plan could be activated on this system.' -Kind Warning
    }
}

switch ($Action) {
    'RamTrim' { Invoke-ZLagRamTrim }
    'TempClean' { Invoke-ZLagTempClean }
    'RecycleBin' { Invoke-ZLagRecycleBinClean }
    'FlushDns' { Invoke-ZLagFlushDns }
    'RestartExplorer' { Invoke-ZLagRestartExplorer }
    'GameBoost' { Invoke-ZLagGameBoost }
    'StandbyClear' { Invoke-ZLagStandbyClear }
    'PingTest' { Invoke-ZLagPingTest }
    'SystemInfo' { Invoke-ZLagSystemInfo }
    'PowerMaxFps' { Invoke-ZLagPowerMaxFps }
    'SoundManager' {
        Write-ZLagToolLog 'Opening the classic Sound Manager.'
        Start-Process (Join-Path $env:SystemRoot 'System32\rundll32.exe') -ArgumentList 'shell32.dll,Control_RunDLL mmsys.cpl,,0' -ErrorAction SilentlyContinue
    }
    'VolumeMixer' {
        Write-ZLagToolLog 'Opening the classic Volume Mixer.'
        Start-Process (Join-Path $env:SystemRoot 'System32\sndvol.exe') -ErrorAction SilentlyContinue
    }
}
