# Z-LAG OS - create a pre-optimization system restore point (safety net).
# Runs BEFORE any aggressive tweak while VSS/System Restore is still enabled.
# Fails safe: never blocks the playbook if System Protection is unavailable.
$ErrorActionPreference = "Continue"
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Z-LAG OS - Pre-Optimization" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop | Out-Null
    Write-Output "[Z-LAG] Restore point created."
} catch {
    Write-Output "[Z-LAG] Restore point skipped (System Protection unavailable): $($_.Exception.Message)"
}
