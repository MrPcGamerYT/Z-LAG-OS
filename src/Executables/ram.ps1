<#
.SYNOPSIS
    Aggressive Memory & Process Optimization Script for Windows 10 & 11 Custom OS Mods.
    Must be run as Administrator.
#>

# 1. Force Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator! Relaunching..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  LAUNCHING ULTRA RAM DROPPER FOR WIN 10/11  " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

---

# 2. Native Win32 API Injections (Live Memory Flush)
Write-Host "[+] Initializing Win32 Working Set Purge API..." -ForegroundColor Yellow

$Win32API = @"
using System;
using System.Runtime.InteropServices;

public class MemoryOptimizer {
    [DllImport("psapi.dll", SetLastError = true)]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@

# Inject the Win32 type into the PowerShell session
Add-Type -TypeDefinition $Win32API -ErrorAction SilentlyContinue

# Loop through every running process and force it to minimize its working physical memory
Write-Host "[+] Flushing working memory sets for all active processes..." -ForegroundColor White
$Processes = Get-Process -ErrorAction SilentlyContinue
$SuccessCount = 0

foreach ($Process in $Processes) {
    if ($Process.Handle -ne [IntPtr]::Zero) {
        try {
            $Result = [MemoryOptimizer]::EmptyWorkingSet($Process.Handle)
            if ($Result) { $SuccessCount++ }
        }
        catch {
            # Catching processes that reject termination/flushing hooks (e.g., protected system drivers)
            continue;
        }
    }
}
Write-Host "[✓] Successfully trimmed RAM allocations across $SuccessCount processes." -ForegroundColor Green

---

# 3. Apply Persistent SvcHost Process Consolidation
Write-Host "[+] Adjusting Service Host Split Threshold to group services..." -ForegroundColor Yellow

$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control"
# Setting the threshold value to 38000000 KB (~36 GB). 
# This tricks Windows into thinking it has low RAM, forcing it to group individual services back into single svchost.exe processes.
if (Test-Path $RegistryPath) {
    New-ItemProperty -Path $RegistryPath -Name "SvcHostSplitThresholdInKB" -Value 38000000 -PropertyType DWORD -Force | Out-Null
    Write-Host "[✓] Service Host Split Threshold updated. Services will group on next reboot." -ForegroundColor Green
}

---

# 4. Pure Cache & Telemetry Service Annihilation
Write-Host "[+] Halting and disabling RAM-heavy caching and tracking services..." -ForegroundColor Yellow

$BloatServices = @(
    "SysMain",          # Formerly Superfetch. Caches apps into RAM aggressively.
    "WSearch",          # Windows Search Indexer. Creates large background memory caches.
    "DiagTrack",        # Connected User Experiences and Telemetry.
    "dmwappushservice", # WAP Push Message Routing Service (More telemetry bloat).
    "MapsBroker"        # Downloaded Maps Manager.
)

foreach ($Service in $BloatServices) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        try {
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   -> Disabled: $Service" -ForegroundColor Gray
        }
        catch {
            Write-Host "   -> Failed to modify service: $Service (Likely stripped or locked)" -ForegroundColor DarkYellow
        }
    }
}

---

# 5. Core Kernel Memory Structure Adjustments
Write-Host "[+] Fine-tuning Windows Kernel Memory Management Registry keys..." -ForegroundColor Yellow

$MemoryMgmtPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

# DisablePagingExecutive = 0 forces the kernel and drivers to page to disk when idle, freeing physical RAM.
New-ItemProperty -Path $MemoryMgmtPath -Name "DisablePagingExecutive" -Value 0 -PropertyType DWORD -Force | Out-Null

# LargeSystemCache = 0 prevents the system from giving large allocations to file system caching over application RAM.
New-ItemProperty -Path $MemoryMgmtPath -Name "LargeSystemCache" -Value 0 -PropertyType DWORD -Force | Out-Null

# Kill unresponding tasks quickly to avoid memory leaks hanging in the background
$DesktopPath = "HKCU:\Control Panel\Desktop"
New-ItemProperty -Path $DesktopPath -Name "AutoEndTasks" -Value "1" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $DesktopPath -Name "HungAppTimeout" -Value "1000" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $DesktopPath -Name "WaitToKillAppTimeout" -Value "2000" -PropertyType String -Force | Out-Null

Write-Host "[✓] Memory Management configurations optimized successfully." -ForegroundColor Green

---

# 6. PowerShell Environment Garbage Collection
Write-Host "[+] Purging the active PowerShell execution workspace..." -ForegroundColor Yellow
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host "=============================================" -ForegroundColor Green
Write-Host "  RAM OPTIMIZATION COMPLETE! REBOOT DEVICE.  " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
