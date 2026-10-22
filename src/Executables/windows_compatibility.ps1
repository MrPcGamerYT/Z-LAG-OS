# Shared, non-resident build checks. Dot-source; no Windows settings changed.
$ErrorActionPreference = 'Continue'

function Get-ZLagWindowsBuild {
    $build = 0
    $version = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    foreach ($value in @($version.CurrentBuildNumber, $version.CurrentBuild)) {
        if ([int]::TryParse([string]$value, [ref]$build) -and $build -ge 10240) { return $build }
    }
    Write-Warning '[Z-LAG] Windows build could not be identified; build-specific tweaks will be skipped.'
    return 0
}

function Get-ZLagWindowsCompatibility {
    param([int]$Build)
    # Build classification for Windows client installations, not Server support.
    [PSCustomObject]@{
        Build = $Build
        IsWindows10 = ($Build -ge 10240 -and $Build -lt 22000)
        IsWindows11 = ($Build -ge 22000)
        SupportsHags = ($Build -ge 19041)
        SupportsTaskbarSi = ($Build -ge 22000 -and $Build -lt 22621)
    }
}

function Enable-ZLagTaskbarAutoHide {
    param([AllowNull()][byte[]]$Settings)
    # Only known layouts with a matching size header. Never invent a taskbar
    # geometry blob for a different build, display topology or future format.
    if ($null -eq $Settings -or $Settings.Length -notin @(40, 48) -or
        [BitConverter]::ToInt32($Settings, 0) -ne $Settings.Length) {
        Write-Warning '[Z-LAG] Taskbar settings format absent/unknown; leaving auto-hide unchanged.'
        return $null
    }
    [byte[]]$updated = $Settings.Clone()
    $updated[8] = $updated[8] -bor 1
    return ,$updated
}
