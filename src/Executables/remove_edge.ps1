# ==============================================================================
# Z-LAG OS - Microsoft Edge + WebView2 COMPLETE remover
# ------------------------------------------------------------------------------
# Removes the Edge browser AND the Evergreen WebView2 Runtime. This is an
# intentionally aggressive configuration: applications that require WebView2
# will no longer work unless they install their own runtime again.
#
# Safe to re-run. Never prompts. Every pass is logged to:
#   C:\ProgramData\Z-LAG-OS\remove_edge.log
# ==============================================================================

$ErrorActionPreference = 'Continue'

$logDir = Join-Path $env:ProgramData 'Z-LAG-OS'
New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $logDir 'remove_edge.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-EDGE] ' + $Message
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

    # TrustedInstaller normally has access. This fallback also handles a script
    # launched manually by a regular elevated Administrator.
    & takeown.exe /f $Path /a /r /d y 2>$null | Out-Null
    & icacls.exe $Path /grant '*S-1-5-32-544:(OI)(CI)F' /t /c /q 2>$null | Out-Null
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
}

function Remove-ZLagRegistryPropertiesMatching {
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

function Clear-ZLagEdgeUserHive {
    param([Parameter(Mandatory = $true)][string]$HiveRoot)

    foreach ($runPath in @(
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Run'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\RunOnce'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32')
    )) {
        Remove-ZLagRegistryPropertiesMatching -Path $runPath -Pattern '(?i)msedge|Microsoft Edge|WebView'
    }

    foreach ($path in @(
        (Join-Path $HiveRoot 'Software\Microsoft\Edge'),
        (Join-Path $HiveRoot 'Software\Microsoft\EdgeWebView'),
        (Join-Path $HiveRoot 'Software\Microsoft\EdgeUpdate'),
        (Join-Path $HiveRoot 'Software\Clients\StartMenuInternet\Microsoft Edge'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView'),
        (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'),
        (Join-Path $HiveRoot 'Software\Classes\Applications\msedge.exe'),
        (Join-Path $HiveRoot 'Software\Classes\MSEdgeHTM'),
        (Join-Path $HiveRoot 'Software\Classes\MSEdgePDF'),
        (Join-Path $HiveRoot 'Software\Classes\MSEdgeMHT'),
        (Join-Path $HiveRoot 'Software\Classes\MSEdgeHTML')
    )) {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Remove stale per-extension UserChoice records that still point to an Edge
    # ProgID; leaving those records creates dead "Microsoft Edge" defaults.
    $fileExtRoot = Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts'
    Get-ChildItem -LiteralPath $fileExtRoot -ErrorAction SilentlyContinue |
        ForEach-Object {
            $choicePath = Join-Path $_.PSPath 'UserChoice'
            $progId = (Get-ItemProperty -LiteralPath $choicePath -Name ProgId -ErrorAction SilentlyContinue).ProgId
            if ($progId -match '^MSEdge') {
                Remove-Item -LiteralPath $choicePath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
}

$edgeBrowserGuid = '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
$webViewGuid     = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
$programFilesX86 = ${env:ProgramFiles(x86)}
if (-not $programFilesX86) { $programFilesX86 = $env:ProgramFiles }

$profiles = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $profilePath = (Get-ItemProperty -Path $_.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($profilePath) {
            [pscustomobject]@{
                Sid = $_.PSChildName
                Path = [Environment]::ExpandEnvironmentVariables($profilePath)
            }
        }
    }
$profileRoots = $profiles | ForEach-Object { $_.Path }

# 1. Stop every browser/runtime process so installers and folders are unlocked.
Write-ZLagLog 'Stopping Edge and WebView2 processes...'
$processNames = @(
    'msedge', 'msedge_proxy', 'msedgewebview2', 'MicrosoftEdgeUpdate',
    'MicrosoftEdgeCP', 'MicrosoftEdgeSH', 'Win32WebViewHost', 'WebViewHost',
    'Widgets', 'WidgetService'
)
foreach ($name in $processNames) {
    Stop-Process -Name $name -Force -ErrorAction SilentlyContinue
}

# 2. Use the official uninstallers first. WebView2 needs the --msedgewebview
# switch; without it setup.exe can report success while leaving the runtime.
Write-ZLagLog 'Running official Edge and WebView2 uninstallers...'
$setupJobs = @()
foreach ($base in @(
    (Join-Path $programFilesX86 'Microsoft\Edge\Application'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application'),
    (Join-Path $programFilesX86 'Microsoft\EdgeCore'),
    (Join-Path $env:ProgramFiles 'Microsoft\EdgeCore')
)) {
    if (Test-Path -LiteralPath $base) {
        Get-ChildItem -LiteralPath $base -Filter 'setup.exe' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                $setupJobs += [pscustomobject]@{
                    Path = $_.FullName
                    Args = @('--uninstall', '--system-level', '--force-uninstall', '--verbose-logging')
                }
            }
    }
}
foreach ($base in @(
    (Join-Path $programFilesX86 'Microsoft\EdgeWebView\Application'),
    (Join-Path $env:ProgramFiles 'Microsoft\EdgeWebView\Application')
)) {
    if (Test-Path -LiteralPath $base) {
        Get-ChildItem -LiteralPath $base -Filter 'setup.exe' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                $setupJobs += [pscustomobject]@{
                    Path = $_.FullName
                    Args = @('--uninstall', '--msedgewebview', '--system-level', '--force-uninstall', '--verbose-logging')
                }
            }
    }
}
# Per-user installs are independent from the system runtime and have their own
# setup.exe below LocalAppData. Remove those for every profile as well.
foreach ($profile in $profiles) {
    foreach ($spec in @(
        [pscustomobject]@{ RelativePath = 'AppData\Local\Microsoft\Edge\Application'; WebView = $false },
        [pscustomobject]@{ RelativePath = 'AppData\Local\Microsoft\EdgeCore'; WebView = $false },
        [pscustomobject]@{ RelativePath = 'AppData\Local\Microsoft\EdgeWebView\Application'; WebView = $true }
    )) {
        $base = Join-Path $profile.Path $spec.RelativePath
        if (Test-Path -LiteralPath $base) {
            Get-ChildItem -LiteralPath $base -Filter 'setup.exe' -File -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $arguments = @('--uninstall', '--user-level', '--force-uninstall', '--verbose-logging')
                    if ($spec.WebView) { $arguments = @('--uninstall', '--msedgewebview', '--user-level', '--force-uninstall', '--verbose-logging') }
                    $setupJobs += [pscustomobject]@{ Path = $_.FullName; Args = $arguments }
                }
        }
    }
}

foreach ($job in ($setupJobs | Sort-Object Path -Unique)) {
    [void](Invoke-ZLagProcess -FilePath $job.Path -Arguments $job.Args)
}

# Some WebView2 builds only expose an uninstall command in the uninstall key.
# Read it directly instead of Win32_Product/WMIC, which can trigger an MSI repair.
$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($root in $uninstallRoots) {
    Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Microsoft Edge WebView2|Microsoft Edge$' } |
        ForEach-Object {
            $command = $_.QuietUninstallString
            if (-not $command) { $command = $_.UninstallString }
            if ($command) {
                Write-ZLagLog ('  registered uninstaller: ' + $_.DisplayName)
                [void](Invoke-ZLagProcess -FilePath $env:ComSpec -Arguments @('/d', '/s', '/c', $command))
            }
        }
}
Start-Sleep -Seconds 2
foreach ($name in $processNames) {
    Stop-Process -Name $name -Force -ErrorAction SilentlyContinue
}

# 3. Remove every Edge/WebView package for existing and future users. There are
# deliberately no WebView exclusions in this pass.
Write-ZLagLog 'Removing Edge and WebView AppX packages...'
Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'Edge|WebView|Win32WebViewHost' } |
    ForEach-Object {
        Write-ZLagLog ('  appx: ' + $_.PackageFullName)
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Edge|WebView|Win32WebViewHost' } |
    ForEach-Object {
        Write-ZLagLog ('  deprovision: ' + $_.DisplayName)
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }

# 4. Delete shared updater services and scheduled tasks. Both Edge product IDs
# are blocked below, so keeping the WebView update client is no longer needed.
Write-ZLagLog 'Deleting Edge update services and tasks...'
foreach ($service in @('edgeupdate', 'edgeupdatem', 'MicrosoftEdgeElevationService')) {
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    & sc.exe delete $service 2>$null | Out-Null
}
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { ($_.TaskName + $_.TaskPath) -match 'MicrosoftEdge|EdgeUpdate|WebView' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
foreach ($task in @('MicrosoftEdgeUpdateTaskMachineCore', 'MicrosoftEdgeUpdateTaskMachineUA')) {
    & schtasks.exe /delete /tn $task /f 2>$null | Out-Null
}

# 5. Remove machine and per-user files, including EdgeWebView. The old remover
# intentionally skipped this directory, which is why WebView2 survived.
Write-ZLagLog 'Deleting Edge and WebView2 files...'
$machinePaths = @(
    (Join-Path $programFilesX86 'Microsoft\Edge'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge'),
    (Join-Path $programFilesX86 'Microsoft\EdgeCore'),
    (Join-Path $env:ProgramFiles 'Microsoft\EdgeCore'),
    (Join-Path $programFilesX86 'Microsoft\EdgeWebView'),
    (Join-Path $env:ProgramFiles 'Microsoft\EdgeWebView'),
    (Join-Path $programFilesX86 'Microsoft\EdgeUpdate'),
    (Join-Path $env:ProgramFiles 'Microsoft\EdgeUpdate'),
    (Join-Path $programFilesX86 'Microsoft\Temp'),
    (Join-Path $env:ProgramData 'Microsoft\EdgeUpdate'),
    (Join-Path $env:SystemRoot 'System32\Tasks\Microsoft\Windows\Edge'),
    (Join-Path $env:SystemRoot 'System32\Tasks\Microsoft\Windows\EdgeUpdate')
)
foreach ($path in ($machinePaths | Select-Object -Unique)) { Remove-ZLagPath -Path $path }

foreach ($profile in ($profileRoots | Select-Object -Unique)) {
    foreach ($relativePath in @(
        'AppData\Local\Microsoft\Edge',
        'AppData\Local\Microsoft\EdgeCore',
        'AppData\Local\Microsoft\EdgeWebView',
        'AppData\Local\Microsoft\EdgeUpdate',
        'AppData\Roaming\Microsoft\Edge'
    )) {
        Remove-ZLagPath -Path (Join-Path $profile $relativePath)
    }

    Get-ChildItem (Join-Path $profile 'AppData\Local\Packages') -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'Edge|WebView|Win32WebViewHost' } |
        ForEach-Object { Remove-ZLagPath -Path $_.FullName }
}

# Remove the legacy EdgeHTML and Win32 WebView system-app folders too.
Get-ChildItem (Join-Path $env:SystemRoot 'SystemApps') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^Microsoft\.MicrosoftEdge|^Microsoft\.Win32WebViewHost' } |
    ForEach-Object { Remove-ZLagPath -Path $_.FullName }
foreach ($file in @('MicrosoftEdgeCP.exe', 'MicrosoftEdgeSH.exe', 'MicrosoftEdge.exe')) {
    Remove-ZLagPath -Path (Join-Path $env:SystemRoot ('System32\' + $file))
}

# 6. Remove shortcuts from all profiles and refresh each Start cache.
Write-ZLagLog 'Removing Edge shortcuts and Start-menu cache entries...'
$shortcutNames = @('Microsoft Edge.lnk', 'Edge.lnk', 'Microsoft Edge (1).lnk')
foreach ($profile in (($profileRoots + $env:PUBLIC) | Where-Object { $_ } | Select-Object -Unique)) {
    foreach ($folder in @(
        'Desktop',
        'AppData\Roaming\Microsoft\Windows\Start Menu\Programs',
        'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch',
        'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
    )) {
        foreach ($shortcut in $shortcutNames) {
            Remove-ZLagPath -Path (Join-Path (Join-Path $profile $folder) $shortcut)
        }
    }
    Remove-ZLagPath -Path (Join-Path $profile 'AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start.bin')
}
foreach ($shortcut in $shortcutNames) {
    Remove-ZLagPath -Path (Join-Path $env:ProgramData ('Microsoft\Windows\Start Menu\Programs\' + $shortcut))
}

# 7. Registry cleanup: remove BOTH update clients and all runtime uninstall
# records. The policy values prevent Edge/WebView from being offered again by
# the Edge updater if Windows servicing recreates it later.
Write-ZLagLog 'Cleaning Edge and WebView2 registry entries...'
foreach ($profile in $profiles) {
    $hiveRoot = 'Registry::HKEY_USERS\' + $profile.Sid
    $temporaryHive = $false
    $temporaryName = 'ZLAG_Edge_' + ($profile.Sid -replace '[^A-Za-z0-9_]', '_')
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
        if (Test-Path -LiteralPath $hiveRoot) { Clear-ZLagEdgeUserHive -HiveRoot $hiveRoot }
    } finally {
        if ($temporaryHive) {
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            & reg.exe unload ('HKU\' + $temporaryName) 2>$null | Out-Null
        }
    }
}

$defaultProfile = Join-Path $env:SystemDrive 'Users\Default'
$defaultNtUser = Join-Path $defaultProfile 'NTUSER.DAT'
$defaultHiveName = 'ZLAG_Edge_DefaultUser'
if (Test-Path -LiteralPath $defaultNtUser) {
    & reg.exe unload ('HKU\' + $defaultHiveName) 2>$null | Out-Null
    & reg.exe load ('HKU\' + $defaultHiveName) $defaultNtUser 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        try { Clear-ZLagEdgeUserHive -HiveRoot ('Registry::HKEY_USERS\' + $defaultHiveName) }
        finally {
            [gc]::Collect()
            [gc]::WaitForPendingFinalizers()
            & reg.exe unload ('HKU\' + $defaultHiveName) 2>$null | Out-Null
        }
    }
}

$registryPaths = @(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Edge',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Edge',
    'Registry::HKEY_CURRENT_USER\Software\Microsoft\Edge',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EdgeWebView',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeWebView',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Clients\StartMenuInternet\Microsoft Edge',
    'Registry::HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\Microsoft Edge',
    'Registry::HKEY_CLASSES_ROOT\MSEdgeHTM',
    'Registry::HKEY_CLASSES_ROOT\MSEdgePDF',
    'Registry::HKEY_CLASSES_ROOT\MSEdgeMHT',
    'Registry::HKEY_CLASSES_ROOT\MSEdgeHTML',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
)
foreach ($path in $registryPaths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($uninstallRoot in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)) {
    Get-ChildItem -Path $uninstallRoot -ErrorAction SilentlyContinue |
        Where-Object {
            $item = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            $item.DisplayName -match 'Microsoft Edge|WebView2'
        } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($clientsRoot in @(
    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients'
)) {
    foreach ($productGuid in @($edgeBrowserGuid, $webViewGuid)) {
        Remove-Item -Path (Join-Path $clientsRoot $productGuid) -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\RegisteredApplications' -Name 'Microsoft Edge' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\RegisteredApplications' -Name 'Microsoft Edge' -ErrorAction SilentlyContinue

$edgePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
New-Item -Path $edgePolicy -Force -ErrorAction SilentlyContinue | Out-Null
$edgePolicyValues = @(
    [pscustomobject]@{ Name = 'InstallDefault'; Value = 0 },
    [pscustomobject]@{ Name = 'UpdateDefault'; Value = 0 },
    [pscustomobject]@{ Name = ('Install' + $edgeBrowserGuid); Value = 0 },
    [pscustomobject]@{ Name = ('Update' + $edgeBrowserGuid); Value = 0 },
    [pscustomobject]@{ Name = ('Install' + $webViewGuid); Value = 0 },
    [pscustomobject]@{ Name = ('Update' + $webViewGuid); Value = 0 }
)
foreach ($entry in $edgePolicyValues) {
    New-ItemProperty -Path $edgePolicy -Name $entry.Name -Value $entry.Value -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
}
$edgeUpdate = 'HKLM:\SOFTWARE\Microsoft\EdgeUpdate'
New-Item -Path $edgeUpdate -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $edgeUpdate -Name 'DoNotUpdateToEdgeWithChromium' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'EdgeRemoved' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'WebView2Removed' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'WebView2Status' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $marker -Name 'WebView2RepairDate' -ErrorAction SilentlyContinue

$remainingRuntime = Get-ChildItem -Path (Join-Path $programFilesX86 'Microsoft\EdgeWebView\Application') -Filter 'msedgewebview2.exe' -File -Recurse -ErrorAction SilentlyContinue
if ($remainingRuntime) {
    Write-ZLagLog 'WARNING: a locked WebView2 runtime file remains; reboot will release it for the next cleanup pass.'
} else {
    Write-ZLagLog 'Microsoft Edge and WebView2 were removed successfully.'
}
