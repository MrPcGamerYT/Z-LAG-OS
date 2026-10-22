# Test only extracted pure profile/snapshot functions; never apply registry tweaks.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $root 'src/Executables/set_kernel_profile.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Kernel profile source has parse errors.' }
foreach ($name in @('Get-ZLagKernelProfile', 'Read-ZLagKernelSnapshot')) {
    $definition = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true) | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $definition) { throw "Missing helper: $name" }
    Invoke-Expression $definition.Extent.Text
}
$profile = @(Get-ZLagKernelProfile)
if ($profile.Count -ne 4) { throw 'Unexpected kernel profile size.' }
if (($profile | Where-Object Name -eq 'DisablePagingExecutive').Value -ne 0) { throw 'Must allow executive paging.' }
if (($profile | Where-Object Name -eq 'SystemResponsiveness').Value -ne 10) { throw 'Must use valid MMCSS reserve.' }
$testDir = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
New-Item -Path $testDir -ItemType Directory | Out-Null
try {
    $path = Join-Path $testDir 'snapshot.json'
    $values = @($profile | ForEach-Object {
        [PSCustomObject]@{ Path = $_.Path; Name = $_.Name; Exists = $true; Value = 20 }
    })
    [PSCustomObject]@{ Version = 1; Values = $values } | ConvertTo-Json -Depth 4 | Set-Content $path -Encoding UTF8
    $result = Read-ZLagKernelSnapshot -Path $path -Profile $profile
    if ($result.Values.Count -ne 4) { throw 'Valid original snapshot rejected.' }
    $values[0].Path = 'HKLM:\SOFTWARE\UnexpectedTarget'
    [PSCustomObject]@{ Version = 1; Values = $values } | ConvertTo-Json -Depth 4 | Set-Content $path -Encoding UTF8
    $rejected = $false
    try { $null = Read-ZLagKernelSnapshot -Path $path -Profile $profile } catch { $rejected = $true }
    if (-not $rejected) { throw 'Unapproved restore target was accepted.' }
    Set-Content $path '{invalid-json' -Encoding UTF8
    $rejected = $false
    try { $null = Read-ZLagKernelSnapshot -Path $path -Profile $profile } catch { $rejected = $true }
    if (-not $rejected) { throw 'Corrupt snapshot was accepted.' }
    Write-Host 'PASS: kernel profile values and restore snapshot whitelist; no registry changes performed.'
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
