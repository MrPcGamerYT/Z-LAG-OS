# ==============================================================================
# Z-LAG OS - Windows 11 EXTRA Process Floor  (brings Win11 idle count down to
#                                           near Windows 10 levels)
# Runs ONLY on Windows 11 (build >= 22000). Targets Win11-only services, AI
# components (Copilot/Recall), per-user bloat services, and Win11-only apps.
#
# SAFETY: same hard keep-list as process_floor.ps1 - networking (Wi-Fi /
# Bluetooth / Ethernet), the AppX shell + app-launch stack and WebView2 are
# NEVER touched.
# ==============================================================================

$ErrorActionPreference = "Continue"
function Log([string]$m) { Write-Output "[Z-LAG-W11] $m" }

# --- 0. Build guard (defense-in-depth; the playbook also gates this task) ---
$build = [int](Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "CurrentBuildNumber" -ErrorAction SilentlyContinue)
if (-not $build) { $build = 0 }
if ($build -lt 22000) {
    Log ("Skipping - not Windows 11 (build " + $build + ").")
    exit 0
}
Log ("Windows 11 detected (build " + $build + ") - applying extra process floor.")

# --- 1. HARD KEEP LIST (never stopped/disabled) ---
$KeepServices = @(
    # Networking - Wi-Fi / Bluetooth / Ethernet / VPN / firewall (untouchable)
    "Dhcp","Dnscache","NlaSvc","nsi","Tcpip","NetBT","LanmanWorkstation","netprofm",
    "WcmSvc","WlanSvc","vwififlt","vwifibus","vwifimp","bthserv","BTAGService",
    "bthpriv","BluetoothUserService","RasMan","RasAuto","RemoteAccess","SstpSvc",
    "IKEEXT","BFE","MpsSvc","EapHost","dot3svc","WwanSvc","RmSvc","PolicyAgent",
    "NcdAutoSetup","DusmSvc","NPSMSvc","wcncsvc",
    # Security / logon / user
    "WinDefend","WdNisSvc","SecurityHealthService","SamSs","ProfSvc","UserManager",
    "seclogon","KeyIso","VaultSvc","gpsvc","SENS","Winmgmt","msiserver",
    "TrustedInstaller",
    # Core OS / RPC / power / plug&play
    "RpcSs","RpcEptMapper","DcomLaunch","Power","PlugPlay","Schedule","EventLog",
    "EventSystem","BrokerInfrastructure","CoreMessagingRegistrar",
    "SystemEventsBroker","Themes","StorSvc","W32Time","CryptSvc",
    # Shell / AppX / WebView2 host (untouchable -> no silent app crashes)
    "AppXSvc","AppReadiness","ClipSVC","LicenseManager","StateRepository",
    "camsvc","wlidsvc","TokenBroker",
    # Audio
    "Audiosrv","AudioEndpointBuilder"
)

function Test-KeepService {
    param([string]$Name, [object]$Svc)
    if ($KeepServices -contains $Name) { return $true }
    if ($Svc -and $Svc.DisplayName -match 'NVIDIA|AMD|Intel|Audio|Sound|Display|GPU') { return $true }
    return $false
}

# Boot/System-start services (Start 0 or 1) are kernel-critical and must never be
# touched - final safety net on top of the keep-list.
function Test-CriticalStart {
    param([string]$Name)
    $start = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" -Name "Start" -ErrorAction SilentlyContinue).Start
    if ($null -ne $start -and [int]$start -le 1) { return $true }
    return $false
}

# --- 2. Disable Win11-only background services (only truly safe-to-disable) ---
$Win11Disable = @(
    # Shared PC account manager + UWP disk/storage telemetry (safe to disable)
    "shpamsvc","UdkUserSvc"
)

# Win11-only services set to demand-only instead of disabled, so Store-keep users
# and clipboard history keep working while contributing 0 idle processes.
$Win11Manual = @(
    "AarSvc","Ndu","WpnService","cbdhsvc"
)

# Per-user instances of services already disabled at base level (Win11 spawns
# one per logged-in user -> extra svchost processes).
$Win11PerUser = @(
    "OneSyncSvc_","UnistoreSvc_","PimIndexMaintenanceSvc_","UserDataSvc_",
    "BcastDVRUserService_","MessagingService_","CaptureService_",
    "CDPUserSvc_"
)

