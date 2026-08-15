# ==============================================================================
# Z-LAG OS - Microsoft Store & Microsoft Services TOTAL Removal Engine
# Runs ONLY when the user picks "Remove Microsoft Store & All MS Services".
#
#   * Uninstalls + deprovisions the Store and every Microsoft consumer/cloud app
#     so nothing comes back after reboot.
#   * Stops + disables Microsoft account / cloud / identity / telemetry services
#     so they contribute ZERO processes at idle.
#   * Sets a marker (HKLM:\SOFTWARE\Z-LAG-OS\StoreRemoved=1) so the AppX repair
#     step knows NOT to re-enable Microsoft account services afterwards.
#
# NOTE ON THE SMALL PRINT: the Windows desktop shell itself (Start Menu, Search,
# Action Center) is a packaged-app runtime. Those 4 tiny services
# (AppXSvc, StateRepository, LicenseManager, ClipSVC) are PART OF WINDOWS, not
# "Store bloat" - deleting them breaks the shell and makes apps installed by
# Z-LAG Toolbox crash with "The service has not been started". They are kept so
# everything keeps working; Microsoft account sign-in (wlidsvc) + Web Account
# Manager (TokenBroker) are dropped to demand-only so they never run at idle.
# ==============================================================================

$ErrorActionPreference = "Continue"
Write-Output "[Z-LAG] Purging Microsoft Store + Microsoft services (total removal)..."

# --- 1. AppX removal for Store & Microsoft cloud/identity packages ---
$StorePackages = @(
    'Microsoft.WindowsStore',
    'Microsoft.StorePurchaseApp',
    'Microsoft.Services.Store.Engagement',
    'Microsoft.GamingApp',
    'Microsoft.XboxApp',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxGameCallableUI',
    'Microsoft.YourPhone',
    'MicrosoftWindows.CrossDevice',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.WindowsMaps',
    'Microsoft.WindowsAlarms',
    'Microsoft.WindowsCamera',
    'Microsoft.MicrosoftStickyNotes',
    'microsoft.windowscommunicationsapps',
    'Microsoft.People',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.Todos',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'Microsoft.WindowsSoundRecorder',
    'Clipchamp.Clipchamp',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.SkypeApp',
    'MicrosoftTeams',
    'MSTeams',
    'Microsoft.Copilot',
    'Microsoft.Advertising',
    'MixedReality.Portal',
    'Microsoft.Windows.DevHome',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.OutlookForWindows'
)

foreach ($Pkg in $StorePackages) {
    Get-AppxPackage -AllUsers -Name "*$Pkg*" -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -like "*$Pkg*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# --- 2. Stop + disable Microsoft account/cloud/identity/telemetry services ---
#     (Removed "totally": they cannot auto-start, so 0 processes at idle.)
$StoreServices = @(
    "InstallService", "PushToInstall",
    "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "XboxGipSvc",
    "OneSyncSvc", "UserDataSvc", "UnistoreSvc", "PimIndexMaintenanceSvc",
    # CDPSvc/CDPUserSvc are pairing infrastructure, not Store services.
    "MessagingService", "BcastDVRUserService",
    "WSearch", "MapsBroker", "wisvc"
)

foreach ($Svc in $StoreServices) {
    Get-Service -Name "$Svc*" -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# Microsoft account sign-in + Web Account Manager: drop to demand-only.
# They never run at idle, but can still start if a sideloaded app asks for them -
# this is the crash-guard that stops "The service has not been started".
foreach ($Svc in @("wlidsvc", "TokenBroker")) {
    Get-Service -Name $Svc -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $_.Name -StartupType Manual -ErrorAction SilentlyContinue
    }
}

# KEEP the Windows shell's own AppX runtime healthy so the Start Menu/Search and
# Z-LAG Toolbox installed apps never crash:
foreach ($Svc in @("LicenseManager", "ClipSVC")) {
    Get-Service -Name $Svc -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Service -Name $_.Name -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $_.Name -ErrorAction SilentlyContinue
    }
}
foreach ($Svc in @("AppXSvc", "StateRepository")) {
    Get-Service -Name $Svc -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Service -Name $_.Name -StartupType Manual -ErrorAction SilentlyContinue
    }
}

# --- 3. Policy & registry lockdown for Store + MS accounts ---
$StorePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
if (-not (Test-Path $StorePolicyPath)) { New-Item -Path $StorePolicyPath -Force | Out-Null }
Set-ItemProperty -Path $StorePolicyPath -Name "RemoveWindowsStore" -Value 1 -Type DWord -Force
# Do NOT set DisableStoreApps=1 - that blocks ALL packaged apps and is the cause
# of "file system error (-2147416359)" on everything the toolbox installs.
Remove-ItemProperty -Path $StorePolicyPath -Name "DisableStoreApps" -ErrorAction SilentlyContinue

$SysPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $SysPolicyPath)) { New-Item -Path $SysPolicyPath -Force | Out-Null }
Set-ItemProperty -Path $SysPolicyPath -Name "BlockMicrosoftAccounts" -Value 1 -Type DWord -Force

$SecSysPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-ItemProperty -Path $SecSysPath -Name "NoConnectedUser" -Value 3 -Type DWord -Force

$PushInstallPath = "HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall"
if (-not (Test-Path $PushInstallPath)) { New-Item -Path $PushInstallPath -Force | Out-Null }
Set-ItemProperty -Path $PushInstallPath -Name "DisablePushToInstall" -Value 1 -Type DWord -Force

# --- 4. Sideload policy stays ON so the toolbox can still install apps ---
$AppxPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
if (-not (Test-Path $AppxPolicy)) { New-Item -Path $AppxPolicy -Force | Out-Null }
Set-ItemProperty -Path $AppxPolicy -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $AppxPolicy -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

$DevUnlock = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $DevUnlock)) { New-Item -Path $DevUnlock -Force | Out-Null }
Set-ItemProperty -Path $DevUnlock -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $DevUnlock -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

# --- 5. Marker so repair_appx_runtime.ps1 does not undo this removal ---
$ZlagKey = "HKLM:\SOFTWARE\Z-LAG-OS"
if (-not (Test-Path $ZlagKey)) { New-Item -Path $ZlagKey -Force | Out-Null }
Set-ItemProperty -Path $ZlagKey -Name "StoreRemoved" -Value 1 -Type DWord -Force

# --- 6. Remove Store shortcuts ---
Get-ChildItem -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Filter "*Store*" -Recurse -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

# --- 7. Clear the Start Menu cache so the Store stops showing ghost tiles ---
try {
    & (Join-Path $PSScriptRoot "clear_start_menu_cache.ps1")
} catch {
    Write-Output "[Z-LAG] Start Menu cache clear failed (non-fatal)."
}

Write-Output "[Z-LAG] Microsoft Store & Microsoft services fully removed (shell AppX stack preserved for stability)."
