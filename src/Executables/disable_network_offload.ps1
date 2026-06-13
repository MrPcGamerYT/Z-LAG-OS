Get-NetAdapter | ForEach-Object {
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "TCP Checksum Offloading" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
}