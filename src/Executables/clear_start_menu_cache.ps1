# ==============================================================================
# Z-LAG OS - Clear Start Menu cache (remove ghost tiles for deleted apps)
# ------------------------------------------------------------------------------
# When an AppX app, Edge, or the Store is removed, the Start Menu keeps a
# cached tile / entry in start.bin + the StartMenuExperienceHost settings.
# The result: the app icon is still listed but does nothing when clicked
# ("showing but not opening"). Clearing this cache makes the ghost entries
# vanish immediately (and after the final reboot they stay gone).
#
# Safe to run repeatedly. Works for ALL user profiles + the Default profile.
# ==============================================================================
$ErrorActionPreference = "Continue"

function Log([string]$m) { Write-Host "[Z-LAG-SM] $m" }

# 1. Stop the Start Menu hosts so their caches are released (they auto-restart
#    in the user's session; we deliberately do NOT touch explorer here).
foreach ($p in @("StartMenuExperienceHost","SearchApp","ShellExperienceHost")) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}

# 2. Collect every user profile root + the Default profile template.
$roots = @("$env:SystemDrive\Users\Default")
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -ErrorAction SilentlyContinue | ForEach-Object {
    $pi = (Get-ItemProperty -Path $_.PSPath -Name "ProfileImagePath" -ErrorAction SilentlyContinue).ProfileImagePath
    if ($pi -and (Test-Path $pi)) { $roots += $pi }
}
$roots = $roots | Where-Object { $_ } | Select-Object -Unique

# 3. Delete the Start Menu cache files in every profile.
#    start.bin  = Windows 10 / early Win11 pinned-tile cache
#    start2.bin = Windows 11 22H2+ pinned-tile cache (the one that matters now)
#    The glob covers both plus any future startN.bin variant.
$cleared = 0
foreach ($r in $roots) {
    $base = Join-Path $r "AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
    $localState = Join-Path $base "LocalState"
    if (Test-Path $localState) {
        Get-ChildItem -Path (Join-Path $localState "start*.bin") -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $_.FullName)) { $cleared++ }
        }
    }
    foreach ($rel in @("Settings\settings.dat", "LocalState\StartMenuExperienceHost.settings")) {
        $p = Join-Path $base $rel
        if (Test-Path $p) {
            Remove-Item $p -Force -ErrorAction SilentlyContinue
            $cleared++
        }
    }
}

Log "Cleared $cleared Start Menu cache files across $($roots.Count) profiles."
Log "Removed apps (and Edge / Store) will no longer show ghost tiles."
