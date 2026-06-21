<#
.SYNOPSIS
    Copilot Forge — Active Context Snapshot Generator

.DESCRIPTION
    Compiles a compact, token-efficient snapshot of the current working state
    into .forge/.active-context.md. This file is designed to be read by the
    agent at the start of every coding interaction to prevent context drift
    during long implementation sessions.

    The snapshot includes:
      - Current task title, description, and acceptance criteria
      - Relevant acceptance criteria from the parent requirement
      - A compact git diff --stat summary
      - A focus reminder

    Freshness rules:
      - Regenerate on every call (idempotent)
      - The agent should call this before starting work on any task
      - Stale after: new commits, task switch, or 30-min idle

.PARAMETER ReqId
    The requirement ID (e.g. REQ-003 or 3). Required.

.PARAMETER TaskId
    The task ID (e.g. TASK-012 or 12). If omitted, shows the REQ-level
    context without task-specific details.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to current directory.

.EXAMPLE
    .\forge-context.ps1 -ReqId REQ-003 -TaskId TASK-012
    .\forge-context.ps1 -ReqId 3
#>

param(
    [Parameter(Mandatory)]
    [string]$ReqId,

    [string]$TaskId   = "",
    [string]$RepoRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$forgeDir   = Join-Path $RepoRoot ".forge"
$outputFile = Join-Path $forgeDir ".active-context.md"

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

function Normalize-Id([string]$raw, [string]$prefix) {
    $num = $raw -replace "[^0-9]", ""
    if ($num -eq "") { return $raw }
    return "{0}-{1:D3}" -f $prefix, [int]$num
}

function Get-FrontmatterBlock([string]$filePath) {
    $lines = Get-Content $filePath
    $inFm = $false
    $fm = @{}
    foreach ($line in $lines) {
        if ($line -match "^---\s*$") {
            if ($inFm) { break }
            $inFm = $true
            continue
        }
        if ($inFm -and $line -match "^(\w[\w\-]*):\s*(.+)$") {
            $fm[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
        }
    }
    return $fm
}

function Get-SectionContent([string]$filePath, [string]$heading) {
    $lines = Get-Content $filePath
    $capture = $false
    $result = @()
    foreach ($line in $lines) {
        if ($line -match "^##\s+$heading") {
            $capture = $true
            continue
        }
        if ($capture -and $line -match "^##\s+") {
            break
        }
        if ($capture) {
            $result += $line
        }
    }
    return ($result -join "`n").Trim()
}

# ─────────────────────────────────────────────
# Locate artifacts
# ─────────────────────────────────────────────

$normalizedReq = Normalize-Id $ReqId "REQ"
$specsRoot     = Join-Path $RepoRoot ".forge\specs"

$reqDir = Get-ChildItem $specsRoot -Directory -Filter "$normalizedReq-*" -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $reqDir) {
    Write-Error "No spec directory found for $normalizedReq under $specsRoot"
    exit 1
}

$reqFile = Join-Path $reqDir.FullName "requirement.md"
if (-not (Test-Path $reqFile)) {
    Write-Error "requirement.md not found in $($reqDir.FullName)"
    exit 1
}

$reqFm = Get-FrontmatterBlock $reqFile
$reqTitle  = if ($reqFm["title"]) { $reqFm["title"] } else { $normalizedReq }
$reqStatus = if ($reqFm["status"]) { $reqFm["status"] } else { "unknown" }

# Extract acceptance criteria from requirement
$acceptanceCriteria = Get-SectionContent $reqFile "Acceptance Criteria"
if ([string]::IsNullOrWhiteSpace($acceptanceCriteria)) {
    $acceptanceCriteria = "_No acceptance criteria found in requirement.md._"
}

# ─────────────────────────────────────────────
# Locate task (optional)
# ─────────────────────────────────────────────

$taskSection = ""
if ($TaskId -ne "") {
    $normalizedTask = Normalize-Id $TaskId "TASK"
    $taskDir = Join-Path $reqDir.FullName "tasks"
    $taskFile = Get-ChildItem $taskDir -Filter "$normalizedTask-*.md" -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($taskFile) {
        $taskFm = Get-FrontmatterBlock $taskFile.FullName
        $taskTitle  = if ($taskFm["title"]) { $taskFm["title"] } else { $normalizedTask }
        $taskStatus = if ($taskFm["status"]) { $taskFm["status"] } else { "unknown" }
        $taskDeps   = if ($taskFm["dependencies"]) { $taskFm["dependencies"] } else { "none" }

        $taskDesc = Get-SectionContent $taskFile.FullName "Description"
        if ([string]::IsNullOrWhiteSpace($taskDesc)) { $taskDesc = "_No description._" }

        $taskAC = Get-SectionContent $taskFile.FullName "Acceptance Criteria"
        if ([string]::IsNullOrWhiteSpace($taskAC)) { $taskAC = "_See requirement-level acceptance criteria above._" }

        $taskFiles = Get-SectionContent $taskFile.FullName "Files to Create/Modify"
        if ([string]::IsNullOrWhiteSpace($taskFiles)) { $taskFiles = "_Not specified._" }

        $taskSection = @"

## Current Task: $normalizedTask

| Field | Value |
|---|---|
| Title | $taskTitle |
| Status | $taskStatus |
| Dependencies | $taskDeps |

### Description
$taskDesc

### Task Acceptance Criteria
$taskAC

### Files to Create/Modify
$taskFiles
"@
    }
    else {
        $taskSection = "`n## Current Task: $normalizedTask`n`n_Task file not found._"
    }
}

# ─────────────────────────────────────────────
# Git diff summary
# ─────────────────────────────────────────────

Push-Location $RepoRoot
$diffStat = git diff main...HEAD --stat 2>&1
$branch   = git branch --show-current 2>&1
Pop-Location

if ([string]::IsNullOrWhiteSpace($diffStat)) {
    $diffStat = "_No changes detected vs main._"
}

# ─────────────────────────────────────────────
# Compose snapshot
# ─────────────────────────────────────────────

$snapshot = @"
---
generated: $(Get-Date -Format 'o')
req: $normalizedReq
task: $(if ($TaskId) { Normalize-Id $TaskId "TASK" } else { "none" })
branch: $branch
---

# Active Context Snapshot

> **Focus**: You are implementing **$normalizedReq: $reqTitle**. Only use `.forge/context/*.md`, this snapshot, and the current code. Ignore earlier chat history.

## Requirement: $normalizedReq

| Field | Value |
|---|---|
| Title | $reqTitle |
| Status | $reqStatus |

### Acceptance Criteria
$acceptanceCriteria
$taskSection

## Working State

### Branch
``$branch``

### Changes vs main
``````
$diffStat
``````

---

> This file is auto-generated by ``forge-context.ps1``. Regenerate with:
> ``.\forge-context.ps1 -ReqId $normalizedReq $(if ($TaskId) { "-TaskId $(Normalize-Id $TaskId 'TASK')" })``
"@

if (-not (Test-Path $forgeDir)) { New-Item -ItemType Directory -Path $forgeDir -Force | Out-Null }
$snapshot | Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "  [FORGE-CONTEXT] Snapshot generated" -ForegroundColor Cyan
Write-Host "  REQ:    $normalizedReq — $reqTitle" -ForegroundColor White
if ($TaskId -ne "") {
    Write-Host "  TASK:   $(Normalize-Id $TaskId 'TASK')" -ForegroundColor White
}
Write-Host "  Branch: $branch" -ForegroundColor DarkGray
Write-Host "  Output: $outputFile" -ForegroundColor DarkGray
Write-Host ""

## Internal Reference
- **Incoming Dependencies**: *None*
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*