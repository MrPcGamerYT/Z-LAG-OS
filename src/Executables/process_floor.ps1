# ==============================================================================
# Z-LAG OS - ULTRA Idle Process + RAM Floor Engine (max gaming footprint drop)
# ------------------------------------------------------------------------------
#  Goal: crush idle background processes and RAM to the absolute floor for
#  gaming. On-demand features (System Restore / VSS, notifications, network
#  discovery, file sharing, hotspot) are now DISABLED entirely, not just set
#  to demand-only, so they can never spawn processes mid-game.
#
#  STILL NEVER TOUCHED: Windows core (no crash / no boot break), Wi-Fi /
#  Bluetooth / Ethernet, the app-launch stack (so Z-LAG Toolbox apps and the
#  Start Menu never silently crash), and WebView2.
#
#  SAFETY: everything below is gated behind a hard "KEEP" list. A service that
#  matches the keep list (or a GPU/audio vendor) is NEVER stopped or disabled,
#  even if a name accidentally appears in the disable list.
#
#  KEEP (never touched):
#    * Networking core + Wi-Fi/Bluetooth/Ethernet: Dhcp, Dnscache, NlaSvc, nsi,
#      Tcpip, NetBT, LanmanWorkstation, netprofm, WcmSvc, WlanSvc, vwififlt,
#      vwifibus, vwifimp, bthserv, BTAGService, bthpriv, BluetoothUserService,
#      RasMan, RasAuto, RemoteAccess, SstpSvc, IKEEXT, BFE, MpsSvc, EapHost,
#      dot3svc, WwanSvc, RmSvc, PolicyAgent
#    * Shell / AppX / WebView2 host: AppXSvc, AppReadiness, ClipSVC,
#      LicenseManager, StateRepository, SystemEventsBroker, CoreMessagingRegistrar,
#      Themes, camsvc (+ wlidsvc/TokenBroker left to the Store option)
#    * Audio + display: Audiosrv, AudioEndpointBuilder + NVIDIA/AMD/Intel/GPU
#    * Core OS: RpcSs, RpcEptMapper, DcomLaunch, Power, PlugPlay, Schedule,
#      EventLog, EventSystem, ProfSvc, UserManager, gpsvc, Winmgmt, msiserver,
#      TrustedInstaller, SamSs, KeyIso, VaultSvc, SENS, seclogon, WinDefend...
# ==============================================================================

$ErrorActionPreference = "Continue"

# --- 0. Persistent logging (production diagnostics) + elevation guard ---
$logDir = Join-Path $env:ProgramData "Z-LAG-OS"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "process_floor.log"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output "[Z-LAG-FLOOR] ERROR: Administrator privileges required. Run from an elevated session."
    exit 1
}

