# Remove pinned groups and tiles from Start menu (Windows 10 & 11)

# 1. Clear Windows 10/11 Start menu database
$regPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultCache",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage2",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TileStore"
)
foreach ($path in $regPaths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Import empty layout XML (works on both, but especially for Windows 10)
$xml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6" />
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
$tempFile = "$env:TEMP\EmptyLayout.xml"
$xml | Out-File -FilePath $tempFile -Encoding utf8 -Force
Import-StartLayout -LayoutPath $tempFile -MountPath $env:SystemDrive -ErrorAction SilentlyContinue

# 3. Windows 11 specific: Remove the "Recommended" section and disable recommendations
if ((Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "CurrentBuildNumber" -ErrorAction SilentlyContinue) -ge 22000) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 0 -Type DWord -Force
}

Write-Host "Start menu cleared. Restart Explorer to see changes."