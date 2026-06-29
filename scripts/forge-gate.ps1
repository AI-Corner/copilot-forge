<#
.SYNOPSIS
    Copilot Forge — Pipeline State Machine Gate

.DESCRIPTION
    Enforces phase transition rules for the Copilot Forge pipeline.
    Each phase has required pre-conditions that must be satisfied before
    the agent is allowed to proceed. This script makes those rules
    deterministic — enforced in code, not just prompt text.

    Phases and their gates:
      spec      : .forge/context/project-overview.md must exist
      architect : requirement.md must exist with status: draft|approved
      tdd       : requirement.md status: approved + at least 1 TASK-*.md
      reflect   : git diff must be non-empty (there are changes to review)
      review    : git diff must be non-empty (there are changes to review)
      wrapup    : all TASK-*.md files must have status: complete

    On failure, the script exits with code 1 and a human-readable error.
    Use --Force to override a failing gate (logged as a forced transition).

.PARAMETER Phase
    The pipeline phase to gate. Required.
    Allowed values: spec, architect, tdd, reflect, review, wrapup

.PARAMETER ReqId
    Optional. REQ ID to use when locating specs (e.g. REQ-003).
    If omitted, the script finds the most recent requirement.md.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to current directory.

.PARAMETER Force
    If set, bypasses the gate and logs a forced transition warning
    to pipeline-state.json. Use sparingly.

.EXAMPLE
    .\forge-gate.ps1 -Phase architect
    .\forge-gate.ps1 -Phase tdd -ReqId REQ-003
    .\forge-gate.ps1 -Phase wrapup -Force
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet("spec","architect","tdd","reflect","review","wrapup")]
    [string]$Phase,

    [string]$ReqId     = "",
    [string]$RepoRoot  = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$divider = "-" * 56

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

function Pass([string]$msg) {
    Write-Host ""
    Write-Host "  ✓ GATE PASSED [$Phase]" -ForegroundColor Green
    Write-Host "  $msg" -ForegroundColor DarkGray
    Write-Host ""
}

