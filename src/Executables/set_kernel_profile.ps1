# Reversible Windows 10/11 client scheduler/memory profile. No resident process.
[CmdletBinding()]
param([switch]$Restore)
$ErrorActionPreference = 'Stop'

function Get-ZLagKernelProfile {
    $memory = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    @(
        [PSCustomObject]@{ Path = $memory; Name = 'DisablePagingExecutive'; Value = 0 },
        [PSCustomObject]@{ Path = $memory; Name = 'LargeSystemCache'; Value = 0 },
        [PSCustomObject]@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Value = 38 },
        [PSCustomObject]@{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name = 'SystemResponsiveness'; Value = 10 }
    )
}

function Get-ZLagKernelValue {
    param($Setting)
    $key = Get-Item -LiteralPath $Setting.Path -ErrorAction Stop
    $exists = $key.GetValueNames() -contains $Setting.Name
    if ($exists -and $key.GetValueKind($Setting.Name).ToString() -ne 'DWord') {
        throw ('Unexpected registry type; refusing to overwrite ' + $Setting.Name)
    }
    [PSCustomObject]@{
        Path = $Setting.Path; Name = $Setting.Name; Exists = $exists
        Value = $(if ($exists) { $key.GetValue($Setting.Name) } else { $null })
    }
}

function Restore-ZLagKernelValue {
    param($Original)
    if ($Original.Exists) {
        New-ItemProperty -LiteralPath $Original.Path -Name $Original.Name -Value ([int]$Original.Value) -PropertyType DWord -Force -ErrorAction Stop | Out-Null
    } else {
        $key = Get-Item -LiteralPath $Original.Path -ErrorAction Stop
        if ($key.GetValueNames() -contains $Original.Name) {
            Remove-ItemProperty -LiteralPath $Original.Path -Name $Original.Name -ErrorAction Stop
        }
    }
}

function Read-ZLagKernelSnapshot {
    param([string]$Path, [object[]]$Profile)
    $snapshot = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($snapshot.Version -ne 1 -or @($snapshot.Values).Count -ne $Profile.Count) { throw 'Invalid kernel-profile snapshot.' }
    # Validate every row BEFORE changing anything. Never trust a snapshot to
    # supply arbitrary registry targets, and never overwrite newer user edits.
    foreach ($setting in $Profile) {
        $rows = @($snapshot.Values | Where-Object { $_.Name -eq $setting.Name -and $_.Path -eq $setting.Path })
        if ($rows.Count -ne 1 -or $rows[0].Exists -isnot [bool] -or
            ($rows[0].Exists -and $rows[0].Value -isnot [int] -and $rows[0].Value -isnot [long])) { throw 'Invalid snapshot row.' }
        if ($rows[0].Exists -and ($rows[0].Value -lt [int]::MinValue -or $rows[0].Value -gt [int]::MaxValue)) { throw 'Invalid DWORD snapshot value.' }
    }
    return $snapshot
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Error 'Administrator or SYSTEM required.'; exit 1 }
. (Join-Path $PSScriptRoot 'windows_compatibility.ps1')
$ErrorActionPreference = 'Stop'
$compat = Get-ZLagWindowsCompatibility -Build (Get-ZLagWindowsBuild)
if (-not ($compat.IsWindows10 -or $compat.IsWindows11)) {
    Write-Warning '[Z-LAG] Unknown Windows build; kernel profile skipped.'
    exit 0
}
$profile = @(Get-ZLagKernelProfile)
$dataDir = Join-Path $env:ProgramData 'Z-LAG-Backups'
$backupPath = Join-Path $dataDir 'kernel-profile-original.json'
$before = @()
$mutationStarted = $false
try {
    # Require existing keys, never invent an unsupported subsystem.
    $before = @($profile | ForEach-Object { Get-ZLagKernelValue -Setting $_ })
    if ($Restore) {
        if (-not (Test-Path -LiteralPath $backupPath)) { throw 'No original kernel-profile snapshot exists.' }
        $snapshot = Read-ZLagKernelSnapshot -Path $backupPath -Profile $profile
        $mutationStarted = $true
        foreach ($setting in $profile) {
            $current = Get-ZLagKernelValue -Setting $setting
            if (-not $current.Exists -or $current.Value -ne $setting.Value) {
                Write-Warning ('[Z-LAG] User/system changed ' + $setting.Name + '; not overwriting it during restore.')
                continue
            }
            $original = $snapshot.Values | Where-Object { $_.Name -eq $setting.Name -and $_.Path -eq $setting.Path }
            Restore-ZLagKernelValue -Original $original
        }
        Write-Output '[Z-LAG] Original kernel settings restored where still owned by this profile. Reboot before comparison.'
        exit 0
    }
    New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $backupPath)) {
        # First snapshot stays immutable across reapply. A failed snapshot aborts
        # before any tuning; restore never depends on a registry export elsewhere.
        [PSCustomObject]@{ Version = 1; Values = $before } | ConvertTo-Json -Depth 4 |
            Out-File -LiteralPath $backupPath -Encoding UTF8 -NoClobber
    }
    $snapshot = Read-ZLagKernelSnapshot -Path $backupPath -Profile $profile
    $mutationStarted = $true
    foreach ($setting in $profile) {
        New-ItemProperty -LiteralPath $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType DWord -Force | Out-Null
        $after = Get-ZLagKernelValue -Setting $setting
        if (-not $after.Exists -or $after.Value -ne $setting.Value) { throw ('Verification failed: ' + $setting.Name) }
    }
    # Keep the reversible tool available after AME removes its temporary files.
    $runtimeDir = Join-Path $env:SystemRoot 'Z-LAG-OS'
    New-Item -Path $runtimeDir -ItemType Directory -Force | Out-Null
    foreach ($name in @('set_kernel_profile.ps1', 'windows_compatibility.ps1')) {
        $source = Join-Path $PSScriptRoot $name
        $destination = Join-Path $runtimeDir $name
        if (-not [IO.Path]::GetFullPath($source).Equals([IO.Path]::GetFullPath($destination), [StringComparison]::OrdinalIgnoreCase)) {
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }
    }
    Write-Output ('[Z-LAG] Kernel profile verified. Snapshot: ' + $backupPath + '. Reboot and benchmark frame times; no FPS guarantee.')
} catch {
    Write-Warning ('[Z-LAG] Kernel profile failed: ' + $_.Exception.Message)
    if ($mutationStarted) {
        foreach ($original in $before) {
            try { Restore-ZLagKernelValue -Original $original } catch { Write-Warning ('Rollback failed: ' + $original.Name) }
        }
    }
    exit 1
}
