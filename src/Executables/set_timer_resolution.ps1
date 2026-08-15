$source = @'
using System;
using System.Runtime.InteropServices;
public class Timer {
    [DllImport("ntdll.dll")]
    public static extern uint NtSetTimerResolution(uint DesiredResolution, bool SetResolution, ref uint CurrentResolution);
}
'@
Add-Type -TypeDefinition $source
$cur = 0
[Timer]::NtSetTimerResolution(5000, $true, [ref]$cur)