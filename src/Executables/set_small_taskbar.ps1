# ==============================================================================
# Z-LAG OS - Universal Small / Auto-Hide Taskbar  (Windows 10 AND Windows 11)
# Detects the running build and applies the correct tweaks per OS, so the same
# playbook works perfectly on both.
# ==============================================================================

$ErrorActionPreference = "SilentlyContinue"

$build = [int](Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "CurrentBuildNumber" -ErrorAction SilentlyContinue)
if (-not $build) { $build = 0 }
$isWin11 = $build -ge 22000

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }

if ($isWin11) {
    Write-Host "[Z-LAG] Windows 11 (build $build) - applying Win11 taskbar tweaks"
    Set-ItemProperty -Path $adv -Name "TaskbarAl"           -Value 0 -Type DWord -Force   # left-align icons
    Set-ItemProperty -Path $adv -Name "TaskbarSi"           -Value 0 -Type DWord -Force   # small taskbar (21H2; harmless on 22H2+)
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
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Value 0 -Type DWord -Force
}

# --- Auto-hide taskbar (works on BOTH Win10 and Win11) ---
# Flip byte index 8 of StuckRects3\Settings to 0x03. This preserves each OS's own
# taskbar layout/position instead of hard-coding one OS's binary blob.
$stuckKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (-not (Test-Path $stuckKey)) { New-Item -Path $stuckKey -Force | Out-Null }
$settings = (Get-ItemProperty -Path $stuckKey -Name "Settings" -ErrorAction SilentlyContinue).Settings
if ($null -eq $settings) {
    $settings = [byte[]]@(0x30,0,0,0,0xFE,0xFF,0xFF,0xFF,0x03,0,0,0,0x03,0,0,0,0x3E,0,0,0,0x28,0,0,0,0,0,0,0,0x10,0x04,0,0,0x80,0x07,0,0,0x38,0x04,0,0,0x60,0,0,0)
}
if ($settings.Length -gt 8) {
    $settings[8] = 0x03
    Set-ItemProperty -Path $stuckKey -Name "Settings" -Value $settings -Type Binary -Force
}

# Restart Explorer to apply
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "[Z-LAG] Universal taskbar config applied (build $build)."
