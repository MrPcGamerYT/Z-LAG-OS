# ==============================================================================
# Z-LAG OS - WebView2 Runtime Guarantee / Repair (never leave apps broken)
# ------------------------------------------------------------------------------
# Verifies the WebView2 Runtime is present after Edge removal. If it is missing,
# installs the official Evergreen WebView2 Runtime silently so apps that depend
# on it (Discord, Teams v2, Office, etc.) never throw "WebView2 runtime missing".
#
# Idempotent: safe to run repeatedly - only installs when the runtime is absent.
# Logs to C:\ProgramData\Z-LAG-OS\repair_webview2.log
# ==============================================================================

$ErrorActionPreference = "Continue"

# --- 0. Persistent logging + elevation guard ---
$logDir = Join-Path $env:ProgramData "Z-LAG-OS"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "repair_webview2.log"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output "[Z-LAG-WV2] ERROR: Administrator privileges required. Run from an elevated session."
    exit 1
}

function Log([string]$m) {
    $line = "[Z-LAG-WV2] $m"
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding ASCII -ErrorAction SilentlyContinue
}

function Test-WebView2Present {
    # 1. Win32 evergreen runtime (most common)
    foreach ($base in @("$env:ProgramFiles(x86)\Microsoft\EdgeWebView\Application",
                        "$env:ProgramFiles\Microsoft\EdgeWebView\Application")) {
        if (Test-Path $base) {
            $hits = Get-ChildItem -Path $base -Filter "msedgewebview2.exe" -Recurse -ErrorAction SilentlyContinue
            if ($hits) { return $true }
        }
    }
    # 2. AppX host shim / any WebView2 package
    if (Get-AppxPackage -AllUsers -Name "*WebView*" -ErrorAction SilentlyContinue) { return $true }
    if (Get-AppxPackage -AllUsers -Name "*Win32WebViewHost*" -ErrorAction SilentlyContinue) { return $true }
    return $false
}

# Copy ourselves next to the Z-LAG-OS data dir for manual re-runs.
try {
    Copy-Item -Path $PSCommandPath -Destination (Join-Path $logDir "repair_webview2.ps1") -Force -ErrorAction SilentlyContinue
} catch {}

$zk = "HKLM:\SOFTWARE\Z-LAG-OS"
if (-not (Test-Path $zk)) { New-Item -Path $zk -Force | Out-Null }

if (Test-WebView2Present) {
    Log "WebView2 Runtime is present - nothing to do."
    Set-ItemProperty -Path $zk -Name "WebView2Status" -Value "OK" -Type String -Force
    exit 0
}

Log "WebView2 Runtime missing - installing the official Evergreen runtime..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$setup = Join-Path $env:TEMP "MicrosoftEdgeWebView2Setup.exe"
$url = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
$ok = $false

# Prefer system curl.exe (present on Win10/11)
$curlExe = "$env:SystemRoot\System32\curl.exe"
if (Test-Path $curlExe) {
    for ($i = 1; $i -le 3; $i++) {
        Log "Download attempt $i/3 (curl)..."
        & $curlExe -LSs --connect-timeout 30 --retry 3 --retry-delay 3 -o $setup $url 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $setup) -and (Get-Item $setup).Length -gt 1MB) { $ok = $true; break }
        Start-Sleep -Seconds 3
    }
}
if (-not $ok) {
    Log "curl failed/missing - falling back to Invoke-WebRequest..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $setup -UseBasicParsing -TimeoutSec 90 -ErrorAction Stop
        if ((Test-Path $setup) -and (Get-Item $setup).Length -gt 1MB) { $ok = $true }
    } catch {
        Log "Download failed: $($_.Exception.Message)"
    }
}

if (-not $ok) {
    Log "ERROR: could not download the WebView2 bootstrapper."
    Set-ItemProperty -Path $zk -Name "WebView2Status" -Value "MISSING" -Type String -Force
    Log "Manual install: https://developer.microsoft.com/en-us/microsoft-edge/webview2/"
    exit 1
}

Log "Installing WebView2 Runtime (silent, system-level)..."
try {
    Add-MpPreference -ExclusionPath $setup -ErrorAction SilentlyContinue
} catch {}
$proc = Start-Process -FilePath $setup -ArgumentList "/silent","/install" -Wait -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

if (Test-WebView2Present) {
    Log "WebView2 Runtime installed successfully."
    Set-ItemProperty -Path $zk -Name "WebView2Status" -Value "OK" -Type String -Force
    Set-ItemProperty -Path $zk -Name "WebView2RepairDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String -Force
} else {
    Log "WARNING: installer finished but the runtime was not detected yet (a reboot may be needed)."
    Set-ItemProperty -Path $zk -Name "WebView2Status" -Value "PENDING" -Type String -Force
}

Remove-Item $setup -Force -ErrorAction SilentlyContinue
Log "WebView2 repair pass complete."
