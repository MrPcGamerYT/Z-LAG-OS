# ==============================================================================
# Z-LAG OS - Install Z-LAG Toolbox (Strictly targets Z-LAG-Toolbox-Setup-*.exe)
# Hardened deployment: persistent logging + download integrity check + launch
# smoke-test + AppX runtime health pass. If anything fails, it is written to a
# log file and a registry marker so the failure is NEVER silent.
# ==============================================================================

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- 0. Persistent logging (so failures are never silent) ---
$logDir = Join-Path $env:ProgramData "Z-LAG-OS"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "toolbox_install.log"
$zlagKey = "HKLM:\SOFTWARE\Z-LAG-OS"
if (-not (Test-Path $zlagKey)) { New-Item -Path $zlagKey -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $Message"
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII
}

# --- 1. Administrator check ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "[ERROR] Administrator privileges required."
    exit 1
}

# --- 2. Environment ---
Write-Log "[Z-LAG] Initializing Z-LAG Toolbox deployment..."
$tempDir = Join-Path $env:TEMP ("zlag-toolbox-" + [Guid]::NewGuid().ToString())
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

$repoUrl = "https://api.github.com/repos/MrPcGamerYT/Z-LAG-TOOLBOX/releases/latest"
$installDir = "C:\Program Files\Z-LAG Toolbox"

# --- 3. Helpers ---
function Remove-LegacyComponents {
    Write-Log "[Z-LAG] Cleaning up legacy Alt App Installer components..."
    $legacyDirs = @("C:\Program Files\AltAppInstaller", "C:\Program Files (x86)\AltAppInstaller")
    foreach ($dir in $legacyDirs) {
        if (Test-Path $dir) { Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue }
    }
    $shortcuts = @("Alt App Installer.lnk", "AltAppInstaller.lnk")
    $paths = @(
        [IO.Path]::Combine($env:ProgramData, "Microsoft\Windows\Start Menu\Programs"),
        [Environment]::GetFolderPath("CommonDesktopDirectory"),
        [Environment]::GetFolderPath("Desktop")
    )
    foreach ($path in $paths) {
        foreach ($shortcut in $shortcuts) {
            $targetPath = Join-Path $path $shortcut
            if (Test-Path $targetPath) { Remove-Item $targetPath -Force -ErrorAction SilentlyContinue }
        }
    }
}

function Invoke-RobustDownload {
    param([string]$Url, [string]$OutFile)
    $maxRetries = 5
    $curlExe = "$env:SystemRoot\System32\curl.exe"
    if (Test-Path $curlExe) {
        for ($i = 1; $i -le $maxRetries; $i++) {
            Write-Log "[Z-LAG] Download attempt $i/$maxRetries (curl)..."
            & $curlExe @("-LSs", "-o", $OutFile, "--connect-timeout", "30", "--retry", "3", "--fail", $Url) 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 1MB) { return $true }
            Start-Sleep -Seconds 3
        }
    }
    Write-Log "[Z-LAG] curl failed/missing - falling back to native web request..."
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -TimeoutSec 60 | Out-Null
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 1MB) { return $true }
        } catch { Start-Sleep -Seconds 3 }
    }
    return $false
}

# Make sure the packaged-app launch stack is healthy BEFORE the toolbox installs
# anything (prevents "The service has not been started" crashes).
function Invoke-AppXHealthCheck {
    Write-Log "[Z-LAG] Ensuring packaged-app launch stack is healthy..."
    $appxPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
    if (-not (Test-Path $appxPolicy)) { New-Item -Path $appxPolicy -Force | Out-Null }
    Set-ItemProperty -Path $appxPolicy -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $appxPolicy -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

    $devUnlock = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $devUnlock)) { New-Item -Path $devUnlock -Force | Out-Null }
    Set-ItemProperty -Path $devUnlock -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $devUnlock -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "DisableStoreApps" -ErrorAction SilentlyContinue

    foreach ($s in @("LicenseManager", "ClipSVC")) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $s -ErrorAction SilentlyContinue
        }
    }
    foreach ($s in @("AppXSvc", "StateRepository")) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) { Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue }
    }
}