$disabledCount = 0
foreach ($name in $Win11Disable) {
    Get-Service -Name "$name*" -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-KeepService -Name $_.Name -Svc $_) {
            Log ("  keep (protected): " + $_.Name)
        } elseif (Test-CriticalStart -Name $_.Name) {
            Log ("  skip (boot/system service): " + $_.Name)
        } else {
            Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
            $script:disabledCount++
        }
    }
}
foreach ($prefix in $Win11PerUser) {
    Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$prefix*" } | ForEach-Object {
        if (Test-KeepService -Name $_.Name -Svc $_) {
            Log ("  keep (protected): " + $_.Name)
        } elseif (Test-CriticalStart -Name $_.Name) {
            Log ("  skip (boot/system service): " + $_.Name)
        } else {
            Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
            $script:disabledCount++
        }
    }
}
foreach ($name in $Win11Manual) {
    Get-Service -Name "$name*" -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not (Test-CriticalStart -Name $_.Name)) {
            Set-Service -Name $_.Name -StartupType Manual -ErrorAction SilentlyContinue
        }
    }
}
Log ("Disabled " + $script:disabledCount + " Windows 11 services (AarSvc/Ndu/WpnService/cbdhsvc kept demand-only).")

# --- 3. Remove Win11-only bloat apps (WebView2 kept) ---
Log "Removing Windows 11-only bloat apps (WebView2 kept)..."
$Win11Packages = @(
    "Microsoft.Windows.Ai","Microsoft.Copilot","Clipchamp.Clipchamp",
    "Microsoft.PowerAutomateDesktop","Microsoft.Windows.DevHome",
    "MicrosoftCorporationII.QuickAssist","MicrosoftCorporationII.MicrosoftFamily",
    "MicrosoftTeams","MSTeams","Microsoft.OutlookForWindows",
    "MicrosoftWindows.Client.WebExperience","Microsoft.WindowsFeedbackHub",
    "Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.Todos",
    "Microsoft.WindowsCamera","Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder"
)
foreach ($Pkg in $Win11Packages) {
    Get-AppxPackage -AllUsers -Name "*$Pkg*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "*WebView*" } |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -like "*$Pkg*" -and $_.DisplayName -notlike "*WebView*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# --- 4. Kill Win11-only resident processes ---
$Win11Processes = @("Copilot","Recall","Widgets","ms-teams","Clipchamp","PhoneExperienceHost","PowerAutomate","DevHome")
foreach ($p in $Win11Processes) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
Log "Windows 11 resident bloat processes terminated."

# --- 5. Registry: disable Win11 AI / Copilot / Recall / Chat / suggestions ---
$ai = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
if (-not (Test-Path $ai)) { New-Item -Path $ai -Force | Out-Null }
Set-ItemProperty -Path $ai -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $ai -Name "AllowRecallEnablement" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AI" -Name "RecallEnabled" -Value 0 -Type DWord -Force

$copilot = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
if (-not (Test-Path $copilot)) { New-Item -Path $copilot -Force | Out-Null }
Set-ItemProperty -Path $copilot -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force

$chat = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
if (-not (Test-Path $chat)) { New-Item -Path $chat -Force | Out-Null }
Set-ItemProperty -Path $chat -Name "ChatIcon" -Value 3 -Type DWord -Force

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $adv -Name "ShowCopilotButton" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $adv -Name "TaskbarMn" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $adv -Name "TaskbarDa" -Value 0 -Type DWord -Force

$expl = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $expl)) { New-Item -Path $expl -Force | Out-Null }
Set-ItemProperty -Path $expl -Name "HideRecommendedSection" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $adv -Name "Start_IrisRecommendations" -Value 0 -Type DWord -Force

$cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $cdm -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CloudSearchEnabled" -Value 0 -Type DWord -Force

# --- 6. Restart the shell cleanly ---
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Log "Windows 11 extra process floor applied. Reboot for full effect."
Log "Protected: Wi-Fi / Bluetooth / Ethernet, AppX shell + app launching, WebView2."
