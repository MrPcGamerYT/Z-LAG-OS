# ==============================================================================
# Z-LAG OS - Empty Start Menu layout for the CURRENT USER (universal Win10/11)
# ------------------------------------------------------------------------------
# Runs with `runas: currentUserElevated` so HKCU/%LOCALAPPDATA% point at the
# real signed-in user (under TrustedInstaller they would point at SYSTEM).
#
# Universal strategy:
#   * BOTH     : stop StartMenuExperienceHost first (it rewrites its cache from
#                memory on exit - deleting while it runs silently undoes the
#                clean), purge CloudStore/StartPage2/TileStore tile databases.
#   * Win10    : Import-StartLayout with an empty layout (supported and
#                reliable on Win10; deprecated/no-op on Win11 so it is gated),
#                clear the legacy TileDataLayer database when present.
#   * Win11    : write an empty pinnedList LayoutModification.json into the
#                user's Shell folder and delete start*.bin (start.bin,
#                start2.bin) so the host rebuilds an empty pin grid; hide the
#                Recommended section via policy + Iris toggle.
# Idempotent - safe to run repeatedly. Explorer restart is handled by task 27.
# ==============================================================================
$ErrorActionPreference = 'Continue'

$build = 0
try {
    $build = [int](Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber' -ErrorAction SilentlyContinue)
} catch { }
$isWin11 = ($build -ge 22000)
Write-Host ("[Z-LAG-SM] Cleaning Start Menu for user '" + $env:USERNAME + "' (build " + $build + ", " + $(if ($isWin11) { 'Windows 11' } else { 'Windows 10' }) + ")...")

# --- 1. Stop the Start Menu host so caches are not rewritten from memory. ----
foreach ($hostProcess in @('StartMenuExperienceHost', 'ShellExperienceHost')) {
    Stop-Process -Name $hostProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 300

# --- 2. Purge the tile/pin registry databases (both Windows 10 and 11). ------
foreach ($path in @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultCache',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage2',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TileStore'
)) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# GamerzOS-style tile grid purge: the actual Win10 pinned-tile grid lives in
# start.tilegrid keys under CloudStore\Store\Cache\DefaultAccount. Deleting
# only DefaultCache leaves the pinned section intact - this is why the pinned
# items kept coming back on Windows 10.
$cloudAccount = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount'
if (Test-Path $cloudAccount) {
    Get-ChildItem -Path $cloudAccount -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'start\.tilegrid' } |
        ForEach-Object { Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue }
}

# Remove Start advertisements/stubs config (Win10 22H2 / Win11 23H2+).
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'Config' -Force -ErrorAction SilentlyContinue

# --- 3. Per-user layout template + pin cache. ---------------------------------
$shellDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Shell'
New-Item -Path $shellDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

if ($isWin11) {
    # Windows 11: an empty pinnedList JSON template + removing start*.bin makes
    # StartMenuExperienceHost rebuild a pin-free Start Menu on next launch.
    Set-Content -Path (Join-Path $shellDir 'LayoutModification.json') -Value '{"pinnedList":[]}' -Encoding ASCII -Force
    $packageRoot = Join-Path $env:LOCALAPPDATA 'Packages'
    Get-ChildItem -Path $packageRoot -Directory -Filter 'Microsoft.Windows.StartMenuExperienceHost*' -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem -Path (Join-Path $_.FullName 'LocalState\start*.bin') -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }

    # Hide the Recommended section (files/app suggestions under the pins).
    New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_IrisRecommendations' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
} else {
    # Windows 10: Import-StartLayout is the supported way to apply an empty
    # tile layout (the cmdlet is deprecated on Win11, hence the gate above).
    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6" />
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
    $tempFile = Join-Path $env:TEMP 'ZLagEmptyLayout.xml'
    $xml | Out-File -FilePath $tempFile -Encoding utf8 -Force
    Set-Content -Path (Join-Path $shellDir 'LayoutModification.xml') -Value $xml -Encoding UTF8 -Force
    if (Get-Command Import-StartLayout -ErrorAction SilentlyContinue) {
        try { Import-StartLayout -LayoutPath $tempFile -MountPath ($env:SystemDrive + '\') -ErrorAction SilentlyContinue } catch { }
    }
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

    # Legacy Win10 (1507-1607) tile database, present only on old builds.
    $tileDb = Join-Path $env:LOCALAPPDATA 'TileDataLayer\Database'
    if (Test-Path $tileDb) {
        Remove-Item -Path (Join-Path $tileDb '*') -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Win10 pin cache: same host package, same start.bin family.
    $packageRoot = Join-Path $env:LOCALAPPDATA 'Packages'
    Get-ChildItem -Path $packageRoot -Directory -Filter 'Microsoft.Windows.StartMenuExperienceHost*' -ErrorAction SilentlyContinue | ForEach-Object {
        Get-ChildItem -Path (Join-Path $_.FullName 'LocalState\start*.bin') -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

Write-Host '[Z-LAG-SM] Start Menu layout cleaned (pins/tiles cleared). Explorer restart applies it.'
exit 0
