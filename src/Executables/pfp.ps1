# Z-LAG OS - set default user account picture (robust path handling)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.Drawing

$source = Get-ChildItem -Path $PSScriptRoot -Filter "user.png" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $source) {
    $source = Get-ChildItem -Path $PSScriptRoot -Filter "user.*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '(?i)^\.(png|bmp|jpg|jpeg)$' } | Select-Object -First 1
}
if (-not $source) {
    Write-Host "[Z-LAG-PFP] No user picture source found - skipping."
    exit 0
}

$img = [System.Drawing.Image]::FromFile($source.FullName)

$resolutions = @{
    "user.png"    = 448
    "user.bmp"    = 448
    "guest.png"   = 448
    "guest.bmp"   = 448
    "user-192.png" = 192
    "user-48.png" = 48
    "user-40.png" = 40
    "user-32.png" = 32
}

$destDir = [Environment]::GetFolderPath('CommonApplicationData') + "\Microsoft\User Account Pictures"
if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }

foreach ($image in $resolutions.Keys) {
    $resolution = $resolutions[$image]
    try {
        $a = New-Object System.Drawing.Bitmap($resolution, $resolution)
        $graph = [System.Drawing.Graphics]::FromImage($a)
        $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graph.DrawImage($img, 0, 0, $resolution, $resolution)
        $a.Save((Join-Path $destDir $image))
        $graph.Dispose()
        $a.Dispose()
    } catch {
        Write-Host ("[Z-LAG-PFP] Could not write " + $image)
    }
}
$img.Dispose()
