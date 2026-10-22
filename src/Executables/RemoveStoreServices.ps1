# ==============================================================================
# Z-LAG OS - Microsoft Store & Microsoft Services TOTAL Removal Engine
# Runs ONLY when the user picks "Remove Microsoft Store & All MS Services".
#
#   * Uninstalls + deprovisions the Store and every Microsoft consumer/cloud app
#     and checks registered packages plus provisioning after removal.
#   * Stops + disables Microsoft account / cloud / identity / telemetry services
#     including per-user templates so the setting survives a new logon.
#   * Sets a marker (HKLM:\SOFTWARE\Z-LAG-OS\StoreRemoved=1) so the AppX repair
#     step knows NOT to re-enable Microsoft account services afterwards.
#
# NOTE ON THE SMALL PRINT: the Windows desktop shell itself (Start Menu, Search,
# Action Center) is a packaged-app runtime. Those 4 tiny services
# (AppXSvc, StateRepository, LicenseManager, ClipSVC) are PART OF WINDOWS, not
# "Store bloat" - deleting them breaks the shell and makes apps installed by
# Z-LAG Toolbox crash with "The service has not been started". They are kept so
# everything keeps working; Microsoft account sign-in (wlidsvc) + Web Account
# Manager (TokenBroker) remain demand-only for packaged-app compatibility.
# ==============================================================================

$ErrorActionPreference = "Continue"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Error '[Z-LAG] Administrator or SYSTEM privileges are required.'
    exit 1
}
$failures = New-Object 'System.Collections.Generic.List[string]'
# Save intent before mutation so subsequent runtime repair respects the selection,
# even if Windows refuses one of the packages. This is not a success marker.
$ZlagKey = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $ZlagKey -Force -ErrorAction Stop | Out-Null
New-ItemProperty -Path $ZlagKey -Name StoreRemoved -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
New-ItemProperty -Path $ZlagKey -Name StoreRemovalComplete -Value 0 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
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

# Defense-in-depth vendor guard (fixes: "NVIDIA App not working"): even though
# the list above is Microsoft-only, any future edit must never be able to
# pattern-match a GPU vendor package out of the machine.
function Test-ZLagProtectedVendor {
    param([object]$Pkg)
    $hay = ([string]$Pkg.PackageFullName + ' ' + [string]$Pkg.PackageFamilyName + ' ' + [string]$Pkg.Name + ' ' + [string]$Pkg.DisplayName + ' ' + [string]$Pkg.Publisher)
    return ($hay -match 'nvidia|amd|advanced micro devices|intel')
}

# AppX deployment must be available while removing registered/provisioned apps.
foreach ($name in @('AppXSvc', 'ClipSVC', 'StateRepository')) {
    if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
        & sc.exe config $name start= demand | Out-Null
    }
}
try {
    $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop)
    $installed = @(Get-AppxPackage -AllUsers -ErrorAction Stop)
} catch {
    Write-Error ("[Z-LAG] Cannot enumerate AppX packages: " + $_.Exception.Message)
    exit 1
}
foreach ($Pkg in $StorePackages) {
    $installed | Where-Object { $_.Name -eq $Pkg -and -not (Test-ZLagProtectedVendor -Pkg $_) } | ForEach-Object {
        try {
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop | Out-Null
        } catch {
            Write-Warning ("[Z-LAG] Could not remove " + $Pkg + ': ' + $_.Exception.Message)
        }
    }
    $provisioned | Where-Object { $_.DisplayName -eq $Pkg -and -not (Test-ZLagProtectedVendor -Pkg $_) } | ForEach-Object {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -AllUsers -ErrorAction Stop | Out-Null
        } catch {
            Write-Warning ("[Z-LAG] Deprovision failed: " + $_.Exception.Message)
        }
    }
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
    # Match only the base service or per-user instances, never unrelated prefixes.
    # Include templates: disabling just today's instance does not survive logon.
    $keys = @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction Stop |
        Where-Object { $_.PSChildName -eq $Svc -or $_.PSChildName -like "${Svc}_*" })
    foreach ($key in $keys) {
        $name = $key.PSChildName
        & sc.exe config $name start= disabled 2>$null | Out-Null
        try {
            Set-ItemProperty -LiteralPath $key.PSPath -Name Start -Value 4 -Type DWord -Force -ErrorAction Stop
        } catch {
            $failures.Add("Cannot disable $name : $($_.Exception.Message)")
        }
        if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
            # sc stop does not block indefinitely on dependent services.
            & sc.exe stop $name 2>$null | Out-Null
        }
        if ((Get-ItemProperty -LiteralPath $key.PSPath -Name Start -ErrorAction SilentlyContinue).Start -ne 4) {
            $failures.Add("Startup verification failed: $name")
        }
    }
}

# Microsoft account sign-in + Web Account Manager: drop to demand-only.
# They are not explicitly started here, but can still start if a sideloaded app asks for them -
# this preserves sign-in dependencies used by some sideloaded apps.
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

# --- 5. Confirm the removal intent for subsequent runtime repair ---
$ZlagKey = "HKLM:\SOFTWARE\Z-LAG-OS"
if (-not (Test-Path $ZlagKey)) { New-Item -Path $ZlagKey -Force | Out-Null }
New-ItemProperty -Path $ZlagKey -Name "StoreRemoved" -Value 1 -PropertyType DWord -Force | Out-Null
$markerCheck = (Get-ItemProperty -Path $ZlagKey -Name StoreRemoved -ErrorAction SilentlyContinue).StoreRemoved
Write-Output ("[Z-LAG] Store removal marker committed: " + $markerCheck)

# --- 6. Remove Store shortcuts ---
Get-ChildItem -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Filter "*Store*" -Recurse -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

# --- 7. Clear the Start Menu cache so the Store stops showing ghost tiles ---
try {
    & (Join-Path $PSScriptRoot "clear_start_menu_cache.ps1")
} catch {
    Write-Output "[Z-LAG] Start Menu cache clear failed (non-fatal)."
}

# Verify actual state, not just whether the removal commands were invoked.
try {
    $remaining = @(Get-AppxPackage -AllUsers -ErrorAction Stop | Where-Object { $_.Name -in $StorePackages })
    $remainingProvisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop |
        Where-Object { $_.DisplayName -in $StorePackages })
    foreach ($package in $remaining) { $failures.Add("Still registered: $($package.PackageFullName)") }
    foreach ($package in $remainingProvisioned) { $failures.Add("Still provisioned: $($package.PackageName)") }
    foreach ($Svc in $StoreServices) {
        Get-Service -ErrorAction Stop | Where-Object {
            ($_.Name -eq $Svc -or $_.Name -like "${Svc}_*") -and $_.Status -ne 'Stopped'
        } | ForEach-Object { $failures.Add("Service not stopped (reboot may be needed): $($_.Name)") }
    }
} catch {
    $failures.Add("Verification failed: $($_.Exception.Message)")
}
if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Warning "[Z-LAG] $_" }
    Write-Error '[Z-LAG] Removal incomplete. Review warnings, reboot and retry; shell/runtime services are intentionally preserved.'
    exit 1
}
Set-ItemProperty -Path $ZlagKey -Name StoreRemovalComplete -Value 1 -Type DWord -Force -ErrorAction Stop
Write-Output '[Z-LAG] Selected packages removed and targeted services disabled; required Windows runtime preserved.'
exit 0
