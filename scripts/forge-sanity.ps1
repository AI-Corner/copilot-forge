<#
.SYNOPSIS
    Copilot Forge — Comprehensive Sanity Check Script

.DESCRIPTION
    Runs all deterministic sanity checks for the Copilot Forge toolkit and
    outputs a summary report. Checks cover:
      1.  Prompt frontmatter validity (agent, tools, description fields)
      2.  Duplicate section detection in prompt files
      3.  Agent prompt opening delimiter (---)
      4.  Template file presence
      5.  Context file presence (corpus + rules)
      6.  Knowledge index integrity (support/_index.md vs disk)
      7.  Script file presence
      8.  Knowledge doc frontmatter (id, title, tags)
      9.  Encoding check (mojibake U+FFFD)
      10. Ethos reference in all main prompts

    AI-agent checks (misclassification, drift, analyze) cannot be automated
    here — see SANITY-CHECKS.md Section 2 for those.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to current directory.

.PARAMETER OutputReport
    If set, writes the report to sanity-checks/sanity-check-report-<date>.md

.EXAMPLE
    .\forge-sanity.ps1
    .\forge-sanity.ps1 -OutputReport
#>

param(
    [string]$RepoRoot    = (Get-Location).Path,
    [switch]$OutputReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$date      = Get-Date -Format "yyyy-MM-dd"
$divider   = "=" * 60
$pass      = 0
$fail      = 0
$warn      = 0
$reportLines = [System.Collections.Generic.List[string]]::new()

function Write-Report([string]$line) {
    $reportLines.Add($line)
    Write-Host $line
}

function Pass([string]$msg) {
    $script:pass++
    Write-Report "  [PASS]  $msg"
}

function Fail([string]$msg) {
    $script:fail++
    Write-Report "  [FAIL]  $msg"
}

function Warn([string]$msg) {
    $script:warn++
    Write-Report "  [WARN]  $msg"
}

function Section([string]$title) {
    Write-Report ""
    Write-Report $divider
    Write-Report "  CHECK: $title"
    Write-Report $divider
}

# ─────────────────────────────────────────────
Write-Report "# Copilot Forge — Sanity Check Report"
Write-Report "> Date: $date | Root: $RepoRoot"
Write-Report ""

# ─────────────────────────────────────────────
# CHECK 1: Prompt frontmatter validity
# ─────────────────────────────────────────────
Section "1. Prompt Frontmatter Validity"

$promptsDir = Join-Path $RepoRoot ".github\prompts"
$mainPrompts = Get-ChildItem $promptsDir -Filter "*.prompt.md" -File -ErrorAction SilentlyContinue

foreach ($f in $mainPrompts) {
    $lines = Get-Content $f.FullName -ErrorAction SilentlyContinue
    $name  = $f.Name

    if ($lines.Count -lt 1 -or $lines[0].Trim() -ne "---") {
        Fail "$name - line 1 is not '---' (frontmatter missing or misplaced)"
        continue
    }
    $hasAgent       = $lines | Where-Object { $_ -match '^agent\s*:' }
    $hasTools       = $lines | Where-Object { $_ -match '^tools\s*:' }
    $hasDescription = $lines | Where-Object { $_ -match '^description\s*:' }

    if (-not $hasAgent)       { Fail "$name - missing 'agent:' field" }
    elseif (-not $hasTools)   { Fail "$name - missing 'tools:' field" }
    elseif (-not $hasDescription) { Fail "$name - missing 'description:' field" }
    else                          { Pass "$name - frontmatter OK" }
}

# ─────────────────────────────────────────────
# CHECK 2: Duplicate section detection
# ─────────────────────────────────────────────
Section "2. Duplicate Phase/Section Detection in Prompts"

foreach ($f in $mainPrompts) {
    $lines    = Get-Content $f.FullName -ErrorAction SilentlyContinue
    $headers  = $lines | Where-Object { $_ -match "^## " }
    $dupes    = $headers | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupes) {
        $dupeNames = ($dupes | ForEach-Object { $_.Name }) -join "; "
        Fail "$($f.Name) — duplicate section headers: $dupeNames"
    } else {
        Pass "$($f.Name) — no duplicate sections"
    }
}

# ─────────────────────────────────────────────
# CHECK 3: Agent prompt opening delimiter
# ─────────────────────────────────────────────
Section "3. Agent Prompt Opening Delimiter (---)"

