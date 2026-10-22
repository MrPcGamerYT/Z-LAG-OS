# Shared hosts-file editor. Dot-source; no OS changes until explicitly invoked.
$ErrorActionPreference = 'Continue'

function Update-ZLagHostsFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$BlockedHosts = @(),
        [string[]]$UnblockedHosts = @()
    )
    $ErrorActionPreference = 'Stop'
    foreach ($hostname in @($BlockedHosts) + @($UnblockedHosts)) {
        if ($hostname -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$') {
            throw "Invalid hostname: $hostname"
        }
    }
    $fullPath = [IO.Path]::GetFullPath($Path)
    $exists = [IO.File]::Exists($fullPath)
    [byte[]]$bytes = @()
    if ($exists) { $bytes = [IO.File]::ReadAllBytes($fullPath) }
    # Byte-preserving fallback for ASCII-compatible files (including BOM-less
    # UTF-8 and legacy ANSI). Only ASCII host tokens are edited. Preserve BOMs.
    $encoding = [Text.Encoding]::GetEncoding(28591)
    $offset = 0
    if ($bytes.Length -ge 4 -and (($bytes[0] -eq 255 -and $bytes[1] -eq 254 -and $bytes[2] -eq 0 -and $bytes[3] -eq 0) -or
        ($bytes[0] -eq 0 -and $bytes[1] -eq 0 -and $bytes[2] -eq 254 -and $bytes[3] -eq 255))) {
        throw 'UTF-32 hosts files are not supported; original file left unchanged.'
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        $encoding = New-Object Text.UTF8Encoding($true, $true)
        $offset = 3
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) {
        $encoding = [Text.Encoding]::Unicode
        $offset = 2
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255) {
        $encoding = [Text.Encoding]::BigEndianUnicode
        $offset = 2
    }
    $original = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
    $newline = if ($original.Contains("`r`n")) { "`r`n" } elseif ($original.Contains("`n")) { "`n" } elseif ($original.Contains("`r")) { "`r" } else { "`r`n" }
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $present = @{}
    foreach ($line in [regex]::Split($original, '\r\n|\n|\r')) {
        $parts = $line -split '#', 2
        $fields = @($parts[0].Trim() -split '\s+' | Where-Object { $_ })
        $updatedLine = $line
        if ($fields.Count -ge 2 -and $fields[0] -in @('0.0.0.0', '127.0.0.1', '::', '::1')) {
            $aliases = @($fields[1..($fields.Count - 1)] | Where-Object { $_ -notin $UnblockedHosts })
            if ($aliases.Count -ne $fields.Count - 1) {
                $updatedLine = if ($aliases.Count) { $fields[0] + ' ' + ($aliases -join ' ') } else { '' }
                if ($parts.Count -eq 2) { $updatedLine += ' #' + $parts[1] }
            }
            foreach ($alias in $aliases) { $present[$alias] = $true }
        }
        $lines.Add($updatedLine)
    }
    foreach ($hostname in $BlockedHosts) {
        if ($hostname -in $UnblockedHosts) { continue }
        if (-not $present.ContainsKey($hostname)) {
            if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
            $lines.Add('0.0.0.0 ' + $hostname)
            $lines.Add('')
            $present[$hostname] = $true
        }
    }
    $updated = $lines -join $newline
    if ($updated -ceq $original) { return $false }
    $payload = [byte[]]($encoding.GetPreamble() + $encoding.GetBytes($updated))
    $temp = $fullPath + '.zlag-' + [Guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllBytes($temp, $payload)
        if ($exists) {
            # Same-volume replacement, backup and destination metadata preserved.
            # Failure (e.g. access denied) leaves the original in place.
            $backup = $fullPath + '.zlag-backup-' + [Guid]::NewGuid().ToString('N')
            [IO.File]::Replace($temp, $fullPath, $backup)
        } else {
            [IO.File]::Move($temp, $fullPath)
        }
    } finally {
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
    }
    return $true
}
