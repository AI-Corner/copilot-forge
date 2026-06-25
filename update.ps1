<#
.SYNOPSIS
    Copilot Forge Updater v2

.DESCRIPTION
    Syncs the latest toolkit files into target project repos, produces health reports,
    supports health-only audits, and outputs JSON for CI pipelines.

.PARAMETER TargetDir
    One or more project repo paths to update. Accepts an array: -TargetDir "C:\a","C:\b"

.PARAMETER DryRun
    Preview all changes without writing any files.

.PARAMETER SkipGitPull
    Skip the automatic `git pull` on the toolkit (offline mode / already pulled).

.PARAMETER Force
    Skip the per-repo confirmation prompt.

.PARAMETER NoBackup
    Skip the pre-update backup. NOT recommended for production repos.

.PARAMETER Branch
    Git branch to pull from on the toolkit. Defaults to auto-detection.

.PARAMETER HealthOnly
    No copying, no stamping. Just reports version gap, protected conflicts, and template drift.

.PARAMETER JsonReport
    Outputs the final summary/health report as JSON.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]] $TargetDir,

    [switch] $DryRun,
    [switch] $SkipGitPull,
    [switch] $Force,
    [switch] $NoBackup,
    [string] $Branch = "",
    [string] $Restore = "",
    [switch] $HealthOnly,
    [switch] $JsonReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Header($text) { if (-not $JsonReport) { Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n  $text`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan } }
function Write-Ok($t)   { if (-not $JsonReport) { Write-Host "  ✅  $t" -ForegroundColor Green    } }
function Write-Warn($t) { if (-not $JsonReport) { Write-Host "  ⚠️   $t" -ForegroundColor Yellow   } }
function Write-Info($t) { if (-not $JsonReport) { Write-Host "  ℹ️   $t" -ForegroundColor Cyan     } }
function Write-New($t)  { if (-not $JsonReport) { Write-Host "  🆕  $t" -ForegroundColor Magenta  } }
function Write-Upd($t)  { if (-not $JsonReport) { Write-Host "  ✏️   $t" -ForegroundColor Yellow   } }
function Write-Skip($t) { if (-not $JsonReport) { Write-Host "  ⏭️   $t" -ForegroundColor DarkGray } }
function Write-Err($t)  { if (-not $JsonReport) { Write-Host "  ❌  $t" -ForegroundColor Red      } }

function Get-MD5Hash($path) {
    if (Test-Path $path -PathType Leaf) { return (Get-FileHash -Path $path -Algorithm MD5).Hash }
    return $null
}

function Get-DefaultBranch($repoPath) {
    $result = git -C $repoPath symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($result) { return ($result -split "/")[-1] }
    return "master"
}

function Get-ToolkitVersion($toolkitPath) {
    $readme = Join-Path $toolkitPath "README.md"
    if (Test-Path $readme) {
        $m = Select-String -Path $readme -Pattern "[-–]\s*\*{0,2}(v\d+\.\d+\.\d+)\*{0,2}" | Select-Object -First 1
        if ($m) { return $m.Matches[0].Groups[1].Value }
    }
    return "unknown"
}

function Get-InstalledVersion($projectPath) {
    $vf = Join-Path $projectPath ".forge\.forge-version"
    if (Test-Path $vf) { return (Get-Content $vf -Raw).Trim() }
    return "unknown"
}

function New-Backup($projectPath) {
    $timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $projectPath ".forge\.backups"
    $backupDir  = Join-Path $backupRoot  "pre-update-$timestamp"

    $dirsToBack = @(".github", ".vscode", ".forge\templates") | Where-Object { Test-Path (Join-Path $projectPath $_) }
    if ($dirsToBack.Count -eq 0) { return $null }

    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($rel in $dirsToBack) {
        $src = Join-Path $projectPath $rel
        $dst = Join-Path $backupDir   $rel
        Copy-Item -Path $src -Destination $dst -Recurse -Force
    }
    Write-Ok "Backup created → $backupDir"
    return $backupDir
}

$ProtectedFiles = @("copilot-instructions.md")

function Sync-Directory($toolkitPath, $projectPath, $subDir, [ref]$stats, [ref]$log) {
    $srcRoot = Join-Path $toolkitPath $subDir
    $dstRoot = Join-Path $projectPath $subDir

    if (-not (Test-Path $srcRoot)) { return }

    Get-ChildItem -Path $srcRoot -Recurse -File | ForEach-Object {
        $srcFile = $_.FullName
        $relPath = $srcFile.Substring($srcRoot.Length).TrimStart('\','/')
        $dstFile = Join-Path $dstRoot $relPath
        $srcHash = Get-MD5Hash $srcFile
        $dstHash = Get-MD5Hash $dstFile

        $fileName = Split-Path $relPath -Leaf
        if ($ProtectedFiles -contains $fileName -and $null -ne $dstHash -and $srcHash -ne $dstHash) {
            Write-Skip "[$subDir] $relPath  (protected — user-customised, kept as-is)"
            $stats.Value.Skipped++
            $log.Value.Add([PSCustomObject]@{ Dir=$subDir; File=$relPath; Status="SKIPPED" })
            return
        }

        if ($srcHash -eq $dstHash) { $stats.Value.Identical++; return }
        $isNew = ($null -eq $dstHash)

        if (-not $DryRun -and -not $HealthOnly) {
            $dstDir = Split-Path $dstFile -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item -Path $srcFile -Destination $dstFile -Force
        }

        if ($isNew) {
            if (-not $HealthOnly) { Write-New "[$subDir] $relPath" }
            $stats.Value.Added++
            $log.Value.Add([PSCustomObject]@{ Dir=$subDir; File=$relPath; Status="NEW" })
        } else {
            if (-not $HealthOnly) { Write-Upd "[$subDir] $relPath  ← updated" }
            $stats.Value.Updated++
            $log.Value.Add([PSCustomObject]@{ Dir=$subDir; File=$relPath; Status="UPDATED" })
        }
    }
}

function Get-DiffStats($fileA, $fileB) {
    try {
        $raw = git diff --no-index --numstat -- $fileA $fileB 2>$null
        if ($raw) {
            $parts = $raw.Trim() -split '\s+'
            if ($parts.Count -ge 2 -and $parts[0] -match '^\d+$') {
                return [int]$parts[0], [int]$parts[1]
            }
        }
    } catch {}
    return "?", "?"
}

function Invoke-TemplateDriftReport($toolkitPath, $projectPath) {
    $srcDir = Join-Path $toolkitPath "templates"
    $dstDir = Join-Path $projectPath ".forge\templates"
    $report = [System.Collections.Generic.List[PSCustomObject]]::new()

    if (Test-Path $srcDir) {
        Get-ChildItem -Path $srcDir -Filter "*.md" -File | ForEach-Object {
            $name    = $_.Name
            $srcFile = $_.FullName
            $dstFile = Join-Path $dstDir $name
            $srcHash = Get-MD5Hash $srcFile
            $dstHash = Get-MD5Hash $dstFile

            if ($null -eq $dstHash) {
                $report.Add([PSCustomObject]@{ Template = $name; "+Lines" = "-"; "-Lines" = "-"; Status = "🆕 New"; Action = "Added automatically" })
            } elseif ($srcHash -eq $dstHash) {
                $report.Add([PSCustomObject]@{ Template = $name; "+Lines" = "-"; "-Lines" = "-"; Status = "✅ In sync"; Action = "None" })
            } else {
                $added, $removed = Get-DiffStats $dstFile $srcFile
                $action = if ($added -gt 10 -or $removed -gt 10) { "Run #template-drift to review" } else { "Likely cosmetic — run #template-drift" }
                $report.Add([PSCustomObject]@{ Template = $name; "+Lines" = "+$added"; "-Lines" = "-$removed"; Status = "⚠️ Drifted"; Action = $action })
            }
        }
    }

    if (Test-Path $dstDir) {
        Get-ChildItem -Path $dstDir -Filter "*.md" -File | ForEach-Object {
            if (-not (Test-Path (Join-Path $srcDir $_.Name))) {
                $report.Add([PSCustomObject]@{ Template = $_.Name; "+Lines" = "-"; "-Lines" = "-"; Status = "🔒 Custom"; Action = "Untouched" })
            }
        }
    }

    if (-not $JsonReport) {
        Write-Header "Template Drift Health Report"
        $report | Format-Table -AutoSize | Out-String | Write-Host
    }
    return $report
}

function Update-Repo($toolkitPath, $projectPath, $toolkitVersion) {
    $projectPath = (Resolve-Path $projectPath).Path
    Write-Header "$projectPath"

    $installedVersion = Get-InstalledVersion $projectPath
    Write-Info "Installed : $installedVersion   |   Toolkit : $toolkitVersion"

    if (-not $HealthOnly) {
        $forgeConfig = Join-Path $projectPath ".forge\config.yml"
        if (-not (Test-Path $forgeConfig) -and -not $Force) {
            Write-Warn "Target does not appear to be a Forge project (no .forge/config.yml). Skipping. Use -Force to override."
            return $null
        }

        if ($installedVersion -eq $toolkitVersion -and $installedVersion -ne "unknown" -and -not $Force) {
            Write-Ok "Already at $toolkitVersion — nothing to sync."
            return $null
        }

        if ($DryRun) { Write-Warn "DRY RUN — no files will be written." }

        if (-not $Force -and -not $DryRun) {
            $ok = Read-Host "  Proceed with update? [Y/n]"
            if ($ok -and $ok.ToLower() -ne "y") { Write-Warn "Skipped."; return $null }
        }

        # Migrate old templates dir
        $oldTemplates = Join-Path $projectPath "templates"
        $newTemplates = Join-Path $projectPath ".forge\templates"
        if (Test-Path $oldTemplates -PathType Container) {
            Write-Info "Migrating legacy templates/ directory to .forge/templates/..."
            if (-not $DryRun) {
                if (-not (Test-Path $newTemplates)) {
                    $forgeDir = Join-Path $projectPath ".forge"
                    if (-not (Test-Path $forgeDir)) { New-Item -ItemType Directory $forgeDir -Force | Out-Null }
                    Move-Item $oldTemplates $newTemplates -Force
                } else {
                    Copy-Item "$oldTemplates\*" $newTemplates -Recurse -Force
                    Remove-Item $oldTemplates -Recurse -Force
                }
            }
        }
    }

    $backupDir = $null
    if (-not $DryRun -and -not $NoBackup -and -not $HealthOnly) {
        $backupDir = New-Backup $projectPath
    }

    $stats = [ref]@{ Added=0; Updated=0; Identical=0; Skipped=0 }
    $log   = [ref][System.Collections.Generic.List[PSCustomObject]]::new()

    Sync-Directory $toolkitPath $projectPath ".github"  $stats $log
    Sync-Directory $toolkitPath $projectPath ".vscode"  $stats $log
    Sync-Directory $toolkitPath $projectPath "scripts"  $stats $log

    if (-not $HealthOnly) {
        $srcTemplates = Join-Path $toolkitPath "templates"
        $dstTemplates = Join-Path $projectPath ".forge\templates"
        if (Test-Path $srcTemplates) {
            Get-ChildItem -Path $srcTemplates -Filter "*.md" -File | ForEach-Object {
                $dstFile = Join-Path $dstTemplates $_.Name
                if (-not (Test-Path $dstFile)) {
                    if (-not $DryRun) {
                        if (-not (Test-Path $dstTemplates)) { New-Item -ItemType Directory $dstTemplates -Force | Out-Null }
                        Copy-Item $_.FullName $dstFile -Force
                    }
                    Write-New "[templates] $($_.Name)"
                    $stats.Value.Added++
                    $log.Value.Add([PSCustomObject]@{ Dir="templates"; File=$_.Name; Status="NEW" })
                }
            }
        }

        if (-not $DryRun -and $toolkitVersion -ne "unknown") {
            $forgeDir = Join-Path $projectPath ".forge"
            if (Test-Path $forgeDir) {
                Set-Content (Join-Path $forgeDir ".forge-version") $toolkitVersion
            }
        }
    }

    $templateReport = Invoke-TemplateDriftReport $toolkitPath $projectPath

    $resultObj = @{
        Project = $projectPath
        InstalledVersion = $installedVersion
        ToolkitVersion = $toolkitVersion
        FilesAdded = $stats.Value.Added
        FilesUpdated = $stats.Value.Updated
        FilesSkipped = $stats.Value.Skipped
        TemplateDrift = $templateReport
        BackupDir = $backupDir
    }

    if (-not $JsonReport) {
        Write-Header "Update Summary"
        Write-Host "  🆕 Added     : $($stats.Value.Added)"
        Write-Host "  ✏️  Updated   : $($stats.Value.Updated)"
        Write-Host "  ⏭️  Skipped   : $($stats.Value.Skipped)"
    }

    return $resultObj
}

$ToolkitDir = $PSScriptRoot

if (-not (Test-Path (Join-Path $ToolkitDir ".github"))) {
    Write-Err "Run update.ps1 from the copilot-forge toolkit root directory."
    exit 1
}

if (-not $SkipGitPull -and -not $HealthOnly) {
    $pullBranch = if ($Branch) { $Branch } else { Get-DefaultBranch $ToolkitDir }
    Push-Location $ToolkitDir
    try {
        $out = git pull origin $pullBranch 2>&1
    } catch {} finally { Pop-Location }
}

$toolkitVersion = Get-ToolkitVersion $ToolkitDir
$allResults = @()

foreach ($target in $TargetDir) {
    if (-not (Test-Path $target)) { continue }
    $res = Update-Repo $ToolkitDir $target $toolkitVersion
    if ($res) { $allResults += $res }
}

if ($JsonReport) {
    $allResults | ConvertTo-Json -Depth 5 | Write-Output
}
