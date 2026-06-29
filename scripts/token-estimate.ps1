<#
.SYNOPSIS
    Copilot Forge — Token Usage Estimator

.DESCRIPTION
    Estimates token consumption for a Copilot Forge pipeline session by scanning
    all files that would be loaded across each pipeline phase.

    Formula: estimated_tokens = ceil(file_size_bytes / 4)
    (~4 bytes per token is the standard approximation for English/Markdown text)

    Accuracy: ±15–20%. Useful for comparing REQs, not exact billing.

.PARAMETER ReqId
    The requirement ID to estimate (e.g. REQ-023 or 23).
    If omitted, estimates baseline context only.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to current directory.

.PARAMETER OutputJson
    If set, writes the estimate as a JSON block to stdout (for piping).

.PARAMETER UpdatePipelineState
    If set, appends the token estimate to pipeline-state.json for the REQ.

.EXAMPLE
    .\token-estimate.ps1 -ReqId REQ-023
    .\token-estimate.ps1 -ReqId 23 -UpdatePipelineState
    .\token-estimate.ps1 -OutputJson | ConvertFrom-Json
#>

param(
    [string]$ReqId = "",
    [string]$RepoRoot = (Get-Location).Path,
    [switch]$OutputJson,
    [switch]$UpdatePipelineState
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

function Get-Tokens([string]$path) {
    if (Test-Path $path) {
        $bytes = (Get-Item $path).Length
        return [math]::Ceiling($bytes / 4)
    }
    return 0
}

function Get-DirTokens([string]$dir, [string]$pattern = "*") {
    if (-not (Test-Path $dir)) { return 0 }
    $total = 0
    Get-ChildItem $dir -Recurse -File -Filter $pattern | ForEach-Object {
        $total += [math]::Ceiling($_.Length / 4)
    }
    return $total
}

function Get-DirDetails([string]$dir, [string]$pattern = "*", [int]$topN = 0) {
    if (-not (Test-Path $dir)) { return @() }
    $files = Get-ChildItem $dir -Recurse -File -Filter $pattern |
        Sort-Object Length -Descending
    if ($topN -gt 0) { $files = $files | Select-Object -First $topN }
    return $files | ForEach-Object {
        [PSCustomObject]@{
            Name   = $_.Name
            Tokens = [math]::Ceiling($_.Length / 4)
        }
    }
}

function Pad([string]$s, [int]$width) {
    if ($s.Length -ge $width) { return $s.Substring(0, $width) }
    return $s.PadRight($width)
}

function FmtN([int]$n) { return $n.ToString("N0") }

# ─────────────────────────────────────────────
# Normalize REQ ID
# ─────────────────────────────────────────────

$normalizedReqId = ""
$reqSpecDir = ""
$reqTitle = ""

if ($ReqId -ne "") {
    # Normalize: accept "23", "REQ-23", "REQ-023"
    $num = $ReqId -replace "[^0-9]", ""
    $normalizedReqId = "REQ-{0:D3}" -f [int]$num

    # Find the spec directory
    $specsRoot = Join-Path $RepoRoot ".forge\specs"
    $matches = Get-ChildItem $specsRoot -Directory -Filter "$normalizedReqId-*" -ErrorAction SilentlyContinue
    if ($matches.Count -gt 0) {
        $reqSpecDir = $matches[0].FullName
        # Extract title from requirement.md frontmatter
        $reqFile = Join-Path $reqSpecDir "requirement.md"
        if (Test-Path $reqFile) {
            $content = Get-Content $reqFile -Raw
            if ($content -match 'title:\s*"?([^"\r\n]+)"?') {
                $reqTitle = $Matches[1].Trim()
            }
        }
    } else {
        Write-Warning "No spec directory found for $normalizedReqId under $specsRoot"
        Write-Warning "Continuing with baseline context estimate only."
        $normalizedReqId = ""
    }
}

# ─────────────────────────────────────────────
# File paths
# ─────────────────────────────────────────────

$forge    = Join-Path $RepoRoot ".forge"
$context  = Join-Path $forge "context"
$prompts  = Join-Path $RepoRoot ".github\prompts"
$agents   = Join-Path $prompts "agents"
$knowledge = Join-Path $forge "knowledge"

# ─────────────────────────────────────────────
# Phase measurements
# ─────────────────────────────────────────────

# --- Baseline Context (always loaded) ---
$baselineFiles = @(
    (Join-Path $RepoRoot ".github\copilot-instructions.md"),
    (Join-Path $context "project-overview.md"),
    (Join-Path $context "architecture.md"),
    (Join-Path $context "conventions.md"),
    (Join-Path $context "variables.md"),
    (Join-Path $context "taxonomy.md"),
    (Join-Path $context "deployment.md")
)
$tBaseline = ($baselineFiles | ForEach-Object { Get-Tokens $_ } | Measure-Object -Sum).Sum

# --- Prompts per phase ---
$tSpec         = Get-Tokens (Join-Path $prompts "spec.prompt.md")
$tValidate     = Get-Tokens (Join-Path $prompts "validate.prompt.md")
$tArchitect    = Get-Tokens (Join-Path $prompts "architect.prompt.md")
$tTdd          = Get-Tokens (Join-Path $prompts "tdd.prompt.md")
$tProceed      = Get-Tokens (Join-Path $prompts "proceed.prompt.md")
$tReflect      = Get-Tokens (Join-Path $prompts "reflect.prompt.md")
$tReview       = Get-Tokens (Join-Path $prompts "review.prompt.md")
$tWrapup       = Get-Tokens (Join-Path $prompts "wrapup.prompt.md")
$tCanary       = Get-Tokens (Join-Path $prompts "canary.prompt.md")
$tAgents       = Get-DirTokens $agents "*.md"

# --- RAG: top 5 lessons + top 3 support docs (conservative estimate) ---
$lessonsDir = Join-Path $knowledge "lessons"
$supportDir = Join-Path $knowledge "support"
$tRagLessons = (Get-DirDetails $lessonsDir "*.md" -topN 5 | Measure-Object -Property Tokens -Sum).Sum
$tRagSupport = (Get-DirDetails $supportDir "*.md" -topN 3 | Measure-Object -Property Tokens -Sum).Sum
$tRag = $tRagLessons + $tRagSupport

# --- REQ-specific artifacts & Variable source code payload ---
$tReqArtifacts = 0
$tTasks        = 0
$taskCount     = 0
$tSourcePayload = 0
$sourceFilesCount = 0

if ($reqSpecDir -ne "") {
    $reqFile  = Join-Path $reqSpecDir "requirement.md"
    $tasksDir = Join-Path $reqSpecDir "tasks"
    $tReqArtifacts = Get-Tokens $reqFile
    if (Test-Path $tasksDir) {
        $taskFiles = Get-ChildItem $tasksDir -File -Filter "*.md"
        $taskCount = $taskFiles.Count
        $tTasks = ($taskFiles | ForEach-Object { [math]::Ceiling($_.Length / 4) } | Measure-Object -Sum).Sum

        # Estimate variable source code payload based on files listed in tasks
        $sourcePaths = @()
        foreach ($taskFile in $taskFiles) {
            $content = Get-Content $taskFile.FullName -Raw
            # Extract content between ## Files to Create/Modify and the next ##
            if ($content -match "(?s)## Files to Create/Modify\s*(.*?)(?:##|\Z)") {
                $filesSection = $Matches[1]
                # Match lines like `- `path/to/file` — description`
                $pathMatches = [regex]::Matches($filesSection, '(?m)^[-\*]\s+[`"]?([^`" \-]+)[`"]?')
                foreach ($m in $pathMatches) {
                    $sourcePaths += $m.Groups[1].Value
                }
            }
        }
        
        $uniqueSourcePaths = $sourcePaths | Select-Object -Unique
        foreach ($path in $uniqueSourcePaths) {
            # Try to resolve path relative to RepoRoot
            $fullPath = Join-Path $RepoRoot $path
            if (Test-Path $fullPath -PathType Leaf) {
                $tSourcePayload += Get-Tokens $fullPath
                $sourceFilesCount++
            }
        }
    }
}

# ─────────────────────────────────────────────
# Phase totals
# ─────────────────────────────────────────────

# Each phase = baseline loaded once + prompt + relevant REQ files
# (In practice Copilot may cache some; this is the honest upper bound)

$phases = [ordered]@{
    "Step 0: Preflight"       = $tBaseline + $tReqArtifacts
    "Phase 1: Validate Spec"  = $tValidate + $tReqArtifacts
    "Phase 2: Architect"      = $tArchitect + $tBaseline + $tRag
    "Phase 3: Validate Arch"  = $tValidate + $tReqArtifacts + $tTasks
    "Phase 3.5: TDD"          = $tTdd + $tReqArtifacts + $tTasks
    "Phase 4: Implement"      = $tProceed + $tTasks + ($tBaseline * 0.5) + $tSourcePayload # conventions re-read + source code
    "Phase 5: Verify"         = $tReflect + $tReview + $tAgents + $tTasks
    "Phase 6-7: PR + CI"      = [math]::Ceiling($tProceed * 0.25)          # only PR section of proceed
    "Phase 7.5: Canary"       = $tCanary
    "Phase 8: Wrapup"         = $tWrapup + $tRag
}

# Cast all values to int
$phasesInt = [ordered]@{}
foreach ($k in $phases.Keys) {
    $phasesInt[$k] = [int][math]::Ceiling($phases[$k])
}

$totalInput    = ($phasesInt.Values | Measure-Object -Sum).Sum
$estOutput     = [int][math]::Ceiling($totalInput * 0.27)  # ~27% output estimate
$grandTotal    = $totalInput + $estOutput

# Largest phase
$maxPhase = ($phasesInt.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)

# ─────────────────────────────────────────────
# Output
# ─────────────────────────────────────────────

if ($OutputJson) {
    $result = [ordered]@{
        reqId              = $normalizedReqId
        reqTitle           = $reqTitle
        estimatedAt        = (Get-Date -Format "o")
        formula            = "ceil(bytes / 4)"
        taskCount          = $taskCount
        phases             = $phasesInt
        totalInputTokens   = $totalInput
        estimatedOutputTokens = $estOutput
        estimatedGrandTotal   = $grandTotal
        largestPhase       = $maxPhase.Key
        note               = "Approximation only (~4 chars/token). Actual Copilot usage may vary ±20%."
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

# ─── Pretty Table ───────────────────────────────────────────────────────────

$header = if ($normalizedReqId -ne "") {
    "$normalizedReqId - $reqTitle"
} else {
    "Baseline Context Estimate (no REQ specified)"
}

$divider = "-" * 62
Write-Host ""
Write-Host "  [TOKEN ESTIMATE] Copilot Forge" -ForegroundColor Cyan
Write-Host "  $header" -ForegroundColor White
Write-Host "  $divider"
Write-Host ("  {0,-30} {1,12}  {2,6}" -f "Phase", "Est. Tokens", "% Total") -ForegroundColor DarkGray
Write-Host "  $divider"

foreach ($entry in $phasesInt.GetEnumerator()) {
    $pct = if ($totalInput -gt 0) { [math]::Round($entry.Value / $totalInput * 100, 1) } else { 0 }
    $marker = if ($entry.Key -eq $maxPhase.Key) { " << largest" } else { "" }
    Write-Host ("  {0,-30} {1,12}  {2,5}%{3}" -f `
        (Pad $entry.Key 30), (FmtN $entry.Value), $pct, $marker)
}

Write-Host "  $divider"
Write-Host ("  {0,-30} {1,12}  {2,6}" -f "TOTAL Input Tokens", (FmtN $totalInput), "100%") -ForegroundColor Green
Write-Host ("  {0,-30} {1,12}" -f "Est. Output Tokens (~27%)", (FmtN $estOutput)) -ForegroundColor Yellow
Write-Host ("  {0,-30} {1,12}" -f "Est. GRAND TOTAL", (FmtN $grandTotal)) -ForegroundColor Cyan
Write-Host "  $divider"

if ($taskCount -gt 0) {
    Write-Host "  Tasks in REQ: $taskCount" -ForegroundColor DarkGray
}
if ($sourceFilesCount -gt 0) {
    Write-Host "  Source files identified: $sourceFilesCount (~$(FmtN $tSourcePayload) tokens)" -ForegroundColor DarkGray
}
Write-Host "  Accuracy: +/-15-20%  |  Formula: ceil(bytes / 4)" -ForegroundColor DarkGray
Write-Host ""

# --- Insights ---

Write-Host "  >> Insights" -ForegroundColor Cyan
Write-Host ("     Largest phase : {0} (~{1} tokens)" -f $maxPhase.Key, (FmtN $maxPhase.Value))

if ($phasesInt["Phase 5: Verify"] -gt 0) {
    $verifyPct = [math]::Round($phasesInt["Phase 5: Verify"] / $totalInput * 100, 0)
    Write-Host "     Phase 5 (Verify) loads all 6 agent checklists - accounts for ~$verifyPct% of input."
}

if ($tRag -gt 0) {
    Write-Host ("     RAG knowledge retrieval contributes ~{0} tokens (top lessons + support docs)." -f (FmtN $tRag))
}

if ($tSourcePayload -gt 0) {
    Write-Host ("     Variable payload: ~{0} tokens from {1} source files." -f (FmtN $tSourcePayload), $sourceFilesCount)
}

Write-Host ""

# ------------------------------------------
# Optional: Write to pipeline-state.json
# ------------------------------------------

if ($UpdatePipelineState -and $reqSpecDir -ne "") {
    $stateFile = Join-Path $reqSpecDir "pipeline-state.json"
    if (Test-Path $stateFile) {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json

        # Build the token estimate block
        $tokenBlock = [ordered]@{
            estimatedAt           = (Get-Date -Format "o")
            formula               = "ceil(bytes / 4)"
            taskCount             = $taskCount
            phases                = $phasesInt
            totalInputTokens      = $totalInput
            estimatedOutputTokens = $estOutput
            estimatedGrandTotal   = $grandTotal
            note                  = "Approximation only (~4 chars/token). Actual Copilot usage may vary ±20%."
        }

        # Add or overwrite tokenEstimate key
        $stateObj = $state | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $stateObj | Add-Member -NotePropertyName "tokenEstimate" -NotePropertyValue $tokenBlock -Force

        $stateObj | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding UTF8
        Write-Host "  [OK] Token estimate written to: $stateFile" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Warning "pipeline-state.json not found at $stateFile - skipping update."
    }
}

## Internal Reference
- **Incoming Dependencies**: `#forge-token-estimate`, `#forge-wrapup`
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*