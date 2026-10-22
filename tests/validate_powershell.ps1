# Parse only. Never execute destructive optimization scripts in CI.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failed = $false
$files = @(Get-ChildItem (Join-Path $root 'src/Executables') -Filter '*.ps1') +
    @(Get-ChildItem $PSScriptRoot -Filter '*.ps1')
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    foreach ($parseError in $errors) {
        Write-Host ($file.Name + ':' + $parseError.Extent.StartLineNumber + ': ' + $parseError.Message)
        $failed = $true
    }
}
if ($failed) { throw 'PowerShell payload syntax validation failed.' }
Write-Host ('PASS: parsed {0} PowerShell payloads without executing them.' -f $files.Count)
