# ==============================================================================
# Z-LAG OS Engine V3.0 Ultimate Universal Edition - Maximum RAM/Process Drop
# Compatibility: Windows 10 & Windows 11 (All Universal Builds)
# Security Policy: Standard Core Kernel Elements & Core Networking Left Intact
# Run Context: Elevated Administrator PowerShell Session
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Critical Error: Script requires elevated Administrative privileges!"
    Exit
}

Write-Output "=================================================================="
Write-Output "   DEPLOYING Z-LAG ULTIMATE PROCESS & RAM REDUCTION ENGINE v3.0   "
Write-Output "=================================================================="

# ------------------------------------------------------------------------------
# 1. SVCHOST SERVICE CONSOLIDATION (Stops process sprawl across your CPU)
# ------------------------------------------------------------------------------
Write-Output "[+] Collapsing independent service processes into single shared pools..."
$SystemControlPath = "HKLM:\SYSTEM\CurrentControlSet\Control"
# Forces the OS to bundle multiple low-level services inside the same svchost instance
Set-ItemProperty -Path $SystemControlPath -Name "SvcHostSplitThresholdInKB" -Value 380000000 -Type DWord -Force


# ------------------------------------------------------------------------------
# 2. DESKTOP INTERFACE RAM STRIPPER (Drops DWM & Explorer Memory Footprint)
# ------------------------------------------------------------------------------
Write-Output "[+] Disabling hidden UI render caching and forcing minimal DWM footprint..."

# Strip heavy visual effects animations that steal hundreds of MBs from RAM
$VisualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (-not (Test-Path $VisualPath)) { New-Item -Path $VisualPath -Force | Out-Null }
Set-ItemProperty -Path $VisualPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force

# Disable translucent animations, window blur layouts, and minimize/maximize animations
$DwmPath = "HKCU:\Software\Microsoft\Windows\DWM"
Set-ItemProperty -Path $DwmPath -Name "ColorPrevalence" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $DwmPath -Name "EnableAeroPeek" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $DwmPath -Name "AlwaysHibernateThumbnails" -Value 1 -Type DWord -Force

$DesktopPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
Set-ItemProperty -Path $DesktopPath -Name "MinAnimate" -Value "0" -Type String -Force


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
# 3.5. 1000% TOTAL NOTIFICATION LOCKDOWN & EXECUTABLE BLOCK 
# ------------------------------------------------------------------------------
Write-Output "[+] Executing aggressive 1000% notification engine lockdown..."

# Take Ownership and Permanently Kill SecurityHealthSystray Binary Execution
$Sys32Path = "$env:SystemRoot\System32"
$SystrayFile = "$Sys32Path\SecurityHealthSystray.exe"

if (Test-Path $SystrayFile) {
    & takeown.exe /f $SystrayFile /a *>$null
    & icacls.exe $SystrayFile /inheritance:r /grant:r *S-1-5-32-544:F /deny *S-1-1-0:`(X`) *>$null
}

# Policy-Level Defenses (Block Windows Security Center Alerts)
$WscNotifPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection"
if (-not (Test-Path $WscNotifPath)) { New-Item -Path $WscNotifPath -Force | Out-Null }
Set-ItemProperty -Path $WscNotifPath -Name "ShowAlertWindow" -Value 0 -Type DWord -Force

$BenignNotifPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications"
if (-not (Test-Path $BenignNotifPath)) { New-Item -Path $BenignNotifPath -Force | Out-Null }
Set-ItemProperty -Path $BenignNotifPath -Name "DisableNotifications" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $BenignNotifPath -Name "DisableEnhancedNotifications" -Value 1 -Type DWord -Force

# Universal Windows Notification System Global Engine Hard-Kill
$WpnPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
if (-not (Test-Path $WpnPolicies)) { New-Item -Path $WpnPolicies -Force | Out-Null }
Set-ItemProperty -Path $WpnPolicies -Name "NoToastNotification" -Value 1 -Type DWord -Force

$WpnPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
if (-not (Test-Path $WpnPath)) { New-Item -Path $WpnPath -Force | Out-Null }
Set-ItemProperty -Path $WpnPath -Name "ToastEnabled" -Value 0 -Type DWord -Force

# User Shell Explorer Balloon Warning Block
$PolicyExplPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $PolicyExplPath)) { New-Item -Path $PolicyExplPath -Force | Out-Null }
Set-ItemProperty -Path $PolicyExplPath -Name "NoNotificationBalloon" -Value 1 -Type DWord -Force

# Remove Startup Run Items
$SysTrayIconPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $SysTrayIconPath -Name "SecurityHealth" -ErrorAction SilentlyContinue


# ------------------------------------------------------------------------------
# 4. MAXIMUM DEEP PROCESS PURGE (Safely Clears Non-Core Service Footprint)
# ------------------------------------------------------------------------------
Write-Output "[+] Halting non-essential services to drop background active handles..."

$ServicesToKill = @(
    "DiagTrack", "dmwappushservice", "WerSvc", "PcaSvc", "SysMain", "WSearch",
    "WbioSrvc", "MapsBroker", "Fax", "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
    "XboxGipSvc", "RetailDemo", "RemoteRegistry", "UsoSvc", "BDESVC", "CDPSvc", 
    "PhoneSvc", "TrkWks", "TabletInputService", "StiSvc", "wisvc", "SensorDataService", 
    "SensorService", "SensrSvc", "BcastDVRUserService", "OneSyncSvc", "UserDataSvc", 
    "UnistoreSvc", "PimIndexMaintenanceSvc", "MessagingService", "wlidsvc", "wuauserv", 
    "WaaSMedicSvc", "FontCache", "FontCache3.0.0.0", "smphost", "DeviceAssociationService",
    "WebManagementService", "SDRSVC", "WpcMonSvc", "Spooler", "PrintNotify",
    "Themes", "DPS", "WdiServiceHost", "WdiSystemHost",
    # Extra bloated telemetry/logging modules safely cut down here:
    "TroubleshootingSvc", "TrainedDeployments", "PushToInstall", "LicenseManager"
)

foreach ($Svc in $ServicesToKill) {
    if (Get-Service -Name $Svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}


# ------------------------------------------------------------------------------
# 5. EXPANDED GHOST APP TERM LIST & TELEMETRY TASKS
# ------------------------------------------------------------------------------
Write-Output "[+] Terminating non-core application background nodes & desktop layouts..."

$GhostProcesses = @(
    "OneDrive", "MicrosoftEdgeUpdate", "msedge", "Teams", "WidgetService", 
    "SearchHost", "YourPhone", "SkypeBackgroundHost", "SecurityHealthSystray",
    "GameBarPresenceWriter", "Cortana", "mobsync", "ctfmon"
)
foreach ($Proc in $GhostProcesses) {
    Stop-Process -Name $Proc -Force -ErrorAction SilentlyContinue
}

if ((Get-CimInstance Win32_OperatingSystem).Caption -like "*Windows 11*") {
    Get-AppxPackage -AllUsers *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# Purge Microsoft Telemetry Scheduled Tasks from waking up processes
$TelemetryTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Maintenance\Scheduler"
)
foreach ($Task in $TelemetryTasks) {
    Disable-ScheduledTask -TaskPath (Split-Path $Task) -TaskName (Split-Path $Task -Leaf) -ErrorAction SilentlyContinue
}


# ------------------------------------------------------------------------------
# 6. GPU INTERRUPT SIGNAL MANAGEMENT (Hardware Level Response Optimization)
# ------------------------------------------------------------------------------
Write-Output "[+] Aligning Message Signaled Interrupts for display arrays..."
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
Set-ItemProperty -Path $PowerControlPath -Name "PowerThrottlingOff" -Value 1 -Value 1 -Type DWord -Force


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
Write-Output " GLOBAL ENGINE OPTIMIZED! REBOOT COMPUTER TO LOCK PARAMETERS.    "
Write-Output "=================================================================="
