# ==============================================================================
# Z-LAG OS - Complete OneDrive remover
# ------------------------------------------------------------------------------
# Uninstalls machine/per-user clients, deprovisions the inbox package, removes
# startup entries, scheduled tasks, shell namespaces, sync-root registrations,
# shortcuts, installers and caches for every local profile.
#
# -RemoveSyncedData also deletes each profile's OneDrive / OneDrive - * folders.
# Z-LAG invokes that switch because the playbook requires a fresh Windows install.
# Logs: C:\ProgramData\Z-LAG-OS\remove_onedrive.log
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$RemoveSyncedData
)

$ErrorActionPreference = 'Continue'
$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $logDir 'remove_onedrive.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-ONEDRIVE] ' + $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-ZLagLog 'ERROR: Administrator privileges are required.'
    exit 1
}

function Invoke-ZLagProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 120
    )
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) { return $false }
    try {
        Write-ZLagLog ('  run: ' + $FilePath + ' ' + ($Arguments -join ' '))
        $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WindowStyle Hidden -PassThru -ErrorAction Stop
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            Write-ZLagLog ('  timeout; terminating PID ' + $process.Id)
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            return $false
        }
        return ($process.ExitCode -eq 0)
    } catch {
        Write-ZLagLog ('  command failed: ' + $_.Exception.Message)
        return $false
    }
}

function Remove-ZLagPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }

    Write-ZLagLog ('  delete: ' + $Path)
    try {
        & attrib.exe -r -s -h $Path /s /d 2>$null | Out-Null
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        return
    } catch { }

    & takeown.exe /f $Path /a /r /d y 2>$null | Out-Null
    & icacls.exe $Path /grant '*S-1-5-32-544:(OI)(CI)F' /t /c /q 2>$null | Out-Null
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-PropertiesMatching {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern
    )
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $item) { return }
    foreach ($property in $item.GetValueNames()) {
        $value = $item.GetValue($property, '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if (($property -match $Pattern) -or ([string]$value -match $Pattern)) {
            Remove-ItemProperty -LiteralPath $Path -Name $property -Force -ErrorAction SilentlyContinue
        }
    }
}

