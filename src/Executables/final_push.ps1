# ==============================================================================
# Z-LAG OS Engine V3.0 Ultimate Universal Edition - Maximum RAM/Process Drop
# Compatibility: Windows 10 & Windows 11 (All Universal Builds)
# Security Policy: Standard Core Kernel Elements & Core Networking Left Intact
# Run Context: Elevated Administrator PowerShell Session
# ==============================================================================

$ErrorActionPreference = 'Continue'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Critical Error: Script requires elevated Administrative privileges!"
    Exit
}

# ------------------------------------------------------------------------------
# DEFENDER OPTION GATE (fixes: "I kept Defender but it is still broken")
# Every Defender-specific action in this script only runs when the user
# SELECTED the defender-disable option (07_defenderAggressive.yml wrote the
# DefenderRemoved marker). When Defender is kept, none of it may touch
# Defender / Windows Security.
# ------------------------------------------------------------------------------
$defenderRemoved = $false
$zlagMarker = Get-ItemProperty -Path "HKLM:\SOFTWARE\Z-LAG-OS" -Name "DefenderRemoved" -ErrorAction SilentlyContinue
if ($zlagMarker -and $zlagMarker.DefenderRemoved -eq 1) { $defenderRemoved = $true }

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

# Global Background Application Execution Ban: REMOVED ON PURPOSE.
# The machine-wide LetAppsRunInBackground=2 policy killed the NVIDIA App's
# background container (in-game overlay broke) and starved the Windows
# Security (SecHealthUI) app of its background pre-load (kept Defender felt
# broken). protect_gpu_apps.ps1 (task 04) now bans background access
# PER-APP: every non-GPU package stays banned, GPU vendor + Windows Security
# packages keep access. Same footprint, zero collateral damage.


# ------------------------------------------------------------------------------
# 3.5. 1000% TOTAL NOTIFICATION LOCKDOWN & EXECUTABLE BLOCK 
# ------------------------------------------------------------------------------
Write-Output "[+] Executing aggressive 1000% notification engine lockdown..."

# ---- DEFENDER-SPECIFIC SUPPRESSION (only when the user chose defender-disable)
# On a "keep Defender" machine these would silence security alerts and kill
# the Windows Security systray - exactly the "kept Defender feels broken" bug.
if ($defenderRemoved) {
    # Never deny execution on a protected Windows binary. Alert suppression is
    # handled by policy; restore inheritance/remove a deny ACE left by older builds.
    $Sys32Path = "$env:SystemRoot\System32"
    $SystrayFile = "$Sys32Path\SecurityHealthSystray.exe"
    if (Test-Path $SystrayFile) {
        & icacls.exe $SystrayFile /remove:d '*S-1-1-0' /inheritance:e /c /q *>$null
    }

    # Policy-Level Defenses (Block Windows Security Center Alerts)
    $WscNotifPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection"
    if (-not (Test-Path $WscNotifPath)) { New-Item -Path $WscNotifPath -Force | Out-Null }
    Set-ItemProperty -Path $WscNotifPath -Name "ShowAlertWindow" -Value 0 -Type DWord -Force

    $BenignNotifPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications"
    if (-not (Test-Path $BenignNotifPath)) { New-Item -Path $BenignNotifPath -Force | Out-Null }
    Set-ItemProperty -Path $BenignNotifPath -Name "DisableNotifications" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $BenignNotifPath -Name "DisableEnhancedNotifications" -Value 1 -Type DWord -Force

    # Remove the Windows Security systray startup entry (no AV left to surface).
    $SysTrayIconPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty -Path $SysTrayIconPath -Name "SecurityHealth" -ErrorAction SilentlyContinue
    Write-Output "[+] Defender removal selected: security-center alert suppression applied."
} else {
    Write-Output "[+] Defender kept: security-center alerts and systray left intact."
}

# ---- GENERIC SHELL NOTIFICATION LOCKDOWN (never Defender-specific) ----
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


# ------------------------------------------------------------------------------
# 4. MAXIMUM DEEP PROCESS PURGE (Safely Clears Non-Core Service Footprint)
# ------------------------------------------------------------------------------
Write-Output "[+] Halting non-essential services to drop background active handles..."

