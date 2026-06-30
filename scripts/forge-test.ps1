<#
.SYNOPSIS
    Copilot Forge — Autonomous Test Runner

.DESCRIPTION
    Detects the project's test runner, executes the test suite, parses structured
    output, and writes a token-efficient failure summary to .forge/.last-test-run.md.

    Designed to be called by the #forge-tdd agent to enable a true red-green-refactor
    loop without requiring the user to relay test results manually.

    Supported test runners (auto-detected):
      - npm / Vitest / Jest  (package.json)
      - Maven / JUnit        (pom.xml)
      - Gradle               (build.gradle)
      - pytest               (pyproject.toml / setup.py)

.PARAMETER ReqId
    Optional. If provided, links the test run to the REQ in the output summary.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to the current directory.

.PARAMETER MaxFailures
    Maximum number of individual failure details to include in the summary.
    Defaults to 10. Capped to keep summary token-efficient.

.EXAMPLE
    .\forge-test.ps1
    .\forge-test.ps1 -ReqId REQ-003
    .\forge-test.ps1 -ReqId REQ-003 -MaxFailures 5
#>

param(
    [string]$ReqId = "",
    [string]$RepoRoot = (Get-Location).Path,
    [int]$MaxFailures = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$forgeDir   = Join-Path $RepoRoot ".forge"
$outputFile = Join-Path $forgeDir ".last-test-run.md"

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

function Write-Header([string]$msg) {
    Write-Host ""
    Write-Host "  [FORGE-TEST] $msg" -ForegroundColor Cyan
}

function Write-Step([string]$msg) {
    Write-Host "  > $msg" -ForegroundColor DarkGray
}

function Write-Ok([string]$msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Fail([string]$msg) {
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
}

# ─────────────────────────────────────────────
# Detect test runner
# ─────────────────────────────────────────────

Write-Header "Detecting test runner..."

$runner      = $null
$runCmd      = $null
$parseMode   = $null

if (Test-Path (Join-Path $RepoRoot "package.json")) {
    $pkg = Get-Content (Join-Path $RepoRoot "package.json") -Raw | ConvertFrom-Json
    $scripts = $pkg.scripts
    if ($scripts -and $scripts.PSObject.Properties["test"]) {
        $runCmd   = "npm test -- --reporter=json 2>&1"
        $runner   = "npm/jest-vitest"
        $parseMode = "json"
    }
    Write-Step "Detected: $runner (package.json)"
}
elseif (Test-Path (Join-Path $RepoRoot "pom.xml")) {
    $runCmd    = "mvn test -q 2>&1"
    $runner    = "maven"
    $parseMode = "text"
    Write-Step "Detected: Maven (pom.xml)"
}
elseif (Test-Path (Join-Path $RepoRoot "build.gradle")) {
    $runCmd    = "./gradlew test 2>&1"
    $runner    = "gradle"
    $parseMode = "text"
    Write-Step "Detected: Gradle (build.gradle)"
}
elseif ((Test-Path (Join-Path $RepoRoot "pyproject.toml")) -or (Test-Path (Join-Path $RepoRoot "setup.py"))) {
    $runCmd    = "pytest --tb=short -q 2>&1"
    $runner    = "pytest"
    $parseMode = "text"
    Write-Step "Detected: pytest"
}
else {
    Write-Warning "No supported test runner detected. Add test runner config to run tests autonomously."
    $runCmd    = $null
}

if (-not $runCmd) {
    $summary = @"
---
req: $ReqId
runner: unknown
status: skipped
timestamp: $(Get-Date -Format 'o')
---

## Test Run: SKIPPED

No supported test runner was detected in the repository root.

**Action required**: Configure a test runner (npm test, mvn test, pytest, etc.) and re-run `forge-test.ps1`.
"@
    $summary | Set-Content $outputFile -Encoding UTF8
    Write-Warning "Output written to $outputFile"
    exit 0
}

# ─────────────────────────────────────────────
# Run tests
# ─────────────────────────────────────────────

Write-Header "Running: $runCmd"

$startTime = Get-Date
Push-Location $RepoRoot

$rawOutput = ""
try {
    $rawOutput = Invoke-Expression $runCmd
    $exitCode  = $LASTEXITCODE
}
catch {
    $rawOutput = $_.Exception.Message
    $exitCode  = 1
}
finally {
    Pop-Location
}

$durationMs = [int](((Get-Date) - $startTime).TotalMilliseconds)

# ─────────────────────────────────────────────
# Parse output into token-efficient summary
# ─────────────────────────────────────────────

Write-Header "Parsing results..."

$totalTests  = 0
$passed      = 0
$failed      = 0
$skipped     = 0
$failures    = [System.Collections.Generic.List[string]]::new()

if ($parseMode -eq "json") {
    # Jest/Vitest --reporter=json outputs a JSON blob at the end
    $jsonLine = ($rawOutput | Select-String -Pattern '^\{.*"testResults".*\}$').Line
    if ($jsonLine) {
        try {
            $result = $jsonLine | ConvertFrom-Json
            $totalTests = $result.numTotalTests
            $passed     = $result.numPassedTests
            $failed     = $result.numFailedTests
            $skipped    = $result.numPendingTests

            foreach ($suite in $result.testResults) {
                foreach ($test in $suite.testResults) {
                    if ($test.status -eq "failed") {
                        $name = $test.fullName
                        $msg  = ($test.failureMessages -join " ") -replace "`n"," " -replace "\s+"," "
                        if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 200) + "..." }
                        $failures.Add("- **$name** — $msg")
                        if ($failures.Count -ge $MaxFailures) { break }
                    }
                }
                if ($failures.Count -ge $MaxFailures) { break }
            }
        }
        catch {
            Write-Warning "JSON parse failed, falling back to text parsing."
            $parseMode = "text"
        }
    }
    else {
        $parseMode = "text"
    }
}

