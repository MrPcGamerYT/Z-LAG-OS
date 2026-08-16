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


# ---------------- BRAVE ----------------
if ($Brave) {
    Write-Output "Downloading Brave..."
    
    $braveArch = if ($osArch -eq "X86") { "winia32" } else { "winx64" }
    $braveUrl = "https://laptop-updates.brave.com/latest/$braveArch"

    & curl.exe -LSs $braveUrl -o "$tempDir\BraveSetup.exe" $timeouts

    if ($LASTEXITCODE -eq 0 -and (Test-Path "$tempDir\BraveSetup.exe")) {
        Write-Output "Installing Brave..."
        Start-Process -FilePath "$tempDir\BraveSetup.exe" `
            -WindowStyle Hidden -ArgumentList "/silent /install" -Wait
    } else {
        Write-Warning "Brave download failed. Continuing..."
    }
}

# ---------------- OPERA GX ----------------
if ($OperaGX) {
    Write-Output "Downloading Opera GX (latest)..."
    & curl.exe -LSs "https://net.geo.opera.com/opera_gx/stable/windows" `
        -o "$tempDir\operagx.exe" $timeouts

    if ($LASTEXITCODE -eq 0 -and (Test-Path "$tempDir\operagx.exe")) {
        Write-Output "Installing Opera GX..."
        Start-Process -FilePath "$tempDir\operagx.exe" `
            -ArgumentList "/silent /allusers /launchopera=0" `
            -WindowStyle Hidden -Wait
    } else {
        Write-Warning "Opera GX download failed. Continuing..."
    }
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

    if ($LASTEXITCODE -eq 0 -and (Test-Path "$tempDir\chrome.msi")) {
        Write-Output "Installing Google Chrome..."
        Start-Process -FilePath "$tempDir\chrome.msi" `
            -WindowStyle Hidden -ArgumentList "/qn /norestart" -Wait
    } else {
        Write-Warning "Chrome download failed. Continuing..."
    }
}

# ---------------- CLEANUP ----------------
Remove-TempDirectory