$ServicesToKill = @(
    "DiagTrack", "dmwappushservice", "WerSvc", "PcaSvc", "SysMain", "WSearch",
    "WbioSrvc", "MapsBroker", "Fax", "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
    "XboxGipSvc", "RetailDemo", "RemoteRegistry", "UsoSvc", "BDESVC",
    # NOTE: TabletInputService stays demand-start (handled by the services
    # task) - hard-disabling it broke keyboard input in UWP/search surfaces.
    "TrkWks", "StiSvc", "wisvc", "SensorDataService", 
    "SensorService", "SensrSvc", "BcastDVRUserService", "OneSyncSvc", "UserDataSvc", 
    "UnistoreSvc", "PimIndexMaintenanceSvc", "MessagingService", "wuauserv", 
    # NOTE: FontCache / FontCache3.0.0.0 are NOT killed - without the font
    # cache, every UI text draw re-renders glyphs and the whole shell stutters.
    "WaaSMedicSvc", "smphost",
    "WebManagementService", "SDRSVC", "WpcMonSvc", "Spooler", "PrintNotify",
    "DPS", "WdiServiceHost", "WdiSystemHost",
    # Extra bloated telemetry/logging modules safely cut down here.
    # NOTE: PushToInstall is NOT touched here - it is handled only by the
    # Store-removal path so users who kept the Store can still install apps.
    "TroubleshootingSvc", "TrainedDeployments"
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
    "SearchHost", "YourPhone", "SkypeBackgroundHost",
    "GameBarPresenceWriter", "Cortana", "mobsync"
    # NOTE: ctfmon (keyboard/IME loader) is intentionally NOT killed - killing it
    # can break text input for the current session.
    # NOTE: SecurityHealthSystray (Windows Security systray) is only killed when
    # the user chose defender-disable - on a kept-Defender machine it is the
    # visible Windows Security icon and must stay.
)
if ($defenderRemoved) { $GhostProcesses += "SecurityHealthSystray" }
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
    # DO NOT force MessageNumberLimit=1: starving a modern GPU down to a single
    # interrupt message serializes interrupt handling and causes frame-time
    # spikes/stutter under load. Let the GPU driver pick its own message count.
    Remove-ItemProperty -Path $MsiPath -Name "MessageNumberLimit" -ErrorAction SilentlyContinue
}


# ------------------------------------------------------------------------------
# 7. UNTHROTTLED POWER SCHEME STRATEGY (universal Win10 + Win11)
# ------------------------------------------------------------------------------
# set_power_plan.ps1 already created, tuned and ACTIVATED the "Maximum FPS"
# plan and recorded its GUID. Re-activate that exact plan here (in case an
# installer switched plans mid-playbook) instead of duplicating a new copy
# on every run - the old duplicate-and-activate-template logic created
# duplicate plans and could activate the WRONG (untuned) scheme.
$MaxFpsGuid = $null
try {
    $MaxFpsGuid = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Z-LAG-OS" -Name "MaxFpsPlanGuid" -ErrorAction SilentlyContinue).MaxFpsPlanGuid
} catch { }
$GuidRegex = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
$SchemeList = (& powercfg /list 2>$null | Out-String)
if (-not ($MaxFpsGuid -and $SchemeList -match [regex]::Escape($MaxFpsGuid))) {
    # Marker missing/stale: find any plan literally named "Maximum FPS".
    $MaxFpsGuid = $null
    foreach ($line in ($SchemeList -split "`r?`n")) {
        if ($line -match ('(' + $GuidRegex + ')\s+\(Maximum FPS\)')) { $MaxFpsGuid = $Matches[1]; break }
    }
}
if ($MaxFpsGuid) {
    & powercfg -setactive $MaxFpsGuid 2>$null
} else {
    # Fallback for standalone runs: High Performance (never duplicate here).
    $HighPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    if ($SchemeList -match $HighPerfGuid) { & powercfg -setactive $HighPerfGuid 2>$null }
}


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

# Shell restart is handled by the playbook as the ACTIVE USER - do not restart
# explorer here under TrustedInstaller (it would leave the user without a desktop).
# Run final hard trim script-side
[ZLagTrueEngine]::GlobalPurge()

Write-Output "=================================================================="
Write-Output " GLOBAL ENGINE OPTIMIZED! REBOOT COMPUTER TO LOCK PARAMETERS.    "
Write-Output "=================================================================="
