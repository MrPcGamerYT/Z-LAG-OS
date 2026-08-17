# ==============================================================================
# Z-LAG OS - Apply user-facing settings to the ACTIVE user (runas currentUserElevated)
# ------------------------------------------------------------------------------
# AME runs !registryValue as TrustedInstaller, whose HKCU is the SYSTEM account's
# hive - so taskbar / dark-mode / explorer / start-menu tweaks written there
# never reach the real user. This script runs with `runas: currentUserElevated`,
# so HKCU == the logged-in user, and it ALSO mirrors each value into
# HKU\.DEFAULT so future accounts inherit the same settings.
# Idempotent - safe to re-run.
# ==============================================================================
$ErrorActionPreference = "Continue"

function Set-ZLagUserValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,      # HKCU:\... path
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Name,
        [Parameter(Mandatory = $true)][AllowEmptyString()]$Value,
        [Parameter(Mandatory = $true)][ValidateSet('DWord', 'String', 'Binary')]$Type
    )
    $defaultTarget = $Path -replace '^HKCU:', 'Registry::HKEY_USERS\.DEFAULT'
    foreach ($target in @($Path, $defaultTarget)) {
        try {
            if (-not (Test-Path $target)) { New-Item -Path $target -Force -ErrorAction Stop | Out-Null }
            if ($Name -eq '') {
                Set-Item -Path $target -Value $Value -Force -ErrorAction Stop
            } else {
                New-ItemProperty -Path $target -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
            }
        } catch { }
    }
}

# --- Dark mode / transparency ---
Set-ZLagUserValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme'     0 'DWord'
Set-ZLagUserValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme'  0 'DWord'
Set-ZLagUserValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency'    0 'DWord'

# --- Taskbar / Explorer / visual effects ---
Set-ZLagUserValue 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
Set-ZLagUserValue 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' 'String'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations'    0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewAlphaSelect' 0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ListviewShadow'      0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt'         0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton'  0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn'           0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'EnableSnapAssistFlyout' 0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'DisallowShaking'     1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl'           0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa'           0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarSi'           0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCopilotButton'   0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAVolume'       0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'EnableSnapBar'       0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'EnableTaskGroups'    0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'SnapFill'            0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'LaunchTo'            1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek'            0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\DWM' 'AlwaysHibernateThumbnails' 1 'DWord'

# --- Mouse / keyboard ---
Set-ZLagUserValue 'HKCU:\Control Panel\Mouse' 'MouseSpeed'      '0'  'String'
Set-ZLagUserValue 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0'  'String'
Set-ZLagUserValue 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0'  'String'
Set-ZLagUserValue 'HKCU:\Control Panel\Mouse' 'MouseHoverTime'  '1'  'String'
Set-ZLagUserValue 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0'  'String'
Set-ZLagUserValue 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'

# --- Start menu (clean app-list only) ---
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs'       0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackDocs'        0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowRecentApps'   0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowAddedApps'    0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowAllApps'      1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowSettings'     1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowDownloads'    0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowUser'         0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowPowerButton'  1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_ShowSearch'       0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoStartMenuMorePrograms' 0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'ShowStartMenuAllApps'   1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoPinnedAppsInStartMenu' 1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'ClearRecentPrograms'    1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'HideRecommendedSection'             1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions'        1 'DWord'

# --- Game config ---
Set-ZLagUserValue 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode'           2 'DWord'
Set-ZLagUserValue 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode'  1 'DWord'
Set-ZLagUserValue 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1 'DWord'
Set-ZLagUserValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled'                  0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 'DWord'
# Game Mode ON (scheduler-level protection for the foreground game; no extra
# processes). GameDVR/capture above stays OFF - only the scheduler policy is kept.
Set-ZLagUserValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode'   1 'DWord'

# --- Notifications ---
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' 'ToastEnabled' 0 'DWord'

# --- Search / suggestions / content delivery ---
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled'      0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent'         0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CloudSearchEnabled'     0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode'   0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode' 2 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAMeetNow' 1 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled'   0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenEnabled'    0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled'           0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled'      0 'DWord'
Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled'   0 'DWord'
foreach ($v in @('SubscribedContent-314559Enabled','SubscribedContent-338387Enabled','SubscribedContent-338388Enabled','SubscribedContent-338389Enabled','SubscribedContent-338393Enabled')) {
    Set-ZLagUserValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $v 0 'DWord'
}

# --- Classic right-click context menu (Windows 11) ---
Set-ZLagUserValue 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '' '' 'String'

Write-Output "[Z-LAG] User-facing settings applied to the active user + default user."
