# Unit test only extracted helper functions; never run the installer payload.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $root 'src/Executables/install_toolbox.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Toolbox source has parse errors.' }
foreach ($name in @('Write-Log', 'Invoke-RobustDownload')) {
    $definition = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true) | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $definition) { throw "Missing helper: $name" }
    Invoke-Expression $definition.Extent.Text
}

$testDir = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
New-Item -Path $testDir -ItemType Directory | Out-Null
$originalSystemRoot = $env:SystemRoot
try {
    # Force the native-request branch without invoking curl or using the network.
    $env:SystemRoot = $testDir
    $logFile = Join-Path $testDir 'download.log'
    $outFile = Join-Path $testDir 'test-download.bin'
    function Start-Sleep { param($Seconds) }
    function Invoke-WebRequest { throw 'Simulated network failure' }
    $result = @(Invoke-RobustDownload -Url 'https://example.invalid/test' -OutFile $outFile)
    if ($result.Count -ne 1 -or $result[0] -isnot [bool] -or $result[0]) {
        throw 'Failed download must return only Boolean false, not truthy log strings.'
    }
    function Invoke-WebRequest {
        param($Uri, $OutFile, [switch]$UseBasicParsing, $TimeoutSec)
        [IO.File]::WriteAllBytes($OutFile, (New-Object byte[] 1048577))
    }
    $result = @(Invoke-RobustDownload -Url 'https://example.invalid/test' -OutFile $outFile)
    if ($result.Count -ne 1 -or $result[0] -isnot [bool] -or -not $result[0]) {
        throw 'Successful download must return only Boolean true.'
    }
    Write-Host 'PASS: mocked Toolbox download failure/success return one Boolean; no network or installer executed.'
} finally {
    $env:SystemRoot = $originalSystemRoot
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