if ($parseMode -eq "text") {
    # Heuristic text parsing for Maven/Gradle/pytest output
    $lines = $rawOutput -split "`n"

    # Maven: "Tests run: X, Failures: Y, Errors: Z, Skipped: W"
    $mavenSummary = $lines | Select-String -Pattern "Tests run:\s*(\d+),\s*Failures:\s*(\d+)"
    if ($mavenSummary) {
        foreach ($m in $mavenSummary) {
            if ($m.Line -match "Tests run:\s*(\d+),\s*Failures:\s*(\d+),\s*Errors:\s*(\d+),\s*Skipped:\s*(\d+)") {
                $totalTests += [int]$Matches[1]
                $failed     += [int]$Matches[2] + [int]$Matches[3]
                $skipped    += [int]$Matches[4]
            }
        }
        $passed = $totalTests - $failed - $skipped
    }

    # pytest: "X passed, Y failed, Z error"
    $pytestSummary = $lines | Select-String -Pattern "(\d+) passed"
    if ($pytestSummary) {
        if ($pytestSummary.Line -match "(\d+) passed") { $passed = [int]$Matches[1] }
        if ($pytestSummary.Line -match "(\d+) failed") { $failed = [int]$Matches[1] }
        $totalTests = $passed + $failed
    }

    # Extract FAILED lines (Maven, Gradle, pytest all emit these)
    $failLines = $lines | Where-Object { $_ -match "FAILED|ERROR|AssertionError|expected|but was" }
    foreach ($line in $failLines) {
        $clean = $line.Trim() -replace "\s+", " "
        if ($clean.Length -gt 200) { $clean = $clean.Substring(0, 200) + "..." }
        if ($clean -ne "" -and $failures.Count -lt $MaxFailures) {
            $failures.Add("- $clean")
        }
    }
}

# ─────────────────────────────────────────────
# Determine overall status
# ─────────────────────────────────────────────

$status    = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$statusEmoji = if ($status -eq "PASS") { "✅" } else { "❌" }
$truncNote = if ($failures.Count -ge $MaxFailures) { "`n> _Showing first $MaxFailures failures. Run tests locally for full output._" } else { "" }

# ─────────────────────────────────────────────
# Write token-efficient summary
# ─────────────────────────────────────────────

$failureBlock = if ($failures.Count -gt 0) {
    ($failures -join "`n")
} else {
    "_No individual failure details extracted._"
}

$summary = @"
---
req: $ReqId
runner: $runner
status: $status
exit_code: $exitCode
timestamp: $(Get-Date -Format 'o')
duration_ms: $durationMs
total: $totalTests
passed: $passed
failed: $failed
skipped: $skipped
---

## Test Run: $statusEmoji $status

| Metric | Value |
|---|---|
| Runner | ``$runner`` |
| Total | $totalTests |
| ✅ Passed | $passed |
| ❌ Failed | $failed |
| ⏭ Skipped | $skipped |
| Duration | ${durationMs}ms |

## Failures
$failureBlock
$truncNote

## Agent Instructions
$(if ($status -eq "PASS") {
"All tests are passing. The Red Phase is complete — you may now proceed to the Green Phase (implementation)."
} else {
"Fix the failures listed above, then re-run ``.\forge-test.ps1`` to verify. Do NOT proceed to implementation until this file reports status: PASS."
})
"@

if (-not (Test-Path $forgeDir)) { New-Item -ItemType Directory -Path $forgeDir -Force | Out-Null }
$summary | Set-Content $outputFile -Encoding UTF8

# ─────────────────────────────────────────────
# Console output
# ─────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
if ($status -eq "PASS") {
    Write-Ok "All tests passed ($passed / $totalTests) in ${durationMs}ms"
} else {
    Write-Fail "$failed test(s) failed out of $totalTests in ${durationMs}ms"
    Write-Host ""
    foreach ($f in $failures) {
        Write-Host "    $f" -ForegroundColor Yellow
    }
}
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Summary written to: $outputFile" -ForegroundColor DarkGray
Write-Host ""

exit $exitCode

## Internal Reference
- **Incoming Dependencies**: *None*
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*