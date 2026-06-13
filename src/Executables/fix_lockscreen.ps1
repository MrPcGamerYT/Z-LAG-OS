# ============================================================
# LOCK SCREEN FIX – Force custom image (no more blue screen)
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FORCING CUSTOM LOCK SCREEN IMAGE (FIX BLUE SCREEN)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$lockImage = "C:\Windows\Web\Screen\Z-LAG_Lock.png"

# Verify image exists
if (-not (Test-Path $lockImage)) {
    Write-Error "Lock screen image not found: $lockImage"
    exit 1
}

# ------------------------------------------------------------------
# METHOD 1: Disable Windows Spotlight and force custom lock screen
# ------------------------------------------------------------------
Write-Host "[1] Disabling Windows Spotlight..." -ForegroundColor Yellow

# Disable Spotlight for current user
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force

# Disable Spotlight for all users (HKLM)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSpotlightCollectionOnDesktop" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableThirdPartySuggestions" -Value 1 -Type DWord -Force

Write-Host "  -> Windows Spotlight disabled" -ForegroundColor Green

# ------------------------------------------------------------------
# METHOD 2: Force lock screen image via multiple registry locations
# ------------------------------------------------------------------
Write-Host "[2] Forcing lock screen image in registry..." -ForegroundColor Yellow

# HKLM Policies (system-wide, highest priority)
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $policyPath)) { New-Item -Path $policyPath -Force | Out-Null }
Set-ItemProperty -Path $policyPath -Name "LockScreenImage" -Value $lockImage -Type String -Force
Set-ItemProperty -Path $policyPath -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force

# OOBE Registry
$oobePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
if (-not (Test-Path $oobePath)) { New-Item -Path $oobePath -Force | Out-Null }
Set-ItemProperty -Path $oobePath -Name "LockScreenImage" -Value $lockImage -Type String -Force

# Current user lock screen settings
$userLockPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
if (-not (Test-Path $userLockPath)) { New-Item -Path $userLockPath -Force | Out-Null }
Set-ItemProperty -Path $userLockPath -Name "LockScreenImagePath" -Value $lockImage -Type String -Force
Set-ItemProperty -Path $userLockPath -Name "LockScreenImage" -Value $lockImage -Type String -Force

# Personalization settings
$personalizePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-Path $personalizePath)) { New-Item -Path $personalizePath -Force | Out-Null }
Set-ItemProperty -Path $personalizePath -Name "LockScreenImage" -Value $lockImage -Type String -Force

Write-Host "  -> Lock screen registry entries applied" -ForegroundColor Green

# ------------------------------------------------------------------
# METHOD 3: Remove Windows Spotlight scheduled tasks
# ------------------------------------------------------------------
Write-Host "[3] Disabling Spotlight scheduled tasks..." -ForegroundColor Yellow
Disable-ScheduledTask -TaskName "Microsoft-Windows-CloudExperienceHost" -TaskPath "\Microsoft\Windows\CloudExperienceHost" -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "Spotlight" -TaskPath "\Microsoft\Windows\Spotlight" -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "SpotlightCollector" -TaskPath "\Microsoft\Windows\Spotlight" -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "SpotlightToast" -TaskPath "\Microsoft\Windows\Spotlight" -ErrorAction SilentlyContinue
Write-Host "  -> Spotlight tasks disabled" -ForegroundColor Green

# ------------------------------------------------------------------
# METHOD 4: Apply to all existing users via their registry hives
# ------------------------------------------------------------------
Write-Host "[4] Applying lock screen to ALL user profiles..." -ForegroundColor Yellow

Get-ChildItem "Registry::HKEY_USERS" | ForEach-Object {
    $sid = $_.PSChildName
    if ($sid -notmatch '_Classes|^\.DEFAULT$') {
        $userLockKey = "Registry::HKEY_USERS\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen"
        $userPersonalizeKey = "Registry::HKEY_USERS\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        
        if (-not (Test-Path $userLockKey)) { New-Item -Path $userLockKey -Force | Out-Null }
        if (-not (Test-Path $userPersonalizeKey)) { New-Item -Path $userPersonalizeKey -Force | Out-Null }
        
        Set-ItemProperty -Path $userLockKey -Name "LockScreenImagePath" -Value $lockImage -Force
        Set-ItemProperty -Path $userLockKey -Name "LockScreenImage" -Value $lockImage -Force
        Set-ItemProperty -Path $userPersonalizeKey -Name "LockScreenImage" -Value $lockImage -Force
        
        Write-Host "  Applied to SID: $sid" -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------
# METHOD 5: Force lock screen via Group Policy local GPO
# ------------------------------------------------------------------
Write-Host "[5] Applying via Group Policy..." -ForegroundColor Yellow

# Write to local GPO
$gpoRegistry = "$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol"
& reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "LockScreenImage" /t REG_SZ /d "$lockImage" /f 2>&1 | Out-Null

# Force GPUpdate
& gpupdate /force 2>&1 | Out-Null
Write-Host "  -> Group Policy updated" -ForegroundColor Green

# ------------------------------------------------------------------
# METHOD 6: Create a startup script to reapply (ensures persistence)
# ------------------------------------------------------------------
Write-Host "[6] Creating startup script for persistence..." -ForegroundColor Yellow

$startupScript = @'
# Lock screen re-apply script (runs at boot)
$lockImage = "C:\Windows\Web\Screen\Z-LAG_Lock.png"
$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (Test-Path $policyPath) {
    Set-ItemProperty -Path $policyPath -Name "LockScreenImage" -Value $lockImage -Type String -Force
}
'@

$startupScriptPath = "$env:SystemRoot\System32\LockScreenFix.ps1"
$startupScript | Out-File -FilePath $startupScriptPath -Encoding UTF8 -Force

# Create scheduled task to run at startup
$taskName = "Z-LAG-LockScreenFix"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$startupScriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force -ErrorAction SilentlyContinue

Write-Host "  -> Startup task created: $taskName" -ForegroundColor Green

# ------------------------------------------------------------------
# METHOD 7: Force Windows to refresh lock screen settings
# ------------------------------------------------------------------
Write-Host "[7] Refreshing Windows settings..." -ForegroundColor Yellow

# Kill and restart LockScreen process
Stop-Process -Name "LockApp" -Force -ErrorAction SilentlyContinue

# Restart Explorer
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ LOCK SCREEN FIX APPLIED!" -ForegroundColor Green
Write-Host "   Reboot your PC to see the change." -ForegroundColor Yellow
Write-Host "   If still blue, run this script again after reboot." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green