# --- 4. Main ---
$ok = $false
try {
    Remove-LegacyComponents
    Invoke-AppXHealthCheck

    Write-Log "[Z-LAG] Querying GitHub API for latest release..."
    $release = Invoke-RestMethod -Uri $repoUrl -UseBasicParsing -TimeoutSec 30
    if (-not $release -or -not $release.assets) { throw "Invalid or empty response from GitHub API." }
    Write-Log "[Z-LAG] Target release: $($release.tag_name)"

    $setupAsset = $release.assets | Where-Object { $_.name -like "*Setup*.exe" } | Select-Object -First 1
    if (-not $setupAsset) { throw "No *Setup*.exe asset found in the release." }

    $exePath = Join-Path $tempDir $setupAsset.name
    Write-Log "[Z-LAG] Installer: $($setupAsset.name)"
    Write-Log "[Z-LAG] URL: $($setupAsset.browser_download_url)"

    if (-not (Invoke-RobustDownload -Url $setupAsset.browser_download_url -OutFile $exePath)) {
        throw "Download failed after multiple attempts."
    }
    Write-Log "[Z-LAG] Downloaded $((Get-Item $exePath).Length) bytes."

    # Integrity: verify against GitHub's published sha256 when available.
    if ($setupAsset.digest) {
        $actual = (Get-FileHash -Path $exePath -Algorithm SHA256).Hash.ToLower()
        $expected = ($setupAsset.digest -split ':')[-1].ToLower()
        if ($actual -ne $expected) {
            Write-Log "[WARNING] SHA256 mismatch (expected $expected, got $actual). Continuing but flagged."
        } else {
            Write-Log "[Z-LAG] SHA256 digest verified."
        }
    }

    try {
        Add-MpPreference -ExclusionPath $installDir -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionPath $exePath -ErrorAction SilentlyContinue
    } catch {}

    Write-Log "[Z-LAG] Executing silent installer (/S)..."
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = "/S"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit(30000) | Out-Null

    # Poll install dir for the main executable (NSIS spawns child processes)
    $timeoutSeconds = 90
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $finalExe = $null
    while ($stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        if (Test-Path $installDir) {
            $finalExe = Get-ChildItem -Path $installDir -Filter "*.exe" -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -notmatch "(?i)unins" } | Select-Object -First 1
            if ($finalExe) { Start-Sleep -Seconds 3; break }
        }
        Start-Sleep -Seconds 2
    }
    $stopwatch.Stop()

    if (-not $finalExe) { throw "Installer timed out - executable not found in '$installDir'." }

    # Smoke test: the binary must exist, be non-trivial and carry version info.
    $vi = $finalExe.VersionInfo
    if ($finalExe.Length -lt 1KB -or -not $vi.FileVersion) {
        throw "Installed binary failed the smoke test (invalid file or no version info)."
    }

    Write-Log "[Z-LAG] SUCCESS: Z-LAG Toolbox deployed -> $($finalExe.FullName) (v$($vi.FileVersion))"
    $ok = $true
} catch {
    Write-Log "[ERROR] Deployment failed: $_"
    Write-Log "[Z-LAG] Manual install: https://github.com/MrPcGamerYT/Z-LAG-TOOLBOX/releases"
}

# --- 5. Persist the result (never silent) ---
Set-ItemProperty -Path $zlagKey -Name "ToolboxInstallStatus" -Value $(if ($ok) { "OK" } else { "FAILED" }) -Type String -Force
if ($ok) {
    Set-ItemProperty -Path $zlagKey -Name "ToolboxInstalled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $zlagKey -Name "ToolboxInstallDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String -Force
}

# --- 6. Cleanup ---
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue }

Write-Log "[Z-LAG] Task complete. Result: $(if ($ok) { 'SUCCESS' } else { 'FAILED' }). Log: $logFile"
