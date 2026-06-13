$tasks = @(
    @{Name="Microsoft Compatibility Appraiser"; Path="\Microsoft\Windows\Application Experience"},
    @{Name="ProgramDataUpdater"; Path="\Microsoft\Windows\Application Experience"},
    @{Name="aitagent"; Path="\Microsoft\Windows\Application Experience"},
    @{Name="Consolidator"; Path="\Microsoft\Windows\Customer Experience Improvement Program"},
    @{Name="KernelCeipTask"; Path="\Microsoft\Windows\Customer Experience Improvement Program"},
    @{Name="UsbCeipTask"; Path="\Microsoft\Windows\Customer Experience Improvement Program"},
    @{Name="Microsoft-Windows-DiskDiagnosticDataCollector"; Path="\Microsoft\Windows\DiskDiagnostic"},
    @{Name="WinSAT"; Path="\Microsoft\Windows\Maintenance"},
    @{Name="AnalyzeSystem"; Path="\Microsoft\Windows\Power Efficiency Diagnostics"},
    @{Name="FamilySafetyMonitor"; Path="\Microsoft\Windows\Shell"}
)

foreach ($t in $tasks) {
    Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue
}