function Log([string]$m) {
    $line = "[Z-LAG-FLOOR] $m"
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

# --- 1. svchost consolidation: never split service hosts (fewer processes) ---
Log "Consolidating service hosts into shared pools..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value 380000000 -Type DWord -Force

# --- 2. HARD KEEP LIST (these are never stopped/disabled) ---
$KeepServices = @(
    # Networking - Wi-Fi / Bluetooth / Ethernet / VPN / firewall (untouchable)
    "Dhcp","Dnscache","NlaSvc","nsi","Tcpip","NetBT","LanmanWorkstation","netprofm",
    "WcmSvc","WlanSvc","vwififlt","vwifibus","vwifimp","bthserv","BTAGService",
    "bthpriv","BluetoothUserService","RasMan","RasAuto","RemoteAccess","SstpSvc",
    "IKEEXT","BFE","MpsSvc","EapHost","dot3svc","WwanSvc","RmSvc","PolicyAgent",
    "NcdAutoSetup","DusmSvc","wcncsvc",
    # Security / logon / user (untouchable)
    "WinDefend","WdNisSvc","SecurityHealthService","SamSs","ProfSvc","UserManager",
    "seclogon","KeyIso","VaultSvc","gpsvc","SENS","Winmgmt","msiserver",
    "TrustedInstaller",
    # Core OS / RPC / power / plug&play (untouchable)
    "RpcSs","RpcEptMapper","DcomLaunch","Power","PlugPlay","Schedule","EventLog",
    "EventSystem","BrokerInfrastructure","CoreMessagingRegistrar",
    "SystemEventsBroker","Themes","StorSvc","W32Time","CryptSvc",
    # Shell / AppX / WebView2 host (untouchable -> no silent app crashes)
    "AppXSvc","AppReadiness","ClipSVC","LicenseManager","StateRepository",
    "camsvc","wlidsvc","TokenBroker",
    # Audio (untouchable)
    "Audiosrv","AudioEndpointBuilder"
)

function Test-KeepService {
    param([string]$Name, [object]$Svc)
    if ($KeepServices -contains $Name) { return $true }
    if ($Svc -and $Svc.DisplayName -match 'NVIDIA|AMD|Intel|Audio|Sound|Display|GPU') { return $true }
    return $false
}

# Boot/System-start services (Start 0 or 1) are kernel-critical and must never be
# touched - this is a final safety net on top of the keep-list.
function Test-CriticalStart {
    param([string]$Name)
    $start = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" -Name "Start" -ErrorAction SilentlyContinue).Start
    if ($null -ne $start -and [int]$start -le 1) { return $true }
    return $false
}

# --- 3. Disable safe-to-remove background services ---
$Disable = @(
    # Cloud / identity / content (Store install services are handled ONLY by the
    # Store-removal path so "keep the Store" users can still install apps)
    "OneSyncSvc","UserDataSvc","UnistoreSvc","PimIndexMaintenanceSvc",
    "MessagingService","BcastDVRUserService","CDPSvc","CDPUserSvc","WSearch",
    "MapsBroker","wisvc",
    # Xbox
    "XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc",
    # Telemetry / errors / diagnostics / compatibility
    "DiagTrack","dmwappushservice","WerSvc","WEPHOSTSVC","wercplsupport","PcaSvc",
    "DPS","WdiServiceHost","WdiSystemHost","TroubleshootingSvc","DcpSvc","UhsSvc",
    # Updates / delivery (Windows Update is already blocked)
    "UsoSvc","WaaSMedicSvc","wuauserv","DoSvc",
    # Edge / Office updaters
    "edgeupdate","edgeupdatem","MicrosoftEdgeElevationService","ClickToRunSvc",
    # Superfetch / RAM hogs
    "SysMain",
    # Printing / imaging / biometrics / sensors
    "Spooler","PrintNotify","StiSvc","WiaRpc","WbioSrvc","SensorService",
    "SensorDataService","SensrSvc","FrameServer","WPDBusEnum",
    # Media / misc bloat
    "WMPNetworkSvc","WalletService","NaturalAuthentication","WpcMonSvc",
    "RetailDemo","RemoteRegistry","PhoneSvc","Fax","TabletInputService",
    "GraphicsPerfSvc","MixedRealityOpenXRSvc",
    # P2P / remote management (NOT core connectivity - safe to disable)
    "p2pimsvc","p2psvc","PNRPsvc","Wecsvc","WinRM","NetTcpPortSharing","lmhosts",
    # Network extras (safe - not needed for normal Wi-Fi/Bluetooth/Ethernet)
    "IpxlatCfgSvc",
    # Smart card / NFC / embedded / Hyper-V
    "SCardSvc","ScDeviceEnum","SCPolicySvc","NfcSvc","SEMgrSvc","embeddedmode",
    "vmcompute","HvHost","vmms","hns","AJRouter",
    # Data usage / misc safe kills
    "Ndu","AarSvc","dcsvc","shpamsvc",
    "NetTcpActivator","NetPipeActivator","NetMsmqActivator",
    "ALG","AeLookupSvc","AppVClient","AssignedAccessManagerSvc","AxInstSV",
    "CaptureService","CscService","defragsvc","EntAppSvc","fhsvc",
    "lfsvc","MSDTC","NcbService","pla","QWAVE","SNMPTRAP","spectrum","svsvc",
    "TapiSrv","TieringEngineService","TrkWks","UevAgentService","vds",
    "wbengine","wmiApSrv","workfolderssvc","autotimesvc",
    # ULTRA: on-demand features that are NOT needed for gaming are disabled
    # entirely (System Restore / VSS, notifications, network discovery, file
    # sharing, hotspot/ICS, WebDAV, iSCSI, clipboard history, Security Center).
    # These can never spawn a process mid-game now. Core networking, the
    # AppX/WebView2 stack and boot/system services remain untouched.
    "VSS","SwPrv","WpnService","WpnUserService","LanmanServer","SharedAccess",
    "SSDPSRV","upnphost","fdPHost","FDResPub","lltdsvc","WebClient","MSiSCSI",
    "cbdhsvc","wscsvc","Browser","perceptionsimulation","ssh-agent","sshd",
    "wlpasvc"
)

$disabledCount = 0
foreach ($name in $Disable) {
    Get-Service -Name "$name*" -ErrorAction SilentlyContinue | ForEach-Object {
        $svc = $_
        if (Test-KeepService -Name $svc.Name -Svc $svc) {
            Log ("  keep (protected): " + $svc.Name)
        } elseif (Test-CriticalStart -Name $svc.Name) {
            Log ("  skip (boot/system service): " + $svc.Name)
        } else {
            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
            $script:disabledCount++
        }
    }
}
Log ("Disabled " + $script:disabledCount + " background services (kept all protected services).")

# --- 4. Demand-only services (available if an app needs them, 0 at idle) ---
$Manual = @(
    "StorSvc","DsmSvc","DmEnrollmentSvc","EapHost","EFS","KeyIso",
    "FontCache","FontCache3.0.0.0","BITS"
)
# NOTE: wlidsvc / TokenBroker are intentionally NOT touched here - their final
# state is decided by the Store option and locked in by repair_appx_runtime.ps1.
foreach ($name in $Manual) {
    Get-Service -Name "$name*" -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Service -Name $_.Name -StartupType Manual -ErrorAction SilentlyContinue
    }
}
Log "Demand-only (no idle footprint) set for compatibility services."

