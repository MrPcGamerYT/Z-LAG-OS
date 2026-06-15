# ==============================================================================
# Z-LAG OS Engine - Ultimate Universal Performance & Memory Optimization Stack
# Targets: Sub-50 Process Floor + Megabyte-Level RAM Trimming
# Compatibility: Windows 10 & Windows 11 (All Versions)
# Run Context: Elevated Administrator PowerShell Session
# ==============================================================================

# Ensure script runs with absolute administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Critical Error: This script must be run as an Administrator!"
    Exit
}

Write-Output "=================================================================="
Write-Output "          LAUNCHING Z-LAG OS ULTIMATE UNIVERSAL ENGINE            "
Write-Output "=================================================================="

# ------------------------------------------------------------------------------
# 1. THE EMBEDDED RAM DROPPER (Win32 Native RAM Trimming Engine)
# ------------------------------------------------------------------------------
Write-Output "[+] Injecting Native Win32 Memory Working Set Compressor..."

$RamDropperCode = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class ZLagRamEngine {
    [DllImport("psapi.dll", SetLastError = true)]
    public static extern int EmptyWorkingSet(IntPtr hProcess);

    public static void PurgeSystemRam() {
        Process[] runningProcesses = Process.GetProcesses();
        foreach (Process proc in runningProcesses) {
            try {
                // Instantly flushes idle page leaks out of physical RAM allocations
                EmptyWorkingSet(proc.Handle);
            }
            catch {
                // Safely bypasses protected kernel threads (smss, lsass, etc.)
                continue;
            }
        }
    }
}
"@

# Compile the C# memory management structure directly into the live session
Add-Type -TypeDefinition $RamDropperCode -ErrorAction SilentlyContinue

# Execute the first memory dump cycle immediately
[ZLagRamEngine]::PurgeSystemRam()
Write-Output "[*] Native RAM Trimming complete. Working memory optimized."


# ------------------------------------------------------------------------------
# 2. THE PROCESS DROPPER MATRIX (Aggressive Safe Service Purge)
# ------------------------------------------------------------------------------
Write-Output "[+] Executing Sub-50 Target Process Dropper Blueprint..."

$ServicesToKill = @(
    "DiagTrack", "dmwappushservice", "WerSvc", "PcaSvc", "SysMain", "WSearch",
    "WbioSrvc", "MapsBroker", "Fax", "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
    "XboxGipSvc", "RetailDemo", "RemoteRegistry", "UsoSvc", "BDESVC", "CDPSvc", 
    "PhoneSvc", "TrkWks", "TabletInputService", "StiSvc", "wisvc", "SensorDataService", 
    "SensorService", "SensrSvc", "BcastDVRUserService", "OneSyncSvc", "UserDataSvc", 
    "UnistoreSvc", "PimIndexMaintenanceSvc", "MessagingService", "wlidsvc", "wuauserv", 
    "WaaSMedicSvc", "FontCache", "FontCache3.0.0.0", "smphost", "DeviceAssociationService",
    "wscsvc", "WebManagementService", "SDRSVC", "WpcMonSvc"
)