$agentDirs = @(
    (Join-Path $promptsDir "agents"),
    (Join-Path $promptsDir "agents\computational"),
    (Join-Path $promptsDir "agents\inferential")
)

foreach ($dir in $agentDirs) {
    if (-not (Test-Path $dir)) { Warn "Agent dir not found: $dir"; continue }
    $agents = Get-ChildItem $dir -Filter "*.prompt.md" -File -ErrorAction SilentlyContinue
    foreach ($a in $agents) {
        $firstLines = Get-Content $a.FullName -First 1 -ErrorAction SilentlyContinue
        $first = if ($firstLines) { $firstLines } else { "" }
        if ($first.Trim() -ne "---") {
            Warn "$($a.Name) - line 1 is not '---' (lenient parser may still work)"
        } else {
            Pass "$($a.Name) - delimiter OK"
        }
    }
}

# ─────────────────────────────────────────────
# CHECK 4: Template file presence
# ─────────────────────────────────────────────
Section "4. Template File Presence"

$expectedTemplates = @(
    "requirement-template.md", "task-template.md", "bug-template.md",
    "lesson-template.md", "assumption-template.md", "config-template.yml",
    "support-template.md", "inbox-template.md"
)
$templatesDir = Join-Path $RepoRoot "templates"

foreach ($t in $expectedTemplates) {
    $path = Join-Path $templatesDir $t
    if (Test-Path $path) { Pass "templates/$t — found" }
    else                 { Fail "templates/$t — MISSING" }
}

# ─────────────────────────────────────────────
# CHECK 5: Context file presence
# ─────────────────────────────────────────────
Section "5. Context File Presence (corpus + rules)"

$expectedCorpus = @("architecture.md", "conventions.md", "variables.md")
$expectedRules  = @("architecture.rules.md", "conventions.rules.md", "deployment.rules.md", "security.rules.md")
$corpusDir      = Join-Path $RepoRoot ".forge\context\corpus"
$rulesDir       = Join-Path $RepoRoot ".forge\context\rules"

foreach ($f in $expectedCorpus) {
    $p = Join-Path $corpusDir $f
    if (Test-Path $p) { Pass "corpus/$f — found" }
    else              { Fail "corpus/$f — MISSING" }
}
foreach ($f in $expectedRules) {
    $p = Join-Path $rulesDir $f
    if (Test-Path $p) { Pass "rules/$f — found" }
    else              { Fail "rules/$f — MISSING" }
}

# ─────────────────────────────────────────────
# CHECK 6: Knowledge index integrity
# ─────────────────────────────────────────────
Section "6. Knowledge Index Integrity (support/_index.md vs disk)"

$indexPath   = Join-Path $RepoRoot ".forge\knowledge\support\_index.md"
$supportDir  = Join-Path $RepoRoot ".forge\knowledge\support"

if (-not (Test-Path $indexPath)) {
    Fail "_index.md not found at $indexPath"
} else {
    $indexContent = Get-Content $indexPath -Raw
    # Extract linked filenames like [SUP-001: ...](SUP-001-init.md)
    $linkedFiles = [regex]::Matches($indexContent, '\]\(([^)]+\.md)\)') | ForEach-Object { $_.Groups[1].Value }
    foreach ($linked in $linkedFiles) {
        $linkedPath = Join-Path $supportDir $linked
        if (Test-Path $linkedPath) { Pass "_index.md link '$linked' — file exists" }
        else                       { Fail "_index.md link '$linked' — FILE MISSING on disk" }
    }
    # Check for files on disk not in index
    $diskFiles = Get-ChildItem $supportDir -Filter "*.md" -File | Where-Object { $_.Name -ne "_index.md" }
    foreach ($d in $diskFiles) {
        if ($d.Name -notin $linkedFiles) {
            Warn "$($d.Name) exists on disk but is NOT listed in _index.md"
        }
    }
}

# ─────────────────────────────────────────────
# CHECK 7: Script file presence
# ─────────────────────────────────────────────
Section "7. Script File Presence"

$expectedScripts = @(
    "forge-gate.ps1", "forge-context.ps1", "forge-test.ps1",
    "generate-graph.ps1", "install.ps1", "token-estimate.ps1", "update.ps1"
)
$scriptsDir = Join-Path $RepoRoot "scripts"

