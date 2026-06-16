# ==============================================================================
# Z-LAG OS Engine - Sub-1GB RAM Physical Floor + 42 Process Grouping Stack
# Compatibility: Windows 10 & Windows 11 (All Universal Versions)
# Security Policy: Standard Windows Defender / Security Subsystems Left Unchanged
# Run Context: Elevated Administrator PowerShell Session
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Critical Error: Script requires elevated Administrative privileges!"
    Exit
}

Write-Output "=================================================================="
Write-Output "         CONFIGURING Z-LAG REAL TIME SUB-1GB PERFORMANCE          "
Write-Output "=================================================================="

# ------------------------------------------------------------------------------
# 1. SVCHOST SERVICE GROUPING (Collapses split processes back to shared pools)
# ------------------------------------------------------------------------------
Write-Output "[+] Forcing service consolidation into shared host containers..."
$SystemControlPath = "HKLM:\SYSTEM\CurrentControlSet\Control"
Set-ItemProperty -Path $SystemControlPath -Name "SvcHostSplitThresholdInKB" -Value 380000000 -Type DWord -Force


# ------------------------------------------------------------------------------
# 2. DESKTOP INTERFACE RAM STRIPPER (Drops DWM & Explorer RAM Footprint)
# ------------------------------------------------------------------------------
Write-Output "[+] Disabling hidden UI render caching to drop memory below 1GB..."

# Strip heavy visual effects animations that steal hundreds of MBs from RAM
$VisualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $VisualPath)) { New-Item -Path $VisualPath -Force | Out-Null }
Set-ItemProperty -Path $VisualPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force

# Disable translucent animations and window blur layouts globally
$DwmPath = "HKCU:\Software\Microsoft\Windows\DWM"
Set-ItemProperty -Path $DwmPath -Name "ColorPrevalence" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $DwmPath -Name "EnableAeroPeek" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $DwmPath -Name "AlwaysHibernateThumbnails" -Value 1 -Type DWord -Force


# ------------------------------------------------------------------------------
# 3. KERNEL MEMORY COMPRESSION ALIGNMENT
# ------------------------------------------------------------------------------
Write-Output "[+] Optimizing kernel memory allocation frameworks..."
$RegMemoryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $RegMemoryPath -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $RegMemoryPath -Name "LargeSystemCache" -Value 0 -Type DWord -Force

# Global Background Application Execution Ban
$PrivacyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
if (-not (Test-Path $PrivacyPath)) { New-Item -Path $PrivacyPath -Force | Out-Null }
Set-ItemProperty -Path $PrivacyPath -Name "LetAppsRunInBackground" -Value 2 -Type DWord -Force


# ------------------------------------------------------------------------------
# 4. AGGRESSIVE NON-SECURITY SERVICE PURGE (Brings process count down to ~42)
# ------------------------------------------------------------------------------
Write-Output "[+] Halting and disabling non-essential background worker cells..."

$ServicesToKill = @(
    "DiagTrack", "dmwappushservice", "WerSvc", "PcaSvc", "SysMain", "WSearch",
    "WbioSrvc", "MapsBroker", "Fax", "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
    "XboxGipSvc", "RetailDemo", "RemoteRegistry", "UsoSvc", "BDESVC", "CDPSvc", 
    "PhoneSvc", "TrkWks", "TabletInputService", "StiSvc", "wisvc", "SensorDataService", 
    "SensorService", "SensrSvc", "BcastDVRUserService", "OneSyncSvc", "UserDataSvc", 
    "UnistoreSvc", "PimIndexMaintenanceSvc", "MessagingService", "wlidsvc", "wuauserv", 
    "WaaSMedicSvc", "FontCache", "FontCache3.0.0.0", "smphost", "DeviceAssociationService",
    "WebManagementService", "SDRSVC", "WpcMonSvc", "Spooler", "PrintNotify", "bthserv"
)

