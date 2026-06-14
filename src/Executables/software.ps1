param (
	[switch]$Chrome,
	[switch]$Brave,
	[switch]$OperaGX
)

# ---------------- SAFE BOOTSTRAP ----------------
$ErrorActionPreference = "SilentlyContinue"

$timeouts = @("--connect-timeout", "10", "--retry", "5", "--retry-delay", "0", "--retry-all-errors")
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"

# Detect ARM
$isARM = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq "Arm64"

# Temp directory (SAFE replacement for Get-SystemDrive)
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
	& curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" `
		-o "$tempDir\BraveSetup.exe" $timeouts

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

	$chromeArch = if ($isARM) { "_Arm64" } else { "" }

	$chromeUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi"

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
$legacyArgs = '/q /norestart'
$modernArgs = "/install /quiet /norestart"

$vcredists = [ordered] @{
	"https://aka.ms/vs/17/release/vc_redist.x64.exe" = @("2015+-x64", $modernArgs)
	"https://aka.ms/vs/17/release/vc_redist.x86.exe" = @("2015+-x86", $modernArgs)
}

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