function Reset-OneDriveKnownFolders {
    param(
        [Parameter(Mandatory = $true)][string]$HiveRoot,
        [Parameter(Mandatory = $true)][string]$ProfilePath
    )

    $userShell = Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    if (-not (Test-Path -LiteralPath $userShell)) { return }

    $defaults = [ordered]@{
        'Desktop' = '%USERPROFILE%\Desktop'
        'Personal' = '%USERPROFILE%\Documents'
        'My Pictures' = '%USERPROFILE%\Pictures'
        'My Music' = '%USERPROFILE%\Music'
        'My Video' = '%USERPROFILE%\Videos'
        'Favorites' = '%USERPROFILE%\Favorites'
        '{374DE290-123F-4565-9164-39C4925E467B}' = '%USERPROFILE%\Downloads'
        '{F42EE2D3-909F-4907-8871-4C22FC0BF756}' = '%USERPROFILE%\Documents'
        '{0DDD015D-B06C-45D5-8C4C-F59713854639}' = '%USERPROFILE%\Pictures'
    }

    $key = Get-Item -LiteralPath $userShell -ErrorAction SilentlyContinue
    foreach ($entry in $defaults.GetEnumerator()) {
        $current = $key.GetValue($entry.Key, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($null -ne $current -and ([string]$current -match '(?i)OneDrive')) {
            Write-ZLagLog ('  reset known folder for ' + $ProfilePath + ': ' + $entry.Key)
            New-ItemProperty -LiteralPath $userShell -Name $entry.Key -Value $entry.Value -PropertyType ExpandString -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Clean-OneDriveUserHive {
    param(
        [Parameter(Mandatory = $true)][string]$HiveRoot,
        [Parameter(Mandatory = $true)][string]$ProfilePath
    )

    Reset-OneDriveKnownFolders -HiveRoot $HiveRoot -ProfilePath $ProfilePath

    foreach ($path in @(
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Run'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\RunOnce'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder')
    )) {
        Remove-PropertiesMatching -Path $path -Pattern '(?i)OneDrive'
    }

    foreach ($path in @(
        (Join-Path $HiveRoot 'Software\Microsoft\OneDrive'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\OneDrive'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'),
        (Join-Path $HiveRoot 'Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'),
        (Join-Path $HiveRoot 'Software\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}')
    )) {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
    }

    foreach ($root in @(
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager'),
        (Join-Path $HiveRoot 'Software\SyncEngines\Providers')
    )) {
        Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue |
            Where-Object {
                $values = (Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue | Out-String)
                ($_.PSChildName -match '(?i)OneDrive') -or ($values -match '(?i)OneDrive')
            } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-ZLagLog 'Stopping OneDrive processes...'
foreach ($process in @('OneDrive', 'OneDriveSetup', 'OneDriveStandaloneUpdater', 'FileCoAuth', 'Microsoft.SharePoint')) {
    Stop-Process -Name $process -Force -ErrorAction SilentlyContinue
}

# Discover setup programs before uninstalling because successful uninstallers
# normally delete themselves.
Write-ZLagLog 'Running all detected OneDrive uninstallers...'
$setupCandidates = @(
    (Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe'),
    (Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\Update\OneDriveSetup.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft OneDrive\OneDriveSetup.exe')
)
$programFilesX86 = ${env:ProgramFiles(x86)}
if ($programFilesX86) { $setupCandidates += (Join-Path $programFilesX86 'Microsoft OneDrive\OneDriveSetup.exe') }

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $profilePath = (Get-ItemProperty -Path $_.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profilePath) {
            $profilePath = [Environment]::ExpandEnvironmentVariables($profilePath)
            $setupCandidates += (Join-Path $profilePath 'AppData\Local\Microsoft\OneDrive\Update\OneDriveSetup.exe')
        }
    }
foreach ($setup in ($setupCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)) {
    [void](Invoke-ZLagProcess -FilePath $setup -Arguments @('/uninstall', '/allusers'))
    if (Test-Path -LiteralPath $setup) {
        [void](Invoke-ZLagProcess -FilePath $setup -Arguments @('/uninstall'))
    }
}
Start-Sleep -Seconds 2
foreach ($process in @('OneDrive', 'OneDriveSetup', 'OneDriveStandaloneUpdater', 'FileCoAuth')) {
    Stop-Process -Name $process -Force -ErrorAction SilentlyContinue
}

Write-ZLagLog 'Removing OneDrive AppX and provisioned packages...'
Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '(?i)OneDrive' } |
    ForEach-Object {
        Write-ZLagLog ('  appx: ' + $_.PackageFullName)
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match '(?i)OneDrive' } |
    ForEach-Object {
        Write-ZLagLog ('  deprovision: ' + $_.DisplayName)
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }

Write-ZLagLog 'Removing OneDrive scheduled tasks and startup entries...'
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { ($_.TaskName + $_.TaskPath) -match '(?i)OneDrive' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
foreach ($runPath in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
)) {
    Remove-PropertiesMatching -Path $runPath -Pattern '(?i)OneDrive'
}

# Clean every user, including users who are not currently signed in. Offline
# NTUSER.DAT hives are mounted temporarily and always unloaded in finally.
Write-ZLagLog 'Cleaning OneDrive from every user registry hive...'
$profiles = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $sid = $_.PSChildName
        $profilePath = (Get-ItemProperty -Path $_.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profilePath) {
            [pscustomobject]@{
                Sid = $sid
                Path = [Environment]::ExpandEnvironmentVariables($profilePath)
            }
        }
    }

foreach ($profile in $profiles) {
    $hiveRoot = 'Registry::HKEY_USERS\' + $profile.Sid
    $temporaryHive = $false
    $temporaryName = 'ZLAG_OneDrive_' + ($profile.Sid -replace '[^A-Za-z0-9_]', '_')

    if (-not (Test-Path -LiteralPath $hiveRoot)) {
        $ntUser = Join-Path $profile.Path 'NTUSER.DAT'
        if (Test-Path -LiteralPath $ntUser) {
            & reg.exe load ('HKU\' + $temporaryName) $ntUser 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $hiveRoot = 'Registry::HKEY_USERS\' + $temporaryName
                $temporaryHive = $true
            }
        }
    }

    try {
        if (Test-Path -LiteralPath $hiveRoot) {
            Clean-OneDriveUserHive -HiveRoot $hiveRoot -ProfilePath $profile.Path
        }
    } finally {
        if ($temporaryHive) {
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            & reg.exe unload ('HKU\' + $temporaryName) 2>$null | Out-Null
        }
    }
}

# ProfileList does not contain C:\Users\Default. Remove its OneDriveSetup Run
# hook explicitly or Windows can reinstall OneDrive for the next account created.
$defaultProfile = Join-Path $env:SystemDrive 'Users\Default'
$defaultNtUser = Join-Path $defaultProfile 'NTUSER.DAT'
$defaultHiveName = 'ZLAG_OneDrive_DefaultUser'
if (Test-Path -LiteralPath $defaultNtUser) {
    & reg.exe unload ('HKU\' + $defaultHiveName) 2>$null | Out-Null
    & reg.exe load ('HKU\' + $defaultHiveName) $defaultNtUser 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        try {
            Clean-OneDriveUserHive -HiveRoot ('Registry::HKEY_USERS\' + $defaultHiveName) -ProfilePath $defaultProfile
        } finally {
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            & reg.exe unload ('HKU\' + $defaultHiveName) 2>$null | Out-Null
        }
    }
}

# Machine-wide namespace, COM, sync-root and uninstall registrations.
Write-ZLagLog 'Removing OneDrive shell and machine registry integration...'
$namespaceClsid = '{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
$machineKeys = @(
    ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\' + $namespaceClsid),
    ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\CLSID\' + $namespaceClsid),
    ('Registry::HKEY_CLASSES_ROOT\CLSID\' + $namespaceClsid),
    ('Registry::HKEY_CLASSES_ROOT\WOW6432Node\CLSID\' + $namespaceClsid),
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OneDrive',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\OneDrive',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager\OneDrive',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe'
)
foreach ($key in $machineKeys) {
    Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($root in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager',
    'HKLM:\SOFTWARE\SyncEngines\Providers',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)) {
    Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue |
        Where-Object {
            $values = (Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue | Out-String)
            ($_.PSChildName -match '(?i)OneDrive') -or ($values -match '(?i)OneDrive')
        } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# Keep a machine policy in place so Windows does not silently configure the sync
# client for a newly-created user after its binaries have been removed.
foreach ($policy in @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive',
    'HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows\OneDrive'
)) {
    New-Item -Path $policy -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $policy -Name 'DisableFileSyncNGSC' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $policy -Name 'DisableFileSync' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
}

Write-ZLagLog 'Deleting OneDrive binaries, caches and shortcuts...'
$paths = @(
    (Join-Path $env:ProgramData 'Microsoft OneDrive'),
    (Join-Path $env:ProgramData 'Microsoft\OneDrive'),
    (Join-Path $env:ProgramFiles 'Microsoft OneDrive'),
    (Join-Path $env:SystemDrive 'OneDriveTemp'),
    (Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'),
    (Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe'),
    (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\OneDrive.lnk')
)
if ($programFilesX86) { $paths += (Join-Path $programFilesX86 'Microsoft OneDrive') }

foreach ($profile in $profiles) {
    $paths += @(
        (Join-Path $profile.Path 'AppData\Local\Microsoft\OneDrive'),
        (Join-Path $profile.Path 'AppData\Local\OneDrive'),
        (Join-Path $profile.Path 'AppData\Roaming\Microsoft\OneDrive'),
        (Join-Path $profile.Path 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'),
        (Join-Path $profile.Path 'Desktop\OneDrive.lnk'),
        (Join-Path $profile.Path 'OneDriveTemp')
    )
    if ($RemoveSyncedData) {
        $paths += (Join-Path $profile.Path 'OneDrive')
        Get-ChildItem -LiteralPath $profile.Path -Directory -Filter 'OneDrive - *' -ErrorAction SilentlyContinue |
            ForEach-Object { $paths += $_.FullName }
    }
}
if ($RemoveSyncedData) {
    Write-ZLagLog 'RemoveSyncedData is enabled: deleting local OneDrive sync folders.'
}
foreach ($path in ($paths | Where-Object { $_ } | Select-Object -Unique)) {
    Remove-ZLagPath -Path $path
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'OneDriveRemoved' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'OneDriveRemovalDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null

Write-ZLagLog 'OneDrive client, provisioning, startup integration and shell entries were removed.'
