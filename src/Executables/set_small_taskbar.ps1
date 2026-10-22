# ==============================================================================
# Z-LAG OS - Universal Small / Auto-Hide Taskbar  (Windows 10 AND Windows 11)
# Detects the running build and applies the correct tweaks per OS, so the same
# optional settings are applied only where the native shell supports them.
# ==============================================================================

$ErrorActionPreference = "SilentlyContinue"

. (Join-Path $PSScriptRoot 'windows_compatibility.ps1')
$build = Get-ZLagWindowsBuild
$compat = Get-ZLagWindowsCompatibility -Build $build
if (-not ($compat.IsWindows10 -or $compat.IsWindows11)) { exit 0 }
$isWin11 = $compat.IsWindows11

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }

if ($isWin11) {
    Write-Host "[Z-LAG] Windows 11 (build $build) - applying Win11 taskbar tweaks"
    Set-ItemProperty -Path $adv -Name "TaskbarAl"           -Value 0 -Type DWord -Force   # left-align icons
    if ($compat.SupportsTaskbarSi) {
        Set-ItemProperty -Path $adv -Name "TaskbarSi" -Value 0 -Type DWord -Force
    } else {
        Write-Host '[Z-LAG] This Windows 11 build does not support the legacy small-taskbar setting; keeping native sizing.'
    }
    Set-ItemProperty -Path $adv -Name "TaskbarDa"           -Value 0 -Type DWord -Force   # hide search/copilot box
    Set-ItemProperty -Path $adv -Name "TaskbarMn"           -Value 0 -Type DWord -Force   # hide task view
    Set-ItemProperty -Path $adv -Name "ShowTaskViewButton"  -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $adv -Name "TaskbarBadges"       -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $adv -Name "ShowCopilotButton"   -Value 0 -Type DWord -Force   # hide Copilot button
} else {
    Write-Host "[Z-LAG] Windows 10 (build $build) - applying Win10 taskbar tweaks"
    Set-ItemProperty -Path $adv -Name "TaskbarSmallIcons"   -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $adv -Name "ShowTaskViewButton"  -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $adv -Name "TaskbarBadges"       -Value 0 -Type DWord -Force
    foreach ($path in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Search', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds', 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds')) {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Value 0 -Type DWord -Force
}

# Keep the existing native layout; old Win10 can use StuckRects2.
foreach ($keyName in @('StuckRects3', 'StuckRects2')) {
    $stuckKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\$keyName"
    $settings = (Get-ItemProperty -Path $stuckKey -Name Settings -ErrorAction SilentlyContinue).Settings
    if ($settings -isnot [byte[]]) { continue }
    $updatedSettings = Enable-ZLagTaskbarAutoHide -Settings $settings
    if ($null -ne $updatedSettings) {
        Set-ItemProperty -Path $stuckKey -Name Settings -Value $updatedSettings -Type Binary -Force
        break
    }
}

# Only restart Explorer in the current interactive session, not other users.
$sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
$explorers = @(Get-Process explorer -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $sessionId })
if ($sessionId -ne 0 -and $explorers.Count -gt 0) {
    $explorers | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Process explorer
}

Write-Host "[Z-LAG] Universal taskbar config applied (build $build)."
