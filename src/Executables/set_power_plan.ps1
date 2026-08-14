# ==============================================================================
# Z-LAG OS - Ultimate Performance power plan + timing tweaks (Win10 + Win11)
# Universal: uses the real Ultimate Performance GUID, falls back to High
# Performance on editions where Ultimate is not available, and applies both AC
# and DC settings so laptops and desktops behave identically.
# ==============================================================================

$ErrorActionPreference = "Continue"

$UltimateProfileGuid = "e9a42b02-d5df-448d-aa00-03f14749eb61"   # Ultimate Performance
$HighPerfGuid        = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"   # High Performance

# ----- 1. Create + activate the performance scheme (universal fallback) -----
Write-Host "[Z-LAG] Creating/activating performance power plan..."
$created = $false
powercfg -duplicatescheme $UltimateProfileGuid 2>$null | Out-Null

$schemes = powercfg -list 2>$null
if ($schemes -match $UltimateProfileGuid) {
    powercfg -setactive $UltimateProfileGuid
    powercfg -changename $UltimateProfileGuid "Maximum FPS" "Optimized for zero-lag gaming"
    Write-Host "[Z-LAG] Ultimate Performance activated."
} elseif ($schemes -match $HighPerfGuid) {
    powercfg -setactive $HighPerfGuid
    Write-Host "[Z-LAG] Ultimate Performance unavailable - High Performance activated instead."
} else {
    Write-Host "[Z-LAG] No High/Ultimate scheme found; using current scheme."
}

# ----- 2. Fine-tune the ACTIVE scheme (both AC and DC for laptops) -----
Write-Host "[Z-LAG] Applying power scheme fine-tuning (AC + DC)..."
foreach ($scope in @("setacvalueindex", "setdcvalueindex")) {
    powercfg -$scope SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 2>$null
    powercfg -$scope SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>$null
    powercfg -$scope SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 2>$null
    powercfg -$scope SCHEME_CURRENT SUB_DISK DISKIDLE 0 2>$null
    powercfg -$scope SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0 2>$null
    powercfg -$scope SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0 2>$null
}
powercfg -setactive SCHEME_CURRENT
powercfg -hibernate off 2>$null

# ----- 3. BCDEdit timing tweaks (ignore errors if values missing) -----
Write-Host "[Z-LAG] Applying BCDEdit timing tweaks..."
bcdedit /deletevalue useplatformclock 2>$null
bcdedit /set tscsyncpolicy Enhanced 2>$null
bcdedit /set disabledynamictick yes 2>$null

Write-Host "[Z-LAG] Power plan and timing optimizations complete."
