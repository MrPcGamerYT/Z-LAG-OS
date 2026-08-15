# ==============================================================================
# Z-LAG OS - Context menu actions
# Installed to the hidden C:\Windows\Z-LAG-OS folder.
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('RamTrim', 'TempClean', 'RecycleBin', 'FlushDns', 'RestartExplorer', 'SoundManager', 'VolumeMixer')]
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

switch ($Action) {
    'RamTrim' { Invoke-ZLagRamTrim }
    'TempClean' { Invoke-ZLagTempClean }
    'RecycleBin' { Invoke-ZLagRecycleBinClean }
    'FlushDns' { Invoke-ZLagFlushDns }
    'RestartExplorer' { Invoke-ZLagRestartExplorer }
    'SoundManager' {
        Write-ZLagToolLog 'Opening the classic Sound Manager.'
        Start-Process (Join-Path $env:SystemRoot 'System32\rundll32.exe') -ArgumentList 'shell32.dll,Control_RunDLL mmsys.cpl,,0' -ErrorAction SilentlyContinue
    }
    'VolumeMixer' {
        Write-ZLagToolLog 'Opening the classic Volume Mixer.'
        Start-Process (Join-Path $env:SystemRoot 'System32\sndvol.exe') -ErrorAction SilentlyContinue
    }
}
