# Diagnostic only: no process-scoped request masquerading as permanent tuning.
$ErrorActionPreference = 'Stop'
try {
    if (-not ('ZLagTimerQuery' -as [type])) {
        Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class ZLagTimerQuery {
    [DllImport("ntdll.dll")]
    public static extern int NtQueryTimerResolution(out uint minimum, out uint maximum, out uint current);
}
'@
    }
    [uint32]$minimum = 0
    [uint32]$maximum = 0
    [uint32]$current = 0
    $status = [ZLagTimerQuery]::NtQueryTimerResolution([ref]$minimum, [ref]$maximum, [ref]$current)
    if ($status -ne 0) { throw ('NtQueryTimerResolution returned ' + $status) }
    Write-Output ('[Z-LAG] Timer diagnostic: current={0:N3} ms, supported bounds={1:N3}/{2:N3} ms. Windows/apps retain timer policy.' -f ($current / 10000.0), ($minimum / 10000.0), ($maximum / 10000.0))
} catch {
    # Optional diagnostic is not required for boot or gaming performance.
    Write-Warning ('[Z-LAG] Timer diagnostic unavailable: ' + $_.Exception.Message)
}
