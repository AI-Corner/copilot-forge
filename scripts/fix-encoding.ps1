<#
.SYNOPSIS
    Scans and fixes encoding issues (BOM, U+FFFD) across the repo.
.DESCRIPTION
    Strips UTF-8 BOM and removes U+FFFD replacement characters from all
    text files. Safe to run repeatedly — idempotent.
#>

param(
    [switch] $DryRun
)

$extensions = @("*.md","*.ps1","*.sh","*.yml","*.yaml","*.json","*.txt","*.html","*.css","*.js")
$fixed = 0

Get-ChildItem -Recurse -File -Include $extensions | ForEach-Object {
    $path = $_.FullName
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $changed = $false

    # Strip BOM
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
        $changed = $true
    }

    # Remove U+FFFD
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($content.Contains([char]0xFFFD)) {
        $content = $content.Replace([string][char]0xFFFD, '')
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $changed = $true
    }

    if ($changed) {
        $rel = $path.Substring((Get-Location).Path.Length + 1)
        if ($DryRun) {
            Write-Host "WOULD FIX: $rel"
        } else {
            [System.IO.File]::WriteAllBytes($path, $bytes)
            Write-Host "FIXED: $rel"
        }
        $script:fixed++
    }
}

if ($fixed -eq 0) {
    Write-Host "All files clean — no issues found."
} else {
    $verb = if ($DryRun) { "would be fixed" } else { "fixed" }
    Write-Host "`n$fixed file(s) $verb."
}
