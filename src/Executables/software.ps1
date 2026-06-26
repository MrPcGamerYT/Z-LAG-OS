param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$OperaGX
)

# ---------------- SAFE BOOTSTRAP ----------------
$ErrorActionPreference = "SilentlyContinue"

# FIX: Increased connect timeout to 30s, added 600s max total time, and set retry delay to 3s to avoid rate-limiting.
$timeouts = @("--connect-timeout", "30", "--max-time", "600", "--retry", "5", "--retry-delay", "3")
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"

# Cleanly detect System Architecture (Returns: X86, X64, ARM, or ARM64)
$osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToUpper()

# Temp directory
$systemDrive = $env:SystemDrive
$tempDir = Join-Path $systemDrive ([System.Guid]::NewGuid().ToString())

New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
Push-Location $tempDir

function Remove-TempDirectory {
    Pop-Location
    Remove-Item -Path $tempDir -Force -Recurse -EA 0
}

# Enforce TLS 1.2/1.3 protocol handling for secure web downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13


# ---------------- UNIVERSAL ALT APP INSTALLER SETUP ----------------
Write-Output "Fetching latest AltAppInstaller release metadata from official repository..."

$repoUrl = "https://api.github.com/repos/mjishnu/alt-app-installer/releases/latest"

try {
    $releaseInfo = Invoke-RestMethod -Uri $repoUrl -UseBasicParsing
    
    if ($releaseInfo) {
        # Dynamically matches primary release distribution zip files (e.g., altappinstaller-v2.7.3.zip)
        $zipAsset = $releaseInfo.assets | Where-Object { 
            $_.name -like "altappinstaller-v*.zip" -or $_.name -like "*.zip"
        } | Where-Object { $_.name -notlike "*cert*" } | Select-Object -First 1

        if ($zipAsset) {
            $downloadUrl = $zipAsset.browser_download_url
            $zipPath = Join-Path $tempDir "AltAppInstaller.zip"
            $installDir = "C:\Program Files\AltAppInstaller"

            Write-Output "Downloading package from: $downloadUrl"
            & curl.exe -LSs $downloadUrl -o $zipPath $timeouts

            if (Test-Path $zipPath) {
                Write-Output "Extracting AltAppInstaller package to $installDir..."
                if (!(Test-Path $installDir)) {
                    New-Item -Path $installDir -ItemType Directory -Force | Out-Null
                }
                
                Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
                
                # Recursively locate the primary entry point application executable
                $exePath = Get-ChildItem -Path $installDir -Filter "altappinstaller.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1

                if ($exePath) {
                    Write-Output "Creating system Start Menu shortcut link..."
                    $startMenuPath = [System.IO.Path]::Combine($env:ProgramData, "Microsoft\Windows\Start Menu\Programs")
                    $shortcutPath = Join-Path $startMenuPath "Alt App Installer.lnk"
                    
                    $wshShell = New-Object -ComObject WScript.Shell
                    $shortcut = $wshShell.CreateShortcut($shortcutPath)
                    $shortcut.TargetPath = $exePath
                    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($exePath)
                    $shortcut.Description = "Alt App Installer - Alternative Windows Store Frontend"
                    $shortcut.Save()
                    Write-Output "AltAppInstaller successfully deployed."
                } else {
                    Write-Warning "Extraction successful, but could not identify altappinstaller.exe application entry."
                }
            }
        } else {
            Write-Warning "Could not isolate target binary zip file asset inside release payloads."
        }
    }
} catch {
    Write-Warning "An error occurred configuring AltAppInstaller deployment pipeline: $_"
}


# ---------------- BRAVE ----------------
if ($Brave) {
    Write-Output "Downloading Brave..."
    
    $braveArch = if ($osArch -eq "X86") { "winia32" } else { "winx64" }
    $braveUrl = "https://laptop-updates.brave.com/latest/$braveArch"

    & curl.exe -LSs $braveUrl -o "$tempDir\BraveSetup.exe" $timeouts

    if (!$?) {
        Write-Error "Brave download failed."
        exit 1
    }

    Write-Output "Installing Brave..."
    Start-Process -FilePath "$tempDir\BraveSetup.exe" `
        -WindowStyle Hidden -ArgumentList "/silent /install" -Wait

    Remove-TempDirectory
    exit
}

# ---------------- OPERA GX ----------------
if ($OperaGX) {
    Write-Output "Downloading Opera GX (latest)..."
    & curl.exe -LSs "https://net.geo.opera.com/opera_gx/stable/windows" `
        -o "$tempDir\operagx.exe" $timeouts

    if (!$?) {
        Write-Error "Opera GX download failed."
        exit 1
    }

    Write-Output "Installing Opera GX..."
    Start-Process -FilePath "$tempDir\operagx.exe" `
        -ArgumentList "/silent /allusers /launchopera=0" `
        -WindowStyle Hidden -Wait

    Remove-TempDirectory
    exit
}

# ---------------- CHROME ----------------
if ($Chrome) {
    Write-Output "Downloading Google Chrome..."

    if ($osArch -eq "ARM64") {
        $chromeUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise_Arm64.msi"
    } elseif ($osArch -eq "X64") {
        $chromeUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    } else {
        $chromeUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise.msi"
    }

    & curl.exe -LSs $chromeUrl -o "$tempDir\chrome.msi" $timeouts

    if (!$?) {
        Write-Error "Chrome download failed."
        exit 1
    }

    Write-Output "Installing Google Chrome..."
    Start-Process -FilePath "$tempDir\chrome.msi" `
        -WindowStyle Hidden -ArgumentList "/qn /norestart" -Wait

    Remove-TempDirectory
    exit
}

# ---------------- VC++ RUNTIMES ----------------
$modernArgs = "/install /quiet /norestart"
$vcredists = [ordered] @{}

if ($osArch -eq "ARM64") {
    $vcredists["https://aka.ms/vs/17/release/vc_redist.arm64.exe"] = @("2015+-arm64", $modernArgs)
}
if ($osArch -eq "X64" -or $osArch -eq "ARM64") {
    $vcredists["https://aka.ms/vs/17/release/vc_redist.x64.exe"] = @("2015+-x64", $modernArgs)
}
$vcredists["https://aka.ms/vs/17/release/vc_redist.x86.exe"] = @("2015+-x86", $modernArgs)

foreach ($a in $vcredists.GetEnumerator()) {
    $vcName = $a.Value[0]
    $vcArgs = $a.Value[1]
    $vcUrl  = $a.Key
    $vcExePath = "$tempDir\vcredist-$vcName.exe"

    Write-Output "Installing VC++ Runtime $vcName..."

    & curl.exe -LSs $vcUrl -o $vcExePath $timeouts

    Start-Process -FilePath $vcExePath -ArgumentList $vcArgs -WindowStyle Hidden -Wait
}

# ---------------- DIRECTX ----------------
Write-Output "Installing DirectX..."

& curl.exe -LSs "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" `
    -o "$tempDir\directx.exe" $timeouts

Start-Process -FilePath "$tempDir\directx.exe" `
    -WindowStyle Hidden -ArgumentList "/q /c /t:`"$tempDir\dx`"" -Wait

Start-Process -FilePath "$tempDir\dx\dxsetup.exe" `
    -WindowStyle Hidden -ArgumentList "/silent" -Wait

# ---------------- CLEANUP ----------------
Remove-TempDirectory
