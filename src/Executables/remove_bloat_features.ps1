# Remove-OptionalApps.ps1
# Removes selected Optional Features from Windows

Write-Host "Removing Optional Features..." -ForegroundColor Cyan

$patterns = @(
    "Notepad",
    "Paint",
    "WordPad",
    "MathRecognizer",
    "Hello.Face",
    "OpenSSH.Client",
    "OpenSSH.Server",
    "StepsRecorder",
    "QuickAssist",
    "Fax",
    "PowerShell.ISE",
    "WMIC",
    "Print.Management.Console"
)

foreach ($pattern in $patterns) {

    $caps = Get-WindowsCapability -Online |
        Where-Object {
            $_.Name -match $pattern -and
            $_.State -eq "Installed"
        }

    foreach ($cap in $caps) {

        Write-Host "Removing capability: $($cap.Name)" -ForegroundColor Yellow

        try {
            Remove-WindowsCapability `
                -Online `
                -Name $cap.Name `
                -ErrorAction Stop
        }
        catch {
            Write-Warning $_.Exception.Message
        }
    }
}

Write-Host "Finished. A restart may be required." -ForegroundColor Green