# ============================================================
# ElegantDark Cursor Installer – Permanent for all users
# ============================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceFolder = Join-Path $ScriptDir "ElegantDark"
$DestinationFolder = "$env:SystemRoot\Cursors\ElegantDark"

# 1. Copy cursor files
if (Test-Path $SourceFolder) {
    Write-Host "Found ElegantDark folder. Copying to C:\Windows\Cursors..." -ForegroundColor Green
    Copy-Item -Path $SourceFolder -Destination $DestinationFolder -Recurse -Force
} else {
    Write-Error "Could not find the 'ElegantDark' folder next to this script!"
    exit 1
}

# 2. Build the scheme string (same as before)
$cursorPaths = @{
    "Arrow"         = "$DestinationFolder\pointer.cur"
    "Help"          = "$DestinationFolder\help.cur"
    "AppStarting"   = "$DestinationFolder\work.ani"
    "Wait"          = "$DestinationFolder\busy.ani"
    "Crosshair"     = "$DestinationFolder\cross.cur"
    "IBeam"         = "$DestinationFolder\text.cur"
    "NWPen"         = "$DestinationFolder\handwriting.cur"
    "No"            = "$DestinationFolder\unavailable.cur"
    "SizeNS"        = "$DestinationFolder\vert.cur"
    "SizeWE"        = "$DestinationFolder\horz.cur"
    "SizeNWSE"      = "$DestinationFolder\dgn1.cur"
    "SizeNESW"      = "$DestinationFolder\dgn2.cur"
    "SizeAll"       = "$DestinationFolder\move.cur"
    "UpArrow"       = "$DestinationFolder\alternate.cur"
    "Hand"          = "$DestinationFolder\link.cur"
}
$schemeString = ($cursorPaths.Arrow, $cursorPaths.Help, $cursorPaths.AppStarting, $cursorPaths.Wait, $cursorPaths.Crosshair, $cursorPaths.IBeam, $cursorPaths.NWPen, $cursorPaths.No, $cursorPaths.SizeNS, $cursorPaths.SizeWE, $cursorPaths.SizeNWSE, $cursorPaths.SizeNESW, $cursorPaths.SizeAll, $cursorPaths.UpArrow, $cursorPaths.Hand) -join ","

# 3. Apply to ALL user hives (including existing and default)
$userHives = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.PSChildName -notmatch '_Classes|^\.DEFAULT$' }
$userHives | ForEach-Object {
    $sid = $_.PSChildName
    Write-Host "Applying cursor scheme to SID: $sid" -ForegroundColor Yellow
    $cursorsKey = "Registry::HKEY_USERS\$sid\Control Panel\Cursors"
    $schemesKey = "Registry::HKEY_USERS\$sid\Control Panel\Cursors\Schemes"
    if (-not (Test-Path $cursorsKey)) { New-Item -Path $cursorsKey -Force | Out-Null }
    if (-not (Test-Path $schemesKey)) { New-Item -Path $schemesKey -Force | Out-Null }

    # Set each cursor type
    foreach ($name in $cursorPaths.Keys) {
        Set-ItemProperty -Path $cursorsKey -Name $name -Value $cursorPaths[$name] -Force
    }
    # Set the scheme name
    Set-ItemProperty -Path $cursorsKey -Name "(Default)" -Value "Dark" -Force
    # Register the scheme
    Set-ItemProperty -Path $schemesKey -Name "Dark" -Value $schemeString -Force
}

# 4. Apply to the default user profile (for new users)
$defaultHive = "C:\Users\Default\NTUSER.DAT"
if (Test-Path $defaultHive) {
    Write-Host "Mounting Default user hive to bake cursor settings..." -ForegroundColor Cyan
    & reg.exe load HKU\DefUserTemp $defaultHive 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $cursorsKey = "Registry::HKEY_USERS\DefUserTemp\Control Panel\Cursors"
        $schemesKey = "Registry::HKEY_USERS\DefUserTemp\Control Panel\Cursors\Schemes"
        if (-not (Test-Path $cursorsKey)) { New-Item -Path $cursorsKey -Force | Out-Null }
        if (-not (Test-Path $schemesKey)) { New-Item -Path $schemesKey -Force | Out-Null }
        foreach ($name in $cursorPaths.Keys) {
            Set-ItemProperty -Path $cursorsKey -Name $name -Value $cursorPaths[$name] -Force
        }
        Set-ItemProperty -Path $cursorsKey -Name "(Default)" -Value "Dark" -Force
        Set-ItemProperty -Path $schemesKey -Name "Dark" -Value $schemeString -Force
        # Unmount safely
        [GC]::Collect(); [GC]::WaitForPendingFinalizers()
        Start-Sleep -Milliseconds 500
        & reg.exe unload HKU\DefUserTemp 2>&1 | Out-Null
        Write-Host "Default profile updated." -ForegroundColor Green
    } else {
        Write-Warning "Could not load default hive. New users may not inherit cursor."
    }
}

# 5. Also set current user's cursor (if not already covered)
$currentCursors = "HKCU:\Control Panel\Cursors"
$currentSchemes = "HKCU:\Control Panel\Cursors\Schemes"
if (-not (Test-Path $currentSchemes)) { New-Item -Path $currentSchemes -Force | Out-Null }
foreach ($name in $cursorPaths.Keys) {
    Set-ItemProperty -Path $currentCursors -Name $name -Value $cursorPaths[$name] -Force
}
Set-ItemProperty -Path $currentCursors -Name "(Default)" -Value "Dark" -Force
Set-ItemProperty -Path $currentSchemes -Name "Dark" -Value $schemeString -Force

# 6. Prevent themes from changing mouse pointers (system-wide policy)
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
Set-ItemProperty -Path $policyPath -Name "NoChangingMousePointers" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $policyPath -Name "PreventChangingTheme" -Value 1 -Type DWord -Force

# 7. Force immediate cursor reload
$User32 = Add-Type -MemberDefinition @"
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
"@ -Name "User32" -Namespace "Win32" -PassThru
$User32::SystemParametersInfo(0x0057, 0, $null, 3) | Out-Null

# 8. Restart Explorer to apply to all windows
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "✅ ElegantDark cursor applied permanently to all users and locked against theme changes." -ForegroundColor Cyan