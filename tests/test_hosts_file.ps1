# Exercise only the shared editor against disposable files; never system hosts.
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/Executables/hosts_file_utils.ps1')
$ErrorActionPreference = 'Stop'
$testDir = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
New-Item -Path $testDir -ItemType Directory | Out-Null
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
try {
    $path = Join-Path $testDir 'hosts'
    $source = "# 0.0.0.0 telemetry.microsoft.com is only a comment`r`n" +
        "0.0.0.0 telemetryXmicrosoftXcom`r`n" +
        "127.0.0.1 keep.example download.microsoft.com # retain alias/comment`r`n" +
        "::1 defender.microsoft.com other.example`r`n" +
        '192.0.2.1 custom.example'
    [IO.File]::WriteAllText($path, $source, [Text.Encoding]::ASCII)
    $changed = Update-ZLagHostsFile -Path $path -BlockedHosts @('telemetry.microsoft.com', 'TELEMETRY.MICROSOFT.COM') -UnblockedHosts @('download.microsoft.com', 'defender.microsoft.com')
    Assert-True $changed 'First pass must change the hosts file.'
    $text = [IO.File]::ReadAllText($path)
    Assert-True ($text.Contains('# 0.0.0.0 telemetry.microsoft.com is only a comment')) 'Comment was lost.'
    Assert-True ($text.Contains('0.0.0.0 telemetryXmicrosoftXcom')) 'Regex-like near-match must be preserved.'
    Assert-True ($text.Contains('127.0.0.1 keep.example # retain alias/comment')) 'Unblocking must retain unrelated aliases/comments.'
    Assert-True ($text.Contains('::1 other.example')) 'IPv6 alias cleanup failed.'
    Assert-True ($text.Contains("custom.example`r`n0.0.0.0 telemetry.microsoft.com")) 'Missing newline must not concatenate mappings.'
    $backups = @(Get-ChildItem $testDir -Filter '*.zlag-backup-*')
    Assert-True ($backups.Count -eq 1) 'Expected one backup for the mutation.'
    Assert-True ([IO.File]::ReadAllText($backups[0].FullName) -ceq $source) 'Backup must preserve original content.'
    $changed = Update-ZLagHostsFile -Path $path -BlockedHosts @('TELEMETRY.MICROSOFT.COM') -UnblockedHosts @('download.microsoft.com', 'defender.microsoft.com')
    Assert-True (-not $changed) 'Second pass must be idempotent.'
    Assert-True (@(Get-ChildItem $testDir -Filter '*.zlag-backup-*').Count -eq 1) 'No-op must not create extra backups.'

    # Round-trip BOM-less UTF-8, legacy single-byte comments and Unicode BOMs.
    $utf8 = New-Object Text.UTF8Encoding($false)
    $utf8Bom = New-Object Text.UTF8Encoding($true)
    $label = '# caf' + [char]0xE9 + "`n"
    foreach ($encoding in @($utf8, $utf8Bom, [Text.Encoding]::GetEncoding(28591), [Text.Encoding]::Unicode, [Text.Encoding]::BigEndianUnicode)) {
        [byte[]]$originalBytes = $encoding.GetPreamble() + $encoding.GetBytes($label)
        [IO.File]::WriteAllBytes($path, $originalBytes)
        $null = Update-ZLagHostsFile -Path $path -BlockedHosts @('update.microsoft.com')
        $after = [IO.File]::ReadAllBytes($path)
        for ($i = 0; $i -lt $originalBytes.Length; $i++) {
            Assert-True ($after[$i] -eq $originalBytes[$i]) 'Unrelated non-ASCII comment/BOM bytes changed.'
        }
        Assert-True (-not (Update-ZLagHostsFile -Path $path -BlockedHosts @('update.microsoft.com'))) 'Encoded file not idempotent.'
    }
    $empty = Join-Path $testDir 'new-hosts'
    Assert-True (Update-ZLagHostsFile -Path $empty -BlockedHosts @('test.example')) 'Missing hosts file should be created.'
    Assert-True ([IO.File]::ReadAllText($empty).Contains('0.0.0.0 test.example')) 'Missing-file entry not written.'
    $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
    $rejected = $false
    try { $null = Update-ZLagHostsFile -Path $path -BlockedHosts @("bad.example`nmalformed") } catch { $rejected = $true }
    Assert-True $rejected 'Invalid host input must be rejected.'
    Assert-True ($before -eq [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))) 'Rejected input must not change file.'
    Write-Host 'PASS: hosts literal matching, alias cleanup, IPv6, newlines, encoding, backups and idempotency.'
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
