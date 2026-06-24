param (
    [Parameter(Mandatory=$true)]
    [string[]]$TargetDir,
    
    [switch]$DryRun,
    [switch]$SkipGitPull,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ToolkitDir = $PSScriptRoot

function Get-MD5Hash($FilePath) {
    if (Test-Path $FilePath -PathType Leaf) {
        return (Get-FileHash -Path $FilePath -Algorithm MD5).Hash
    }
    return $null
}

function Invoke-GitPull {
    Write-Host "Fetching latest updates for Copilot Forge toolkit..." -ForegroundColor Cyan
    $origDir = $PWD
    try {
        Set-Location $ToolkitDir
        git pull origin master
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: git pull failed. Proceeding with current local version." -ForegroundColor Yellow
        }
    } finally {
        Set-Location $origDir
    }
}

function Sync-CoreDirectory($TargetProject, $SubDir) {
    $SourcePath = Join-Path $ToolkitDir $SubDir
    $DestPath = Join-Path $TargetProject $SubDir

    if (-not (Test-Path $SourcePath)) { return }

    Get-ChildItem -Path $SourcePath -Recurse -File | ForEach-Object {
        $srcFile = $_.FullName
        $relPath = $srcFile.Substring($SourcePath.Length + 1)
        $dstFile = Join-Path $DestPath $relPath

        $srcHash = Get-MD5Hash $srcFile
        $dstHash = Get-MD5Hash $dstFile

        if ($srcHash -ne $dstHash) {
            # Protection for copilot-instructions.md
            if ($relPath -eq "copilot-instructions.md" -and ($SubDir -eq ".github" -or $SubDir -eq ".github\prompts")) {
                if ($dstHash -ne $null) {
                    Write-Host "  [SKIP] User customized $SubDir\$relPath (Hashes differ). Keeping local version." -ForegroundColor Yellow
                    return
                }
            }

            if (-not $DryRun) {
                $dstDir = Split-Path $dstFile -Parent
                if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
                Copy-Item -Path $srcFile -Destination $dstFile -Force
            }
            if ($dstHash -eq $null) {
                Write-Host "  [ADD]  $SubDir\$relPath" -ForegroundColor Green
            } else {
                Write-Host "  [SYNC] $SubDir\$relPath" -ForegroundColor Cyan
            }
        }
    }
}

function Sync-Templates($TargetProject) {
    $SourceTemplates = Join-Path $ToolkitDir "templates"
    $DestTemplates = Join-Path $TargetProject "templates"
    
    $Report = @()

    if (Test-Path $SourceTemplates) {
        Get-ChildItem -Path $SourceTemplates -Recurse -File | ForEach-Object {
            $srcFile = $_.FullName
            $relPath = $srcFile.Substring($SourceTemplates.Length + 1)
            $dstFile = Join-Path $DestTemplates $relPath

            $srcHash = Get-MD5Hash $srcFile
            $dstHash = Get-MD5Hash $dstFile

            if ($dstHash -eq $null) {
                if (-not $DryRun) {
                    $dstDir = Split-Path $dstFile -Parent
                    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
                    Copy-Item -Path $srcFile -Destination $dstFile -Force
                }
                $Report += [PSCustomObject]@{ Template = $relPath; Added = "-"; Removed = "-"; Status = "🆕 New"; Action = "Added from toolkit" }
            } elseif ($srcHash -eq $dstHash) {
                $Report += [PSCustomObject]@{ Template = $relPath; Added = "-"; Removed = "-"; Status = "✅ Identical"; Action = "None" }
            } else {
                # Drifted
                $added = "?"
                $removed = "?"
                
                # Try to use git diff --numstat
                try {
                    # Note: git diff --no-index --numstat outputs like: "42\t8\tfilename"
                    $diffOutput = git diff --no-index --numstat $dstFile $srcFile 2>$null
                    if ($diffOutput) {
                        $parts = $diffOutput.Trim() -split '\s+'
                        if ($parts.Length -ge 2) {
                            $added = $parts[0]
                            $removed = $parts[1]
                        }
                    }
                } catch {}

                $Report += [PSCustomObject]@{ Template = $relPath; Added = "+$added"; Removed = "-$removed"; Status = "⚠️ Drifted"; Action = "Review manually" }
            }
        }
    }

    # Find custom templates
    if (Test-Path $DestTemplates) {
        Get-ChildItem -Path $DestTemplates -Recurse -File | ForEach-Object {
            $dstFile = $_.FullName
            $relPath = $dstFile.Substring($DestTemplates.Length + 1)
            $srcFile = Join-Path $SourceTemplates $relPath
            if (-not (Test-Path $srcFile)) {
                $Report += [PSCustomObject]@{ Template = $relPath; Added = "-"; Removed = "-"; Status = "🔒 Custom"; Action = "Untouched" }
            }
        }
    }

    Write-Host "`nTemplate Drift Health Report:" -ForegroundColor Magenta
    $Report | Format-Table Template, Added, Removed, Status, Action | Out-String | Write-Host
}

function Get-ToolkitVersion {
    $readmePath = Join-Path $ToolkitDir "README.md"
    if (Test-Path $readmePath) {
        $match = Select-String -Path $readmePath -Pattern "^\- \*\*(v.*?)\*\*:" | Select-Object -First 1
        if ($match) {
            return $match.Matches.Groups[1].Value
        }
    }
    return "unknown"
}

# ---------------------------
# Main Execution
# ---------------------------

if (-not $SkipGitPull) {
    Invoke-GitPull
}

$Version = Get-ToolkitVersion

foreach ($Target in $TargetDir) {
    Write-Host "`n=================================================" -ForegroundColor DarkGray
    Write-Host "Updating Project: $Target" -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor DarkGray

    if (-not (Test-Path $Target)) {
        Write-Host "Error: Target directory does not exist: $Target" -ForegroundColor Red
        continue
    }

    if (-not $Force -and -not $DryRun) {
        $confirm = Read-Host "Are you sure you want to update $Target? (y/n)"
        if ($confirm -notmatch "^y") {
            Write-Host "Skipping $Target..." -ForegroundColor Yellow
            continue
        }
    }

    if ($DryRun) { Write-Host "*** DRY RUN MODE *** (No files will be modified)`n" -ForegroundColor Yellow }

    Write-Host "Syncing core components..." -ForegroundColor Cyan
    Sync-CoreDirectory $Target ".github"
    Sync-CoreDirectory $Target ".vscode"
    Sync-CoreDirectory $Target "scripts"

    Sync-Templates $Target

    if (-not $DryRun) {
        $forgeDir = Join-Path $Target ".forge"
        if (Test-Path $forgeDir) {
            $versionFile = Join-Path $forgeDir ".forge-version"
            Set-Content -Path $versionFile -Value $Version -Force
            Write-Host "Stamped version $Version in .forge/.forge-version" -ForegroundColor DarkGray
        }
    }

    Write-Host "`nNext Steps for $Target:" -ForegroundColor Yellow
    Write-Host "1. Open Copilot Chat and run '#template-drift' to approve reconciliation actions for any ⚠️ Drifted templates."
    Write-Host "2. Run '#init' to safely apply any new context structure migrations."
}