# --- 4b. ULTRA: the old "on-demand features kept functional" block was removed.
#        System Restore / VSS, notifications, discovery, file sharing and
#        hotspot are now fully DISABLED above (they add nothing to gaming and
#        can never spawn a process mid-game).

# --- 5. RAM floor: memory-management registry tuning ---
$mm = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
if (Test-Path $mm) {
    Set-ItemProperty -Path $mm -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $mm -Name "LargeSystemCache" -Value 0 -Type DWord -Force
    $prefetch = "$mm\PrefetchParameters"
    if (-not (Test-Path $prefetch)) { New-Item -Path $prefetch -Force | Out-Null }
    Set-ItemProperty -Path $prefetch -Name "EnablePrefetcher" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $prefetch -Name "EnableSuperfetch" -Value 0 -Type DWord -Force
    Log "RAM floor: prefetch/superfetch off, paging executive enabled."
}

# --- 5b. ULTRA: ban background apps + kill remaining maintenance wakeups ---
$bg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (-not (Test-Path $bg)) { New-Item -Path $bg -Force | Out-Null }
Set-ItemProperty -Path $bg -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force

$taskPaths = @(
    "\Microsoft\Windows\Application Experience\*",
    "\Microsoft\Windows\Customer Experience Improvement Program\*",
    "\Microsoft\Windows\DiskDiagnostic\*",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Location\*",
    "\Microsoft\Windows\SettingSync\*",
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask",
    "\Microsoft\Windows\Defrag\ScheduledDefrag",
    "\Microsoft\Windows\Diagnosis\*",
    "\Microsoft\Windows\Feedback\Siuf\DmClient"
)
$allTasks = Get-ScheduledTask -ErrorAction SilentlyContinue
foreach ($tp in $taskPaths) {
    $allTasks | Where-Object { $_.TaskPath -like $tp } |
        Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
}
Log "ULTRA: background apps banned + telemetry/maintenance wakeups disabled."

# --- 6. Clear startup Run entries (nothing auto-spawns at logon) ---
$runKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($key in $runKeys) {
    if (Test-Path $key) {
        Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty -ErrorAction SilentlyContinue |
            ForEach-Object { Remove-ItemProperty -Path $key -Name $_.Name -ErrorAction SilentlyContinue }
    }
}
Log "Startup Run entries cleared."

# --- 7. Kill resident bloat processes (safe - WebView2 uses msedgewebview2.exe,
#        not msedge.exe, so WebView2-based apps are untouched) ---
$Ghost = @(
    "OneDrive","Teams","msedge","MicrosoftEdgeUpdate","WidgetService","SearchHost",
    "YourPhone","SkypeBackgroundHost","GameBarPresenceWriter","GameBar","XboxApp",
    "CrossDevice","SecurityHealthSystray","PhoneExperienceHost","Widgets",
    "GameBarFTServer"
)
foreach ($p in $Ghost) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
Log "Resident bloat processes terminated."

# --- 8. Reclaim RAM: trim every process working set ---
$ramCode = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
public class ZLAGRamTrim {
    [DllImport("psapi.dll", SetLastError = true)]
    public static extern int EmptyWorkingSet(IntPtr hProcess);
    public static void Trim() {
        foreach (Process p in Process.GetProcesses()) {
            try { EmptyWorkingSet(p.Handle); } catch {}
        }
    }
}
"@
try {
    Add-Type -TypeDefinition $ramCode -ErrorAction Stop
    [ZLAGRamTrim]::Trim()
    Log "Working sets trimmed (RAM reclaimed)."
} catch {
    Log "RAM trim skipped (not fatal)."
}

# --- 9. Shell restart is handled by the playbook as the ACTIVE USER (or by the
#        final reboot). Restarting explorer here would run it in the
#        TrustedInstaller session and leave the user without a desktop.
Log "ULTRA idle process + RAM floor applied. Reboot for full effect."
Log "Disabled: VSS/System Restore, notifications, discovery, file sharing, hotspot."
Log "Protected: Windows core, Wi-Fi / Bluetooth / Ethernet, AppX shell + app launching, WebView2."
