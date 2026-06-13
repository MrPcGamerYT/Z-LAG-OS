@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: 1. Remove the old layout if it exists
if exist "!SystemDrive!\Windows\StartMenuLayout.xml" (
    del /q /f "!SystemDrive!\Windows\StartMenuLayout.xml"
)

:: 2. Create the Default User Profile's Shell folder and copy the layout files
mkdir "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell" 2>nul
copy /y "LayoutModification.xml" "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml"
copy /y "LayoutModification.json" "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.json"
copy /y "DefaultLayouts.xml" "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml"

:: 3. Prepare the Default User Profile's App Installer settings
mkdir "%SYSTEMDRIVE%\Users\Default\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState" 2>nul
copy /y "settings.json" "%SYSTEMDRIVE%\Users\Default\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"

:: 4. Iterate through each existing user on the system
for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul 2>&1
    if not !errorlevel! == 1 (
        for /f "usebackq tokens=3* delims= " %%b in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Local AppData" 2^>nul ^| findstr /r /x /c:".*Local AppData[ ]*REG_SZ[ ].*"`) do (
            :: 4a. Copy layout files to the user's profile
            copy /y "LayoutModification.xml" "%%c\Microsoft\Windows\Shell\LayoutModification.xml"
            copy /y "LayoutModification.json" "%%c\Microsoft\Windows\Shell\LayoutModification.json"
            copy /y "DefaultLayouts.xml" "%%c\Microsoft\Windows\Shell\DefaultLayouts.xml"

            :: 4b. Clear start menu pinned items for the user
            for /f "usebackq delims=" %%d in (`dir /b "%%c\Packages" /a:d ^| findstr /c:"Microsoft.Windows.StartMenuExperienceHost"`) do (
                for /f "usebackq delims=" %%e in (`dir /b "%%c\Packages\%%d\LocalState" /a:-d ^| findstr /R /c:"start.\.bin" /c:"start\.bin"`) do (
                    del /q /f "%%c\Packages\%%d\LocalState\%%e"
                )
            )

            :: 4c. Prepare App Installer settings for the user
            for /f "usebackq delims=" %%d in (`dir /b "%%c\Packages" /a:d ^| findstr /c:"Microsoft.DesktopAppInstaller"`) do (
                mkdir "%%c\Packages\%%d\LocalState" 2>nul
                copy /y "settings.json" "%%c\Packages\%%d\LocalState\settings.json"
            )
        )

        :: 4d. Clear the start menu tile layout from the registry
        for /f "usebackq delims=" %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" ^| findstr /c:"start.tilegrid"`) do (
            reg delete "%%c" /f
        )

        :: 4e. Clear the Start Menu config for 23H2+
        reg delete "HKU\%%a\Software\Microsoft\Windows\CurrentVersion\Start" /v "Config" /f
    )
)

exit /b