<#
.SYNOPSIS
    Copilot Forge Updater — npm-style auto-update for your project repos.

.DESCRIPTION
    Syncs the latest toolkit files (.github prompts, agents, .vscode settings, templates)
    from the copilot-forge toolkit into one or more target project repos, creates a
    timestamped backup before any writes, then produces a drift health report.

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
    Git branch to pull from on the toolkit. Defaults to auto-detection (main/master).

.EXAMPLE
    .\update.ps1 -TargetDir "C:\repos\my-api"
    .\update.ps1 -TargetDir "C:\repos\my-api","C:\repos\my-frontend"
    .\update.ps1 -TargetDir "C:\repos\my-api" -DryRun
    .\update.ps1 -TargetDir "C:\repos\my-api" -SkipGitPull -Force
    .\update.ps1 -Restore ".forge\.backups\pre-update-20260623-221000" -TargetDir "C:\repos\my-api"
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
    [string] $Restore = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Header($text) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
}

function Write-Ok($t)   { Write-Host "  ✅  $t" -ForegroundColor Green    }
function Write-Warn($t) { Write-Host "  ⚠️   $t" -ForegroundColor Yellow   }
function Write-Info($t) { Write-Host "  ℹ️   $t" -ForegroundColor Cyan     }
function Write-New($t)  { Write-Host "  🆕  $t" -ForegroundColor Magenta  }
function Write-Upd($t)  { Write-Host "  ✏️   $t" -ForegroundColor Yellow   }
function Write-Skip($t) { Write-Host "  ⏭️   $t" -ForegroundColor DarkGray }
function Write-Err($t)  { Write-Host "  ❌  $t" -ForegroundColor Red      }

function Get-MD5Hash($path) {
    if (Test-Path $path -PathType Leaf) {
        return (Get-FileHash -Path $path -Algorithm MD5).Hash
    }
    return $null
}

function Get-DefaultBranch($repoPath) {
    $result = git -C $repoPath symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($result) { return ($result -split "/")[-1] }
    $branches = git -C $repoPath branch -r 2>$null
    if ($branches -match "origin/main")   { return "main"   }
    if ($branches -match "origin/master") { return "master" }
    return "main"
}

