param(
    [Parameter(Mandatory = $true)][string]$SourceScript,
    [Parameter(Mandatory = $true)][string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$content = Get-Content -LiteralPath $SourceScript -Raw
$pattern = '(?s)\$welcomeSource\s*=\s*@''\r?\n(?<source>.*?)\r?\n''@'
$match = [regex]::Match($content, $pattern)
if (-not $match.Success) { throw 'Embedded Welcome C# source was not found.' }
$source = $match.Groups['source'].Value

Add-Type -AssemblyName @('System.Windows.Forms', 'System.Drawing') -ErrorAction Stop
$references = @(
    [System.Diagnostics.Process].Assembly.Location,
    [System.Windows.Forms.Form].Assembly.Location,
    [System.Drawing.Color].Assembly.Location
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
if ($references.Count -lt 3) { throw 'Required WinForms reference paths were not resolved.' }

Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
Add-Type -TypeDefinition $source -Language CSharp -ReferencedAssemblies $references -CompilerOptions '/optimize+ /platform:anycpu' -OutputAssembly $OutputPath -OutputType WindowsApplication -IgnoreWarnings -ErrorAction Stop

$bytes = [IO.File]::ReadAllBytes($OutputPath)
if ($bytes.Length -lt 8192 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { throw 'PE validation failed.' }
$assembly = [Reflection.AssemblyName]::GetAssemblyName($OutputPath)
$versionInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($OutputPath)
if ($assembly.Name -ne 'ZLAGOptiServices') { throw ('Unexpected assembly name: ' + $assembly.Name) }
if ($versionInfo.ProductName -ne 'Z LAG Optimization Services') { throw ('Unexpected product name: ' + $versionInfo.ProductName) }
if ($versionInfo.FileVersion -ne '5.13.0.0') { throw ('Unexpected file version: ' + $versionInfo.FileVersion) }

for ($attempt = 1; $attempt -le 4; $attempt++) {
    $process = Start-Process -FilePath $OutputPath -ArgumentList '--self-test' -PassThru -WindowStyle Hidden
    if (-not $process.WaitForExit(10000)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw ('Self-test timed out on attempt ' + $attempt)
    }
    if ($process.ExitCode -ne 0) { throw ('Self-test failed on attempt ' + $attempt + ' with exit code ' + $process.ExitCode) }
}

$hash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
Write-Output ('PASS: {0} v{1}, {2} bytes, SHA256 {3}' -f $versionInfo.ProductName, $versionInfo.FileVersion, $bytes.Length, $hash)
