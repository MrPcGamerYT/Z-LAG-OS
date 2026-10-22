# ==============================================================================
# Z-LAG OS - GPU-Aware Hardware-Accelerated GPU Scheduling (HAGS)
# ------------------------------------------------------------------------------
# HwSchMode=2 enables HAGS; HwSchMode=1 disables it.
# This policy requests HAGS for recognized modern adapters. The driver/Windows
# build must support it; a model name alone cannot prove support or an FPS gain.
# Unknown/legacy adapters retain their existing preference. Benchmark on the
# target machine; HAGS can improve or worsen frame times depending on workload.
# Applies after the next reboot (the playbook reboots at the end).
# Idempotent. Logs to C:\ProgramData\Z-LAG-OS\gpu_scheduling.log
# ==============================================================================
$ErrorActionPreference = 'Continue'

$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir 'gpu_scheduling.log'

function Log {
    param([string]$m)
    $line = '[{0}] [Z-LAG-GPU-SCHED] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Log 'ERROR: Administrator privileges required.'
    exit 1
}

# --- 1. Detect the GPU generation ---------------------------------------------
# A system counts as MODERN when ANY of its adapters is a HAGS-friendly GPU
# (multi-GPU rigs / iGPU + dGPU are common on gaming laptops).
$gpus = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.Name })
$modern = $false
foreach ($gpu in $gpus) {
    if ($gpu -match 'RTX') { $modern = $true; break }                       # NVIDIA Turing (RTX 20) and newer
    if ($gpu -match 'AMD|Radeon') {
        if ($gpu -match 'RX [679]\d\d') { $modern = $true; break }          # AMD Navi 2 / 3 / 4 (RX 6000/7000/9000)
        continue
    }
    if ($gpu -match 'Intel') {
        if ($gpu -match 'Arc') { $modern = $true; break }                   # Intel Arc (Alchemist / Battlemage)
        continue
    }
}
foreach ($gpu in $gpus) { Log ('Detected adapter: ' + $gpu) }
if ($gpus.Count -eq 0) { Log 'WARNING: no video adapter found; leaving HAGS at the OS default.'; exit 0 }

# --- 2. Windows version --------------------------------------------------------
. (Join-Path $PSScriptRoot 'windows_compatibility.ps1')
$build = Get-ZLagWindowsBuild
$compat = Get-ZLagWindowsCompatibility -Build $build
if (-not $compat.SupportsHags) {
    Log ('HAGS requires Windows 10 build 19041 or newer; skipping build ' + $build)
    exit 0
}
Log ('OS build: ' + $build)

# --- 3. Apply the decision ------------------------------------------------------
$graphicsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
if (-not (Test-Path $graphicsKey)) { New-Item -Path $graphicsKey -Force | Out-Null }

if ($modern) {
    Set-ItemProperty -Path $graphicsKey -Name 'HwSchMode' -Value 2 -Type DWord -Force -ErrorAction Stop
    Log 'Modern GPU detected: HAGS ENABLED (HwSchMode=2). Takes effect after reboot.'
} else {
    # A model-name heuristic cannot determine driver support or the best setting.
    # Preserve the user's preference for unknown/legacy adapters.
    Log 'Unrecognized/legacy GPU: HAGS preference unchanged; driver support and performance vary.'
}
exit 0
