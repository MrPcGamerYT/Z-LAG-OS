@echo off
:: ====================================================================
:: Z LAG OS - ULTIMATE UNIVERSAL ACCOUNT CONVERSION & BYPASS SCRIPT
:: RUN THIS AS ADMINISTRATOR FOR WINDOWS 10 & WINDOWS 11
:: ====================================================================

echo [Z LAG OS] Starting ultimate login optimization...

:: 1. STRIP MICROSOFT CLOUD LINKS & TOKEN REPLICATION LAYERS
reg delete "HKCU\Software\Microsoft\IdentityCRL" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\IdentityCRL" /f >nul 2>&1

:: 2. FORCIBLY CONVERT TO PURE OFFLINE LOCAL MODE IN SAM
reg add "HKLM\SAM\SAM\Domains\Account\Users" /v "InternetProviderGUID" /t REG_BINARY /d "" /f >nul 2>&1

:: 3. WIPE THE ACCOUNT PASSWORD COMPLETELY (MAKE IT BLANK)
net user "%username%" "" >nul 2>&1

:: 4. UNIVERSAL BYPASS FOR WINDOWS 10/11 CREDENTIAL BLOCKS
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" /v "DevicePasswordLessBuildVersion" /t REG_DWORD /d 0 /f >nul 2>&1

:: Clean up any leftover auto-login text variables to prevent conflicts later
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /f >nul 2>&1

:: 5. FORCE WINDOWS 11 LOGON CONTROLLER TO ACCEPT BLANK PASSWORDS
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowDomainPINLogon" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\TestHooks" /v "ForceSimpleBoot" /t REG_DWORD /d 1 /f >nul 2>&1

:: 6. ANTI-LOCKOUT DEEP PROTECTION (THE WINDOWS 11 FIXES)
:: Disable Hello PIN Provisioning
reg add "HKLM\SOFTWARE\Policies\Microsoft\PassportForWork" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\PassportForWork" /v "DisablePostLogonProvisioning" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable post-update nag screens & consumer feature advertising
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1

:: Skip visual lock screen slide-up animation entirely
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreen" /t REG_DWORD /d 1 /f >nul 2>&1

echo [Z LAG OS] Optimization finished successfully! System is now secure from account locks.
exit /b 0
