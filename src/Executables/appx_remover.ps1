param (
    [Parameter(Mandatory = $true)]
    [string[]]$Packages,
    [Parameter(Mandatory = $false)]
    [string[]]$ExcludePackages = @(),
    [Parameter(Mandatory = $false)]
    [switch]$Unregister = $false
)

# CRITICAL: Apps to KEEP (ONLY NVIDIA, AMD, Intel, and ABSOLUTELY ESSENTIAL system apps)
$KeepApps = @(
    # NVIDIA
    'NVIDIA', 'NVIDIACorp', 'NVIDIA.ControlPanel', 'NVIDIA.GraphicsDriver', 'NVIDIA.Display',
    'Nvidia', 'NvContainer', 'NvTelemetry',
    
    # AMD
    'AMD', 'AMDRadeon', 'AMD.RadeonSoftware', 'AMD.ChipsetDriver', 'Amd', 'AmdRyzenMaster',
    
    # Intel
    'Intel', 'IntelCorp', 'Intel.GraphicsCommandCenter', 'Intel.Driver', 'Intc', 'IntelGraphics',
    
    # ABSOLUTELY ESSENTIAL (DO NOT REMOVE - breaks Windows)
    'Microsoft.Windows.Explorer',
    'Microsoft.Windows.ShellExperienceHost',
    'Microsoft.Windows.StartMenuExperienceHost',
    'Microsoft.Windows.Search',
    'Microsoft.VCLibs',
    'Microsoft.UI.Xaml',
    'Microsoft.NET.Native'
    # NOTE: Microsoft.WindowsStore, Microsoft.WindowsCalculator, Microsoft.Windows.Photos, 
    # Microsoft.Xbox*, Microsoft.GamingApp, Microsoft.YourPhone, Microsoft.SkypeApp, 
    # Microsoft.Bing*, Microsoft.Zune*, Clipchamp, Disney, Spotify, Netflix, Teams, Copilot
    # are NOT protected and WILL BE REMOVED
)

# Filter out packages to keep
$FilteredPackages = @()
foreach ($package in $Packages) {
    $shouldKeep = $false
    foreach ($keep in $KeepApps) {
        if ($package -like "*$keep*") {
            $shouldKeep = $true
            Write-Host "Skipping protected app: $package"
            break
        }
    }
    if (-not $shouldKeep) {
        $FilteredPackages += $package
    }
}

$baseRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore"
$allPackages = Get-AppxPackage -AllUsers | Select-Object PackageFullName, PackageFamilyName, PackageUserInformation, NonRemovable

foreach ($package in $FilteredPackages) {
    $filteredPackages = $allPackages | Where-Object { $_.PackageFullName -like "*$package*" }
    
    if ($ExcludePackages.Count -gt 0) {
        $filteredPackages = $filteredPackages | Where-Object {
            $fullPackageName = $_.PackageFullName
            -not ($ExcludePackages | Where-Object { $fullPackageName -like "*$_*" })
        }
    }

    foreach ($pkg in $filteredPackages) {
        $fullPackageName = $pkg.PackageFullName
        $packageFamilyName = $pkg.PackageFamilyName

        # Double-check we're not removing critical apps
        $isProtected = $false
        foreach ($keep in $KeepApps) {
            if ($fullPackageName -like "*$keep*" -or $packageFamilyName -like "*$keep*") {
                $isProtected = $true
                Write-Host "Protected package skipped: $fullPackageName"
                break
            }
        }
        
        if ($isProtected) { continue }

        Write-Host "Removing package: $($fullPackageName)"

        $deprovisionedPath = "$baseRegistryPath\Deprovisioned\$packageFamilyName"
        if (-not (Test-Path -Path $deprovisionedPath)) {
            New-Item -Path $deprovisionedPath -Force | Out-Null
        }

        $inboxAppsPath = "$baseRegistryPath\InboxApplications\$fullPackageName"
        if (Test-Path $inboxAppsPath) {
            Remove-Item -Path $inboxAppsPath -Force -ErrorAction SilentlyContinue
        }
        
        if ($pkg.NonRemovable -eq 1) {
            Write-Host "Non-removable package detected: $packageFamilyName - skipping"
            continue
        }

        foreach ($userInfo in $pkg.PackageUserInformation) {
            $userSid = $userInfo.UserSecurityID.SID
            $endOfLifePath = "$baseRegistryPath\EndOfLife\$userSid\$fullPackageName"
            New-Item -Path $endOfLifePath -Force | Out-Null

            if ($Unregister) {
                Remove-AppxPackage -Package $fullPackageName -User $userSid -PreserveRoamableApplicationData -ErrorAction SilentlyContinue
            } else {
                Remove-AppxPackage -Package $fullPackageName -User $userSid -ErrorAction SilentlyContinue
            }
        }

        if ($Unregister) {
            Remove-AppxPackage -Package $fullPackageName -AllUsers -PreserveRoamableApplicationData -ErrorAction SilentlyContinue
        } else {
            Remove-AppxPackage -Package $fullPackageName -AllUsers -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "AppX removal completed! Protected apps (NVIDIA, AMD, Intel, essential system apps) kept intact."