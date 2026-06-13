$path = "HKCU:\Control Panel\Desktop"
$value = [byte[]](144,18,3,128,16,0,0,0)
Set-ItemProperty -LiteralPath $path -Name "UserPreferencesMask" -Value $value -Type Binary -Force