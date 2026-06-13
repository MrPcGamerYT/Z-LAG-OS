

# ----- 1. Create and activate Ultimate Performance power plan -----
Write-Host "Creating Ultimate Performance power plan..."
$duplicateOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
if ($duplicateOutput -match "Power Scheme GUID:\s*([a-f0-9\-]+)") {
    $newGuid = $matches[1]
    powercfg -setactive $newGuid
    powercfg -changename $newGuid "Maximum FPS" "Optimized for zero-lag gaming"
    Write-Host "Activated and renamed power scheme: $newGuid"
} else {
    Write-Host "Failed to duplicate Ultimate Performance scheme. Falling back to existing 'Ultimate Performance'."
    # Try to find existing Ultimate Performance GUID
    $existing = powercfg -list | Select-String "Ultimate Performance"
    if ($existing -match "([a-f0-9\-]+)") {
        powercfg -setactive $matches[1]
        Write-Host "Activated existing Ultimate Performance scheme."
    }
}

# ----- 2. Fine-tune active power scheme -----
Write-Host "Applying power scheme fine-tuning..."
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg -setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0
powercfg -setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0
powercfg -setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
powercfg -hibernate off

# ----- 3. BCDEdit tweaks (ignore errors if values missing) -----
Write-Host "Applying BCDEdit timing tweaks..."
bcdedit /deletevalue useplatformclock 2>$null
bcdedit /set tscsyncpolicy Enhanced
bcdedit /set disabledynamictick yes

Write-Host "Power plan and timing optimizations complete."
