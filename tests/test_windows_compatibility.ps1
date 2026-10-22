# Pure compatibility tests: no registry, service or process changes.
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/Executables/windows_compatibility.ps1')
$ErrorActionPreference = 'Stop'
function Assert-Compat {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
foreach ($build in @(0, 9600, 10240, 14393, 17763, 18363, 19041, 19045, 21999, 22000, 22621, 22631, 26100, 26200, 30000)) {
    $caps = Get-ZLagWindowsCompatibility -Build $build
    Assert-Compat ($caps.IsWindows10 -eq ($build -ge 10240 -and $build -lt 22000)) "Win10 classification failed: $build"
    Assert-Compat ($caps.IsWindows11 -eq ($build -ge 22000)) "Win11 classification failed: $build"
    Assert-Compat ($caps.SupportsHags -eq ($build -ge 19041)) "HAGS build gate failed: $build"
    Assert-Compat ($caps.SupportsTaskbarSi -eq ($build -ge 22000 -and $build -lt 22621)) "Legacy taskbar-size gate failed: $build"
}
foreach ($size in @(40, 48)) {
    [byte[]]$settings = New-Object byte[] $size
    [Array]::Copy([BitConverter]::GetBytes([int]$size), $settings, 4)
    $settings[8] = 6
    $settings[12] = 127
    $result = Enable-ZLagTaskbarAutoHide -Settings $settings
    Assert-Compat ($result -is [byte[]]) 'Result must remain a byte array.'
    Assert-Compat ($result[8] -eq 7) 'Auto-hide flag must preserve other bits.'
    Assert-Compat ($settings[8] -eq 6) 'Input layout must not be mutated.'
    Assert-Compat ($result[12] -eq 127) 'Unrelated layout bytes must be preserved.'
    $again = Enable-ZLagTaskbarAutoHide -Settings $result
    Assert-Compat ($again[8] -eq 7) 'Auto-hide must be idempotent.'
}
Assert-Compat ($null -eq (Enable-ZLagTaskbarAutoHide -Settings $null)) 'Missing layout must be skipped.'
Assert-Compat ($null -eq (Enable-ZLagTaskbarAutoHide -Settings (New-Object byte[] 64))) 'Unknown layout must be skipped.'
Assert-Compat ($null -eq (Enable-ZLagTaskbarAutoHide -Settings (New-Object byte[] 48))) 'Invalid size header must be skipped.'
Write-Host 'PASS: build capability matrix and taskbar layout preservation (not a Windows installation compatibility certification).'
