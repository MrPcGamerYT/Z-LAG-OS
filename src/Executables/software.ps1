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

# ---------------- BRAVE ----------------
if ($Brave) {
    Write-Output "Downloading Brave..."
    
    # Fall back to 32-bit if it's an old X86 machine, otherwise use X64
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
    # Opera's setup endpoint handles architecture detection automatically on their servers
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

    # Match the exact enterprise MSI URL to the target machine architecture
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

# Smart waterfall injection: 64-bit/ARM environments still require the 32-bit runtimes 
# to support older applications, but 32-bit systems can only install the X86 package.
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
# DirectX installer packs architectures for everything right inside the redist package

& curl.exe -LSs "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" `
    -o "$tempDir\directx.exe" $timeouts

Start-Process -FilePath "$tempDir\directx.exe" `
    -WindowStyle Hidden -ArgumentList "/q /c /t:`"$tempDir\dx`"" -Wait

Start-Process -FilePath "$tempDir\dx\dxsetup.exe" `
    -WindowStyle Hidden -ArgumentList "/silent" -Wait

# ---------------- CLEANUP ----------------
Remove-TempDirectory