function Get-ToolkitVersion($toolkitPath) {
    $vf = Join-Path $toolkitPath ".forge\.forge-version"
    if (Test-Path $vf) { return (Get-Content $vf -Raw).Trim() }

    $readme = Join-Path $toolkitPath "README.md"
    if (Test-Path $readme) {
        $m = Select-String -Path $readme -Pattern "[-–]\s*\*{0,2}(v\d+\.\d+\.\d+)\*{0,2}" |
             Select-Object -First 1
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

    $dirsToBack = @(".github", ".vscode", ".forge\templates") |
                  Where-Object { Test-Path (Join-Path $projectPath $_) }

    if ($dirsToBack.Count -eq 0) {
        Write-Info "Nothing to back up (no managed dirs found yet)."
        return $null
    }

    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    foreach ($rel in $dirsToBack) {
        $src = Join-Path $projectPath $rel
        $dst = Join-Path $backupDir   $rel
        Copy-Item -Path $src -Destination $dst -Recurse -Force
    }

    Write-Ok "Backup created → $backupDir"
    return $backupDir
}

function Invoke-Restore($backupPath, $projectPath) {
    if (-not (Test-Path $backupPath)) {
        Write-Err "Backup path not found: $backupPath"
        exit 1
    }
    Write-Header "Restoring backup → $projectPath"
    Write-Warn "This will overwrite all managed files with the backup snapshot."
    $ok = Read-Host "  Confirm restore? [Y/n]"
    if ($ok -and $ok.ToLower() -ne "y") { Write-Warn "Aborted."; return }

    Get-ChildItem -Path $backupPath -Recurse -File | ForEach-Object {
        $rel    = $_.FullName.Substring($backupPath.Length).TrimStart('\','/')
        $dst    = Join-Path $projectPath $rel
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory $dstDir -Force | Out-Null }
        Copy-Item $_.FullName $dst -Force
        Write-Ok "Restored: $rel"
    }
    Write-Ok "Rollback complete."
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

        if (-not $DryRun) {
            $dstDir = Split-Path $dstFile -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item -Path $srcFile -Destination $dstFile -Force
        }

        if ($isNew) {
            Write-New "[$subDir] $relPath"
            $stats.Value.Added++
            $log.Value.Add([PSCustomObject]@{ Dir=$subDir; File=$relPath; Status="NEW" })
        } else {
            Write-Upd "[$subDir] $relPath  ← updated"
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
    $linesA = @(Get-Content $fileA -ErrorAction SilentlyContinue)
    $linesB = @(Get-Content $fileB -ErrorAction SilentlyContinue)
    $added   = ($linesB | Where-Object { $linesA -notcontains $_ }).Count
    $removed = ($linesA | Where-Object { $linesB -notcontains $_ }).Count
    return $added, $removed
}

function Invoke-TemplateDriftReport($toolkitPath, $projectPath) {
    $srcDir = Join-Path $toolkitPath "templates"
    $dstDir = Join-Path $projectPath ".forge\templates"

    if (-not (Test-Path $srcDir)) {
        Write-Info "No templates directory found in toolkit — skipping drift report."
        return
    }
    if (-not (Test-Path $dstDir)) {
        Write-Info "No .forge/templates in project — run '#init' in Copilot Chat to scaffold."
        return
    }

    $report = [System.Collections.Generic.List[PSCustomObject]]::new()

    Get-ChildItem -Path $srcDir -Filter "*.md" -File | ForEach-Object {
        $name    = $_.Name
        $srcFile = $_.FullName
        $dstFile = Join-Path $dstDir $name
        $srcHash = Get-MD5Hash $srcFile
        $dstHash = Get-MD5Hash $dstFile

        if ($null -eq $dstHash) {
            $report.Add([PSCustomObject]@{
                Template = $name; "+Lines" = "-"; "-Lines" = "-"
                Status   = "🆕 New"; Action = "Added automatically"
            })
        } elseif ($srcHash -eq $dstHash) {
            $report.Add([PSCustomObject]@{
                Template = $name; "+Lines" = "-"; "-Lines" = "-"
                Status   = "✅ In sync"; Action = "None"
            })
        } else {
            $added, $removed = Get-DiffStats $dstFile $srcFile
            $action = if ($added -gt 10 -or $removed -gt 10) {
                "Run #template-drift to review"
            } else {
                "Likely cosmetic — run #template-drift"
            }
            $report.Add([PSCustomObject]@{
                Template = $name; "+Lines" = "+$added"; "-Lines" = "-$removed"
                Status   = "⚠️ Drifted"; Action = $action
            })
        }
    }

    Get-ChildItem -Path $dstDir -Filter "*.md" -File | ForEach-Object {
        if (-not (Test-Path (Join-Path $srcDir $_.Name))) {
            $report.Add([PSCustomObject]@{
                Template = $_.Name; "+Lines" = "-"; "-Lines" = "-"
                Status   = "🔒 Custom"; Action = "Untouched (your addition)"
            })
        }
    }

    Write-Header "Template Drift Health Report"
    $report | Format-Table -AutoSize | Out-String | Write-Host

    $driftCount = ($report | Where-Object { $_.Status -like "*Drifted*" }).Count
    if ($driftCount -gt 0) {
        Write-Warn "$driftCount drifted template(s) detected."
        Write-Warn "Run  #template-drift  in Copilot Chat for guided per-file reconciliation."
    } else {
        Write-Ok "All templates are in sync or intentionally custom."
    }
}

function Get-NewChangelog($toolkitPath, $fromVersion) {
    $readme = Join-Path $toolkitPath "README.md"
    if (-not (Test-Path $readme)) { return @() }

    $lines   = Get-Content $readme
    $entries = [System.Collections.Generic.List[string]]::new()
    $capture = $false

    foreach ($line in $lines) {
        if ($line -match "[-–]\s*\*{0,2}(v\d+\.\d+\.\d+)\*{0,2}") {
            $ver = $Matches[1]
            if ($fromVersion -ne "unknown" -and $ver -eq $fromVersion) { break }
            $capture = $true
        }
        if ($capture) { $entries.Add($line) }
        if ($entries.Count -ge 30) { break }
    }
    return $entries
}

function Update-Repo($toolkitPath, $projectPath, $toolkitVersion) {
    $projectPath = (Resolve-Path $projectPath).Path
    Write-Header "Updating → $projectPath"

    $installedVersion = Get-InstalledVersion $projectPath
    Write-Info "Installed : $installedVersion   |   Toolkit : $toolkitVersion"

    if ($installedVersion -eq $toolkitVersion -and $installedVersion -ne "unknown") {
        Write-Ok "Already at $toolkitVersion — nothing to sync."
        return
    }

    $changelog = Get-NewChangelog $toolkitPath $installedVersion
    if ($changelog.Count -gt 0) {
        Write-Header "What's New (since $installedVersion)"
        $changelog | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    }

    if ($DryRun) { Write-Warn "DRY RUN — no files will be written." }

    if (-not $Force -and -not $DryRun) {
        $ok = Read-Host "  Proceed with update? [Y/n]"
        if ($ok -and $ok.ToLower() -ne "y") { Write-Warn "Skipped."; return }
    }

    $backupDir = $null
    if (-not $DryRun -and -not $NoBackup) {
        $backupDir = New-Backup $projectPath
    }

    $stats = [ref]@{ Added=0; Updated=0; Identical=0; Skipped=0 }
    $log   = [ref][System.Collections.Generic.List[PSCustomObject]]::new()

    Sync-Directory $toolkitPath $projectPath ".github"  $stats $log
    Sync-Directory $toolkitPath $projectPath ".vscode"  $stats $log
    Sync-Directory $toolkitPath $projectPath "scripts"  $stats $log

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
            Write-Info "Version stamped: $toolkitVersion → .forge/.forge-version"
        }
    }

    Invoke-TemplateDriftReport $toolkitPath $projectPath

    Write-Header "Update Summary — $projectPath"
    Write-Host "  $installedVersion  →  $toolkitVersion" -ForegroundColor White
    Write-Host "  🆕 Added     : $($stats.Value.Added)"    -ForegroundColor $(if($stats.Value.Added   -gt 0){"Magenta"}else{"DarkGray"})
    Write-Host "  ✏️  Updated   : $($stats.Value.Updated)"  -ForegroundColor $(if($stats.Value.Updated -gt 0){"Yellow"} else{"DarkGray"})
    Write-Host "  ✅ Unchanged : $($stats.Value.Identical)" -ForegroundColor DarkGray
    Write-Host "  ⏭️  Skipped   : $($stats.Value.Skipped)"  -ForegroundColor $(if($stats.Value.Skipped -gt 0){"Red"}   else{"DarkGray"})

    if ($null -ne $backupDir) {
        Write-Host "  💾 Backup    : $backupDir" -ForegroundColor DarkGray
        Write-Host "  ↩️  Rollback  : .\update.ps1 -Restore `"$backupDir`" -TargetDir `"$projectPath`"" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor White
    Write-Host "    1. Run  #template-drift  in Copilot Chat — review drifted templates." -ForegroundColor Gray
    Write-Host "    2. Run  #init            to apply any new context structure migrations." -ForegroundColor Gray
    Write-Host "    3. Reload VS Code window to pick up new/updated prompt files." -ForegroundColor Gray
    if ($stats.Value.Skipped -gt 0) {
        Write-Host "    4. Manually review skipped protected files — they were NOT overwritten." -ForegroundColor Yellow
    }
    Write-Host ""
}

$ToolkitDir = $PSScriptRoot

Write-Host ""
Write-Host "  ⚒️  Copilot Forge Updater" -ForegroundColor Cyan
Write-Host "  Toolkit → $ToolkitDir" -ForegroundColor DarkGray
if ($DryRun)   { Write-Host "  [DRY RUN — no files will be written]" -ForegroundColor Yellow }
if ($NoBackup) { Write-Warn "Backups disabled (-NoBackup). No rollback will be possible." }

if ($Restore -ne "") {
    Invoke-Restore $Restore $TargetDir[0]
    exit 0
}

if (-not (Test-Path (Join-Path $ToolkitDir ".github"))) {
    Write-Err "This directory does not look like a copilot-forge toolkit (.github not found)."
    Write-Err "Run update.ps1 from the copilot-forge toolkit root directory."
    exit 1
}

if (-not $SkipGitPull) {
    Write-Header "Pulling latest toolkit"
    $pullBranch = if ($Branch) { $Branch } else { Get-DefaultBranch $ToolkitDir }
    Write-Info "Branch: $pullBranch"
    Push-Location $ToolkitDir
    try {
        $out = git pull origin $pullBranch 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Ok "Pulled successfully." }
        else                     { Write-Warn "git pull failed — using local state." }
        Write-Host "    $out" -ForegroundColor DarkGray
    } catch {
        Write-Warn "git not available — using local state."
    } finally {
        Pop-Location
    }
} else {
    Write-Info "Skipping git pull (-SkipGitPull)."
}

$toolkitVersion = Get-ToolkitVersion $ToolkitDir
Write-Info "Toolkit version: $toolkitVersion"

foreach ($target in $TargetDir) {
    $target = $target.Trim()
    if (-not (Test-Path $target)) {
        Write-Err "Target not found: $target — skipping."
        continue
    }
    Update-Repo $ToolkitDir $target $toolkitVersion
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  Done." -ForegroundColor Green
Write-Host ""