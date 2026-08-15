$path = "HKCU:\Control Panel\Mouse"
$nullBytes = [byte[]]@(0)*24
Set-ItemProperty -LiteralPath $path -Name "SmoothMouseXCurve" -Value $nullBytes -Type Binary -Force
Set-ItemProperty -LiteralPath $path -Name "SmoothMouseYCurve" -Value $nullBytes -Type Binary -Force