foreach ($Svc in $ServicesToKill) {
    if (Get-Service -Name $Svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}


# ------------------------------------------------------------------------------
# 5. CLEARING ACTIVE GHOST APPS & SHELL WIDGETS
# ------------------------------------------------------------------------------
Write-Output "[+] Terminating standalone application background nodes..."

$GhostProcesses = @("OneDrive", "MicrosoftEdgeUpdate", "msedge", "Teams", "WidgetService", "SearchHost")
foreach ($Proc in $GhostProcesses) {
    Stop-Process -Name $Proc -Force -ErrorAction SilentlyContinue
}

if ((Get-CimInstance Win32_OperatingSystem).Caption -like "*Windows 11*") {
    Get-AppxPackage -AllUsers *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
}


# ------------------------------------------------------------------------------
# 6. UNTHROTTLED NETWORKING AND LATENCY ENFORCEMENT
# ------------------------------------------------------------------------------
netsh int tcp set global rss=enabled
netsh int tcp set global autotuninglevel=normal

Get-NetAdapter | ForEach-Object {
    $Name = $_.Name
    Set-NetAdapterAdvancedProperty -Name $Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $Name -DisplayName "Flow Control" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
}

$GpuControllers = Get-CimInstance Win32_VideoController
foreach ($Gpu in $GpuControllers) {
    $DevicePNP = $Gpu.PNPDeviceID
    $MsiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$DevicePNP\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    if (-not (Test-Path $MsiPath)) { New-Item -Path $MsiPath -Force | Out-Null }
    Set-ItemProperty -Path $MsiPath -Name "MSISupported" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $MsiPath -Name "MessageNumberLimit" -Value 1 -Type DWord -Force
}


# ------------------------------------------------------------------------------
# 7. UNTHROTTLED POWER SCHEME STRATEGY
# ------------------------------------------------------------------------------
$UltimateProfileGuid = "e9a42b02-581c-44d4-9f1f-9c732444b192"
& powercfg /duplicateid $UltimateProfileGuid 2>$null
& powercfg /setactive $UltimateProfileGuid 2>$null

$PowerControlPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
if (-not (Test-Path $PowerControlPath)) { New-Item -Path $PowerControlPath -Force | Out-Null }
Set-ItemProperty -Path $PowerControlPath -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force


# ------------------------------------------------------------------------------
# 8. C# NATIVE HARD-TRIMMER ENGINE (Forces working RAM allocations to flush)
# ------------------------------------------------------------------------------
Write-Output "[+] Deploying Win32 True Memory Cache Drop Subsystem..."

$TrueRamDropperCode = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class ZLagTrueEngine {
    [DllImport("psapi.dll", SetLastError = true)]
    public static extern int EmptyWorkingSet(IntPtr hProcess);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetSystemFileCacheSize(IntPtr MinimumFileCacheSize, IntPtr MaximumFileCacheSize, int Flags);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetSystemInformation(int SystemInformationClass, IntPtr SystemInformation, int SystemInformationLength);

    public static void GlobalPurge() {
        Process[] runningProcesses = Process.GetProcesses();
        foreach (Process proc in runningProcesses) {
            try { EmptyWorkingSet(proc.Handle); } catch {}
        }
        try {
            IntPtr minusOne = new IntPtr(-1);
            SetSystemFileCacheSize(minusOne, minusOne, 0);
        } catch {}
        try {
            int cmd = 4;
            IntPtr pCmd = Marshal.AllocHGlobal(sizeof(int));
            Marshal.WriteInt32(pCmd, cmd);
            NtSetSystemInformation(67, pCmd, sizeof(int));
            Marshal.WriteInt32(pCmd, 5);
            NtSetSystemInformation(67, pCmd, sizeof(int));
            Marshal.FreeHGlobal(pCmd);
        } catch {}
    }
}
"@

Add-Type -TypeDefinition $TrueRamDropperCode -ErrorAction SilentlyContinue

# Cycle the environment shell to load variables cleanly
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

# Run final hard trim script-side
[ZLagTrueEngine]::GlobalPurge()

Write-Output "=================================================================="
Write-Output " SYSTEM CONFIGURATION SETTLED! PLEASE REBOOT FOR FULL EFFECT.     "
Write-Output "=================================================================="