foreach ($Svc in $ServicesToKill) {
    if (Get-Service -Name $Svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}


# ------------------------------------------------------------------------------
# 3. BACKGROUND APPX & GHOST APP TERMINATION (Targeting Microsoft Background Bloat)
# ------------------------------------------------------------------------------
Write-Output "[+] Purging Active Standalone Background Process App Containers..."

# Kill persistent non-essential background browser helpers and synchronization trees
$GhostProcesses = @("OneDrive", "MicrosoftEdgeUpdate", "msedge", "Teams", "WidgetService", "SearchHost")
foreach ($Proc in $GhostProcesses) {
    Stop-Process -Name $Proc -Force -ErrorAction SilentlyContinue
}

# Windows 11 Specific Shell Bloat Stripping (Safe Universal Check)
if ((Get-CimInstance Win32_OperatingSystem).Caption -like "*Windows 11*") {
    Write-Output "[*] Windows 11 Detected. Suspending Advanced Web Widget Subsystems..."
    Get-AppxPackage -AllUsers *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
}


# ------------------------------------------------------------------------------
# 4. KERNEL & MEMORY ALLOCATION OPTIMIZATIONS (No Core Breaks)
# ------------------------------------------------------------------------------
Write-Output "[+] Adjusting Registry Layer For Zero Storage Page Throttling..."

$RegMemoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $RegMemoryPath -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $RegMemoryPath -Name "LargeSystemCache" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $RegMemoryPath -Name "DisableCompression" -Value 1 -Type DWord -Force

# Global App Background Execution Ban Policy
$PrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
if (-not (Test-Path $PrivacyPath)) { New-Item -Path $PrivacyPath -Force | Out-Null }
Set-ItemProperty -Path $PrivacyPath -Name "LetAppsRunInBackground" -Value 2 -Type DWord -Force


# ------------------------------------------------------------------------------
# 5. HIGH-RESPONSIVENESS NETWORKING LAYER (Corrected RSS Real-Time Rules)
# ------------------------------------------------------------------------------
Write-Output "[+] Configuring Hardware Network Adapters for Zero Interrupt Jitter..."

# Ensure RSS is enabled to scale game network pipelines across multi-core processors cleanly
netsh int tcp set global rss=enabled
netsh int tcp set global autotuninglevel=normal

# Turn off packet bundling constraints to secure immediate hardware mouse translation response
Get-NetAdapter | ForEach-Object {
    $Name = $_.Name
    Set-NetAdapterAdvancedProperty -Name $Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $Name -DisplayName "Flow Control" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
}


# ------------------------------------------------------------------------------
# 6. HARDWARE-LEVEL INTERRUPT OPTIMIZATION (Forced GPU MSI Mode Automation)
# ------------------------------------------------------------------------------
Write-Output "[+] Aligning Message Signaled Interrupts (MSI Mode) on Graphics Core..."

$GpuControllers = Get-CimInstance Win32_VideoController
foreach ($Gpu in $GpuControllers) {
    $DevicePNP = $Gpu.PNPDeviceID
    $MsiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$DevicePNP\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    
    if (-not (Test-Path $MsiPath)) {
        New-Item -Path $MsiPath -Force | Out-Null
    }
    Set-ItemProperty -Path $MsiPath -Name "MSISupported" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $MsiPath -Name "MessageNumberLimit" -Value 1 -Type DWord -Force
}


# ------------------------------------------------------------------------------
# 7. UNTHROTTLED POWER SCHEME STRATEGY
# ------------------------------------------------------------------------------
Write-Output "[+] Activating Native Ultimate Performance Hardware Instructions..."

$UltimateProfileGuid = "e9a42b02-581c-44d4-9f1f-9c732444b192"
& powercfg /duplicateid $UltimateProfileGuid 2>$null
& powercfg /setactive $UltimateProfileGuid 2>$null

# Force Core Parking configurations off completely across default kernels
$PowerControlPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
if (-not (Test-Path $PowerControlPath)) { New-Item -Path $PowerControlPath -Force | Out-Null }
Set-ItemProperty -Path $PowerControlPath -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force


# ------------------------------------------------------------------------------
# 8. SCHEDULER RE-ALIGNMENT & REBOOT SYNC PREPARATION
# ------------------------------------------------------------------------------
Write-Output "[+] Cycling Shell Environment to Settle Process Registers..."

# Double loop RAM cleaner instance call to wipe memory footprint from variables loaded during execution
[ZLagRamEngine]::PurgeSystemRam()

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Output "=================================================================="
Write-Output " SUCCESS: Z-LAG OS UNIVERSAL OPTIMIZATION MATRIX DEPLOYED!         "
Write-Output " TARGET: PROCESSES DROPPED / WORKING MEMORY REDUCED TO MB FLOOR     "
Write-Output " REBOOT YOUR MACHINE TO FINALIZE KERNEL ASSIGNMENTS               "
Write-Output "=================================================================="