function Fail([string]$msg, [string]$remedy = "") {
    Write-Host ""
    Write-Host "  $divider" -ForegroundColor DarkGray
    Write-Host "  ⛔ GATE FAILED [$Phase]" -ForegroundColor Red
    Write-Host "  $msg" -ForegroundColor Yellow
    if ($remedy) {
        Write-Host ""
        Write-Host "  Remedy: $remedy" -ForegroundColor Cyan
    }
    Write-Host "  $divider" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

function Warn([string]$msg) {
    Write-Host "  ⚠  $msg" -ForegroundColor Yellow
}

function Get-ReqFile {
    $specsRoot = Join-Path $RepoRoot ".forge\specs"
    if (-not (Test-Path $specsRoot)) { return $null }

    if ($ReqId -ne "") {
        $num = $ReqId -replace "[^0-9]", ""
        $normalized = "REQ-{0:D3}" -f [int]$num
        $dir = Get-ChildItem $specsRoot -Directory -Filter "$normalized-*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($dir) { return Get-Item (Join-Path $dir.FullName "requirement.md") -ErrorAction SilentlyContinue }
    }

    # Fall back: find the most recently modified requirement.md
    return Get-ChildItem $specsRoot -Recurse -Filter "requirement.md" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-FrontmatterValue([string]$filePath, [string]$key) {
    $lines = Get-Content $filePath
    foreach ($line in $lines) {
        if ($line -match "^$key\s*:\s*(.+)$") {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ""
}

function Log-ForcedTransition {
    param([string]$reqSpecDir)
    if (-not $reqSpecDir) { return }
    $stateFile = Join-Path $reqSpecDir "pipeline-state.json"
    if (-not (Test-Path $stateFile)) { return }
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        $entry = [PSCustomObject]@{
            phase     = $Phase
            timestamp = (Get-Date -Format "o")
            operator  = $env:USERNAME
            note      = "Gate bypassed with --Force flag"
        }
        if (-not $state.forcedTransitions) {
            $state | Add-Member -NotePropertyName "forcedTransitions" -NotePropertyValue @() -Force
        }
        $state.forcedTransitions += $entry
        $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding UTF8
        Warn "Forced transition logged to pipeline-state.json"
    }
    catch {
        Warn "Could not log forced transition: $_"
    }
}

# ─────────────────────────────────────────────
# Force override path
# ─────────────────────────────────────────────

if ($Force) {
    Warn "FORCE flag set — bypassing gate for phase: $Phase"
    $reqFile = Get-ReqFile
    $reqSpecDir = if ($reqFile) { Split-Path $reqFile.FullName } else { "" }
    Log-ForcedTransition -reqSpecDir $reqSpecDir
    Write-Host "  Proceeding under --Force. This transition has been logged." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# ─────────────────────────────────────────────
# Gate logic per phase
# ─────────────────────────────────────────────

Write-Host ""
Write-Host "  [FORGE-GATE] Checking: $Phase" -ForegroundColor Cyan
Write-Host "  $divider" -ForegroundColor DarkGray

switch ($Phase) {

    "spec" {
        $overview = Join-Path $RepoRoot ".forge\context\project-overview.md"
        if (-not (Test-Path $overview)) {
            Fail ".forge/context/project-overview.md not found." "Run #forge-init to initialize the .forge/ structure."
        }
        Pass "project-overview.md exists. Safe to run #forge-spec."
    }

    "architect" {
        $reqFile = Get-ReqFile
        if (-not $reqFile -or -not (Test-Path $reqFile.FullName)) {
            Fail "No requirement.md found under .forge/specs/." "Run #forge-spec first to create a requirement."
        }
        $status = Get-FrontmatterValue $reqFile.FullName "status"
        if ($status -eq "complete") {
            Fail "Requirement '$($reqFile.Name)' is already complete." "Start a new #forge-spec for a new requirement."
        }
        if ($status -notin @("draft","approved")) {
            Fail "Requirement status is '$status'. Expected: draft or approved." "Check the requirement.md frontmatter."
        }
        Pass "$($reqFile.Name) | status: $status"
    }

    "tdd" {
        $reqFile = Get-ReqFile
        if (-not $reqFile -or -not (Test-Path $reqFile.FullName)) {
            Fail "No requirement.md found." "Run #forge-spec and #forge-architect first."
        }
        $status = Get-FrontmatterValue $reqFile.FullName "status"
        if ($status -ne "approved") {
            Fail "Requirement status is '$status'. Must be 'approved' to write tests." "Run #forge-architect to approve the requirement."
        }
        $taskDir   = Join-Path (Split-Path $reqFile.FullName) "tasks"
        $taskCount = (Get-ChildItem $taskDir -Filter "TASK-*.md" -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($taskCount -eq 0) {
            Fail "No TASK-*.md files found in $taskDir." "Run #forge-architect to generate tasks first."
        }
        Pass "$($reqFile.Name) | status: $status | tasks: $taskCount"
    }

    "reflect" {
        Push-Location $RepoRoot
        $diff = git diff main...HEAD --name-only 2>&1
        Pop-Location
        if ([string]::IsNullOrWhiteSpace($diff)) {
            Fail "No changes detected vs main. Nothing to reflect on." "Make sure you are on a feature branch with committed changes."
        }
        $fileCount = ($diff -split "`n" | Where-Object { $_ -ne "" }).Count
        Pass "$fileCount changed file(s) detected vs main. Safe to reflect."
    }

    "review" {
        Push-Location $RepoRoot
        $diff = git diff main...HEAD --name-only 2>&1
        Pop-Location
        if ([string]::IsNullOrWhiteSpace($diff)) {
            Fail "No changes detected vs main. Nothing to review." "Make sure you are on a feature branch with committed changes."
        }
        $fileCount = ($diff -split "`n" | Where-Object { $_ -ne "" }).Count
        Pass "$fileCount changed file(s) detected vs main. Safe to review."
    }

    "wrapup" {
        $reqFile = Get-ReqFile
        if (-not $reqFile -or -not (Test-Path $reqFile.FullName)) {
            Fail "No requirement.md found. Nothing to wrap up." ""
        }
        $reqStatus = Get-FrontmatterValue $reqFile.FullName "status"
        if ($reqStatus -eq "complete") {
            Warn "Requirement is already marked complete. Proceeding (idempotent wrapup)."
        }
        $taskDir = Join-Path (Split-Path $reqFile.FullName) "tasks"
        $tasks   = Get-ChildItem $taskDir -Filter "TASK-*.md" -ErrorAction SilentlyContinue
        if ($tasks.Count -eq 0) {
            Fail "No task files found in $taskDir." "Run #forge-architect first."
        }
        $incomplete = $tasks | Where-Object {
            (Get-FrontmatterValue $_.FullName "status") -ne "complete"
        }
        if ($incomplete.Count -gt 0) {
            $names = ($incomplete | ForEach-Object { "    - $($_.Name)" }) -join "`n"
            Fail "$($incomplete.Count) task(s) not yet complete:`n$names" "Complete all tasks before running #forge-wrapup."
        }
        Pass "$($tasks.Count) tasks — all complete. Safe to wrap up."
    }
}

## Internal Reference
- **Incoming Dependencies**: `#forge-proceed`, `#forge-admin`, `#forge-architect`
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*