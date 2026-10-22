# ==============================================================================
# Z-LAG OS - Fixed-Size Pagefile (kills mid-game pagefile-growth stalls)
# ------------------------------------------------------------------------------
# WHY: with the OS-default "automatically managed" pagefile, every time RAM
#   pressure fills the working sets Windows grows the pagefile in ~100 MB
#   chunks - each growth is synchronous disk I/O that lands mid-frame in
#   games / emulators and reads as a random hitch.
# WHAT: sets a FIXED-size pagefile on the system drive (initial = maximum),
#   so the pagefile can never grow (or shrink) during gameplay:
#       size = clamp(physical RAM, 4 GB, 16 GB)
#   * 4 GB floor is a policy choice, NOT a guarantee for crash dumps or workloads
#   * Fixed caps can exhaust commit under heavy workloads; system-managed may be better
# SAFE GUARDS (skip cleanly, never break):
#   * only touches the pagefile on the SYSTEM drive (from $env:SystemDrive)
#   * requires >= (pagefile size + 8 GB) free space on the system drive
#   * leaves the current configuration untouched when any guard fails
# Takes effect after the next reboot (the playbook reboots at the end).
# Idempotent. Logs to C:\ProgramData\Z-LAG-OS\pagefile.log
# ==============================================================================
$ErrorActionPreference = 'Continue'

$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir 'pagefile.log'

function Log {
    param([string]$m)
    $line = '[{0}] [Z-LAG-PAGEFILE] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Log 'ERROR: Administrator privileges required.'
    exit 1
}

# --- 1. Target size from physical RAM ------------------------------------------
$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if (-not $cs -or -not $cs.TotalPhysicalMemory) {
    Log 'ERROR: could not read physical memory size; skipping.'
    exit 0
}
$ramMB = [int64]($cs.TotalPhysicalMemory / 1MB)
$sizeMB = [int][Math]::Max(4096, [Math]::Min(16384, $ramMB))
Log ('Physical RAM: ' + $ramMB + ' MB -> fixed pagefile size: ' + $sizeMB + ' MB')

# --- 2. Guards ------------------------------------------------------------------
$systemDrive = $env:SystemDrive
if ($systemDrive -notmatch '^[A-Za-z]:$') { Log 'ERROR: invalid system drive.'; exit 1 }
$pagefilePath = Join-Path ($systemDrive + '\') 'pagefile.sys'
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue
if (-not $disk) {
    Log 'WARNING: system drive not found; skipping.'
    exit 0
}
$freeMB = [int64]($disk.FreeSpace / 1MB)
if ($freeMB -lt ($sizeMB + 8192)) {
    Log ('WARNING: not enough free space on the system drive: (free=' + $freeMB + ' MB, need ~' + ($sizeMB + 8192) + ' MB); keeping current pagefile.')
    exit 0
}

# Only manage the pagefile on the system drive.
# NOTE: a system-managed ("automatically managed size") entry reports
# InitialSize=0/MaximumSize=0 - it must NOT be treated as a fixed-size choice.
$existing = @(Get-CimInstance -ClassName Win32_PageFileSet -Namespace 'root/cimv2' -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $pagefilePath })
if ($existing.Count -gt 0) {
    if ($existing[0].InitialSize -eq $sizeMB -and $existing[0].MaximumSize -eq $sizeMB) {
        Log 'Fixed pagefile already configured - no changes.'
        exit 0
    }
    if ($existing[0].InitialSize -gt 0 -and $existing[0].InitialSize -eq $existing[0].MaximumSize) {
        Log ('Existing user-fixed pagefile on system drive: (' + $existing[0].InitialSize + ' MB) respected - leaving it.')
        exit 0
    }
}

# --- 3. Apply with rollback ----------------------------------------------------
$wasAutomatic = [bool]$cs.AutomaticManagedPagefile
$oldInitial = if ($existing.Count) { $existing[0].InitialSize } else { 0 }
$oldMaximum = if ($existing.Count) { $existing[0].MaximumSize } else { 0 }
$created = $null
try {
    # Set-CimInstance has no -ClassName parameter. Update the queried instance;
    # use New-CimInstance when no PageFileSet exists yet.
    if ($wasAutomatic) {
        Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $false } -ErrorAction Stop | Out-Null
    }
    if ($existing.Count -gt 0) {
        Set-CimInstance -InputObject $existing[0] -Property @{ InitialSize = $sizeMB; MaximumSize = $sizeMB } -ErrorAction Stop | Out-Null
    } else {
        $created = New-CimInstance -ClassName Win32_PageFileSet -Namespace 'root/cimv2' -Property @{
            Name = $pagefilePath; InitialSize = [uint32]$sizeMB; MaximumSize = [uint32]$sizeMB
        } -ErrorAction Stop
    }
    $verified = @(Get-CimInstance -ClassName Win32_PageFileSet -ErrorAction Stop | Where-Object { $_.Name -eq $pagefilePath })
    if ($verified.Count -ne 1 -or $verified[0].InitialSize -ne $sizeMB -or $verified[0].MaximumSize -ne $sizeMB) {
        throw 'Pagefile configuration verification failed.'
    }
    Log ('Fixed-size pagefile configured: ' + $pagefilePath + ' initial=maximum=' + $sizeMB + ' MB. Takes effect after reboot.')
} catch {
    Log ('ERROR: pagefile change failed: ' + $_.Exception.Message + '; attempting rollback.')
    try {
        if ($created) { Remove-CimInstance -InputObject $created -ErrorAction Stop }
        if ($existing.Count) {
            Set-CimInstance -InputObject $existing[0] -Property @{ InitialSize = $oldInitial; MaximumSize = $oldMaximum } -ErrorAction Stop | Out-Null
        }
        Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $wasAutomatic } -ErrorAction Stop | Out-Null
        Log 'Previous pagefile settings restored.'
    } catch { Log ('ERROR: rollback failed; check Virtual Memory settings: ' + $_.Exception.Message) }
    exit 1
}
exit 0
