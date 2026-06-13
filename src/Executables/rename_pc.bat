@echo off
:: === Z LAG OS – Full Name Change with Spaces ===
CLS
echo [+] Changing computer name and branding to "Z LAG OS"...

set "NEWNAME=Z LAG OS"
set "NETNAME=Z LAG OS"

:: 1. PowerShell rename (modern, works with spaces)
powershell -Command "Rename-Computer -NewName '%NETNAME%' -Force" >nul 2>&1

:: 2. Registry – Hostname keys (spaces are OK on modern Windows)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" /v "ComputerName" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" /v "ComputerName" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "Hostname" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "NV Hostname" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v "srvcomment" /t REG_SZ /d "%NEWNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Winlogon" /v "AltDefaultDomainName" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Winlogon" /v "DefaultDomainName" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\Setup" /v "ComputerName" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1
reg add "HKLM\SYSTEM\Setup\Pid" /v "ComputerName" /t REG_SZ /d "%NETNAME%" /f >nul 2>&1

:: 3. Branding (display name with spaces)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOwner" /t REG_SZ /d "%NEWNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "%NEWNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "HelpCustomized" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Manufacturer" /t REG_SZ /d "Z LAG OS" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "SupportProvider" /t REG_SZ /d "Z LAG OS Support" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "SupportAppURL" /t REG_SZ /d "zlagos-support" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "SupportURL" /t REG_SZ /d "https://discord.gg/5qkKPRZkWa" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "YouTubeURL" /t REG_SZ /d "https://www.youtube.com/@Z-LAG_OFFICIAL" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "EditionSubManufacturer" /t REG_SZ /d "Z LAG OS" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "EditionSubstring" /t REG_SZ /d "Z LAG OS" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "EditionSubVersion" /t REG_SZ /d "Zero Lag Edition" /f >nul 2>&1

:: 4. Environment variable
setx COMPUTERNAME "%NETNAME%" /m >nul 2>&1

:: 5. Network refresh
ipconfig /flushdns >nul 2>&1
ipconfig /registerdns >nul 2>&1

echo [+] Computer name and branding fully overwritten. Changes apply after reboot.
timeout /t 3 >nul
exit /b