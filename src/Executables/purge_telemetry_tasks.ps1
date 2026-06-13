$taskPaths = @(
    "\Microsoft\Windows\Application Experience"
    "\Microsoft\Windows\Customer Experience Improvement Program"
    "\Microsoft\Windows\DiskDiagnostic"
    "\Microsoft\Windows\Power Efficiency Diagnostics"
    "\Microsoft\Windows\Windows Error Reporting"
    "\Microsoft\Windows\Location"
    "\Microsoft\Windows\Speech"
    "\Microsoft\Windows\WiFi"
    "\Microsoft\Windows\WindowsUpdate"
    "\Microsoft\Windows\CloudExperienceHost"
    "\Microsoft\Windows\DeviceInfo"
)
foreach ($path in $taskPaths) {
    Get-ScheduledTask -TaskPath "$path\*" -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
}
# Specific named tasks
$namedTasks = @(
    @{Name="Microsoft Compatibility Appraiser"; Path="\Microsoft\Windows\Application Experience"}
    @{Name="ProgramDataUpdater"; Path="\Microsoft\Windows\Application Experience"}
    @{Name="Consolidator"; Path="\Microsoft\Windows\Customer Experience Improvement Program"}
    @{Name="UsbCeipTask"; Path="\Microsoft\Windows\Customer Experience Improvement Program"}
    @{Name="DiskDiagnostic"; Path="\Microsoft\Windows\DiskDiagnostic"}
)
foreach ($t in $namedTasks) {
    Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction SilentlyContinue
}