foreach ($s in $expectedScripts) {
    $p = Join-Path $scriptsDir $s
    if (Test-Path $p) { Pass "scripts/$s — found" }
    else              { Fail "scripts/$s — MISSING" }
}

# ─────────────────────────────────────────────
# CHECK 8: Knowledge doc frontmatter
# ─────────────────────────────────────────────
Section "8. Knowledge Doc Frontmatter (id, title, tags)"

$knowledgeDirs = @(
    (Join-Path $RepoRoot ".forge\knowledge\lessons"),
    (Join-Path $RepoRoot ".forge\knowledge\support")
)

foreach ($dir in $knowledgeDirs) {
    if (-not (Test-Path $dir)) { Warn "Knowledge dir not found: $dir"; continue }
    $docs = Get-ChildItem $dir -Filter "*.md" -File | Where-Object { $_.Name -ne "_index.md" }
    foreach ($d in $docs) {
        $content = Get-Content $d.FullName -Raw -ErrorAction SilentlyContinue
        $hasId    = $content -match '(?m)^id\s*:'
        $hasTitle = $content -match '(?m)^title\s*:'
        $hasTags  = $content -match '(?m)^tags\s*:'
        if (-not $hasId -or -not $hasTitle -or -not $hasTags) {
            $missing = @()
            if (-not $hasId)    { $missing += 'id' }
            if (-not $hasTitle) { $missing += 'title' }
            if (-not $hasTags)  { $missing += 'tags' }
            Fail "$($d.Name) - missing frontmatter fields: $($missing -join ', ')"
        } else {
            Pass "$($d.Name) - frontmatter OK"
        }
    }
}

# ─────────────────────────────────────────────
# CHECK 9: Encoding check (mojibake U+FFFD)
# ─────────────────────────────────────────────
Section "9. Encoding Check (mojibake U+FFFD)"

$allMd = Get-ChildItem $RepoRoot -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch "\\.git\\" }

foreach ($f in $allMd) {
    $raw = [System.IO.File]::ReadAllText($f.FullName)
    if ($raw.Contains([char]0xFFFD)) {
        Fail "$($f.Name) — contains Unicode replacement char (U+FFFD) — run fix-encoding.ps1"
    }
}
if ($fail -eq 0) { Pass "No mojibake found across all markdown files" }

# ─────────────────────────────────────────────
# CHECK 10: Ethos reference in main prompts
# ─────────────────────────────────────────────
Section "10. Ethos Reference in Main Prompts"

foreach ($f in $mainPrompts) {
    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "copilot-instructions\.md") {
        Pass "$($f.Name) — ethos reference found"
    } else {
        Warn "$($f.Name) — no reference to copilot-instructions.md"
    }
}

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
Write-Report ""
Write-Report $divider
Write-Report "  SUMMARY"
Write-Report $divider
Write-Report "  [PASS]  $pass"
    Write-Report "  [FAIL]  $fail"
    Write-Report "  [WARN]  $warn"
Write-Report ""
if ($fail -gt 0) {
    Write-Report "  [FAIL] SANITY CHECK FAILED -- fix blockers above before merging."
} elseif ($warn -gt 0) {
    Write-Report "  [WARN] PASSED with warnings -- review warnings above."
} else {
    Write-Report "  [PASS] ALL CHECKS PASSED -- toolkit is healthy."
}
Write-Report ""
Write-Report "─────────────────────────────────────────────────────────"
Write-Report "  AI-AGENT CHECKS - run these in Copilot Chat:"
Write-Report "  A. #forge-admin (knowledge misclassification audit)"
Write-Report "  B. #forge-template-drift (template drift)"
Write-Report "  C. #forge-check-drift (convention drift)"
Write-Report "  D. #forge-analyze (incremental analysis)"
Write-Report "  See SANITY-CHECKS.md Section 2 for exact prompts."
Write-Report "─────────────────────────────────────────────────────────"
Write-Report ""

# ─────────────────────────────────────────────
# OUTPUT REPORT
# ─────────────────────────────────────────────
if ($OutputReport) {
    $outDir  = Join-Path $RepoRoot "sanity-checks"
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
    $outFile = Join-Path $outDir "sanity-check-report-$date.md"
    $reportLines | Set-Content -Path $outFile -Encoding UTF8
    Write-Host ""
    Write-Host "  Report saved to: $outFile" -ForegroundColor Cyan
}

# Exit with error code so CI can detect failures
if ($fail -gt 0) { exit 1 }
