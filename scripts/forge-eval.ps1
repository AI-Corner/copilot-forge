<#
.SYNOPSIS
Forge Evaluation Harness - Pre-release agent validation.

.DESCRIPTION
Orchestrates structural, behavioral, and semantic tests against Copilot Forge prompts.
Validates scenarios against the scenario JSON schema and uses an LLM provider to run tests.

.PARAMETER Scenario
Path to a specific .scenario.md file. If omitted, runs all scenarios in tests/prompts/.

.PARAMETER Mode
Which layer to run: "structural", "behavioral", "semantic", or "all". Default is "all".

.PARAMETER Provider
The LLM provider to use: "openai", "anthropic", "ollama", "gemini". Default is "openai".
#>

[CmdletBinding()]
param(
    [string]$Scenario = "",
    [ValidateSet("structural", "behavioral", "semantic", "all")]
    [string]$Mode = "all",
    [ValidateSet("openai", "anthropic", "ollama", "gemini")]
    [string]$Provider = "gemini"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$RootDir = Split-Path $ScriptDir -Parent
$ReportsDir = Join-Path $RootDir "reports"
$FixturesDir = Join-Path $RootDir "tests\fixtures"
$JudgePromptsDir = Join-Path $RootDir "judge-prompts"
$WorkspaceDir = (Get-Location).Path

# --- Load Environment Variables ---
$EnvFile = Join-Path $RootDir ".env.local"
if (Test-Path $EnvFile) {
    Write-Host "Loading environment variables from .env.local..." -ForegroundColor DarkGray
    Get-Content $EnvFile | Where-Object { $_ -match '=' -and -not $_.StartsWith('#') } | ForEach-Object {
        $Name, $Value = $_.Split('=', 2)
        [System.Environment]::SetEnvironmentVariable($Name.Trim(), $Value.Trim())
    }
}

# --- Core Data Structures ---
$Global:Report = @{
    Timestamp = (Get-Date).ToString("o")
    OverallStatus = "HEALTHY"
    Scenarios = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        NeedsHumanReview = 0
    }
}

# --- Parsing Logic ---
function Parse-Scenario {
    param([string]$FilePath)
    $Content = Get-Content $FilePath -Raw
    
    # Extract Frontmatter
    $FrontmatterRegex = "(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$"
    if ($Content -match $FrontmatterRegex) {
        $YamlText = $matches[1]
        $BodyText = $matches[2]
    } else {
        throw "Failed to parse frontmatter in $FilePath"
    }

    # Very naive YAML parser for our simple format
    $Meta = @{}
    foreach ($Line in $YamlText -split "`n") {
        $Line = $Line.Trim()
        if ($Line.StartsWith("#") -or [string]::IsNullOrWhiteSpace($Line)) { continue }
        $Parts = $Line -split ":\s*", 2
        if ($Parts.Count -eq 2) {
            $Key = $Parts[0].Trim()
            $Val = $Parts[1].Trim().Trim('"').Trim("'")
            $Meta[$Key] = $Val
        }
    }

    # Extract Code Blocks
    $MockRepoState = "{}"
    $UserInput = ""
    $Assertions = "{}"

    # Extract Mock Repo State (json)
    if ($BodyText -match '(?s)## Mock Repo State.*?```json\r?\n(.*?)\r?\n```') {
        $MockRepoState = $matches[1]
    }

    # Extract User Input (text)
    if ($BodyText -match '(?s)## User Input.*?```text\r?\n(.*?)\r?\n```') {
        $UserInput = $matches[1]
    }

    # Extract Assertions (json)
    if ($BodyText -match '(?s)## Assertions.*?```json\r?\n(.*?)\r?\n```') {
        $Assertions = $matches[1]
    }

    return @{
        FilePath = $FilePath
        Metadata = $Meta
        MockRepoState = ($MockRepoState | ConvertFrom-Json)
        UserInput = $UserInput
        Assertions = ($Assertions | ConvertFrom-Json)
    }
}

# --- LLM Provider Abstraction ---
function Invoke-Llm {
    param(
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [switch]$JsonMode
    )

    Write-Verbose "Invoking LLM via $Provider..."
    
    if ($Provider -eq "openai") {
        $ApiKey = $env:OPENAI_API_KEY
        if ([string]::IsNullOrEmpty($ApiKey)) { throw "OPENAI_API_KEY is not set." }

        $Headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type"  = "application/json"
        }

        $BodyObj = @{
            model = "gpt-4o"
            messages = @(
                @{ role = "system"; content = $SystemPrompt },
                @{ role = "user"; content = $UserPrompt }
            )
            temperature = 0.0
        }

        if ($JsonMode) {
            $BodyObj["response_format"] = @{ type = "json_object" }
        }

        $Body = $BodyObj | ConvertTo-Json -Depth 5 -Compress
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $Headers -Body $Body
        return $Response.choices[0].message.content
    } elseif ($Provider -eq "gemini") {
        $ApiKey = $env:GEMINI_API_KEY
        if ([string]::IsNullOrEmpty($ApiKey)) { throw "GEMINI_API_KEY is not set." }

        $Headers = @{
            "Content-Type" = "application/json"
        }

        $BodyObj = @{
            system_instruction = @{ parts = @{ text = $SystemPrompt } }
            contents = @(
                @{ role = "user"; parts = @( @{ text = $UserPrompt } ) }
            )
            generationConfig = @{
                temperature = 0.0
            }
        }

        if ($JsonMode) {
            $BodyObj.generationConfig["responseMimeType"] = "application/json"
        }

        $Body = $BodyObj | ConvertTo-Json -Depth 7 -Compress
        $Endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$ApiKey"
        
        $Response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $Headers -Body $Body
        
        # Extract text from Gemini response structure
        return $Response.candidates[0].content.parts[0].text
    } else {
        throw "Provider $Provider is not fully implemented yet."
    }
}

# --- Execution Layers ---

function Run-StructuralPreflight {
    param($ScenarioObj)
    Write-Host "  [Structural Preflight] Checking required fields..." -ForegroundColor Cyan
    $Required = @("target_prompt", "description", "expected_decision", "severity_if_failed")
    foreach ($Req in $Required) {
        if (-not $ScenarioObj.Metadata.ContainsKey($Req)) {
            throw "Structural Validation Failed: Missing '$Req' in frontmatter."
        }
    }
    
    $TargetPromptPath = Join-Path $RootDir $ScenarioObj.Metadata["target_prompt"]
    if (-not (Test-Path $TargetPromptPath)) {
        throw "Structural Validation Failed: Target prompt file does not exist at $TargetPromptPath"
    }

    Write-Host "  [Structural Preflight] PASSED" -ForegroundColor Green
    return $true
}

function Run-BehavioralDryRun {
    param($ScenarioObj)
    Write-Host "  [Behavioral Dry Run] Simulating repo state..." -ForegroundColor Cyan
    
    # 1. Setup Sandbox
    $SandboxDir = Join-Path $RootDir ".forge-eval-tmp"
    if (Test-Path $SandboxDir) { Remove-Item $SandboxDir -Recurse -Force }
    New-Item -ItemType Directory -Path $SandboxDir | Out-Null
    
    try {
        # Populate Mock Repo State
        if ($ScenarioObj.MockRepoState) {
            foreach ($Prop in $ScenarioObj.MockRepoState.psobject.properties) {
                $FilePath = $Prop.Name
                $FullMockPath = Join-Path $SandboxDir $FilePath
                $MockDir = Split-Path $FullMockPath -Parent
                if (-not (Test-Path $MockDir)) { New-Item -ItemType Directory -Path $MockDir -Force | Out-Null }
                Set-Content -Path $FullMockPath -Value $Prop.Value
            }
        }

        # 2. Execute target prompt against the LLM simulating Copilot
        $TargetPromptPath = Join-Path $RootDir $ScenarioObj.Metadata["target_prompt"]
        $SystemPrompt = Get-Content $TargetPromptPath -Raw
        $SystemPrompt += "`n`n[SIMULATOR NOTE]: You are executing within a dry-run harness. Do not wait for actual tool execution. Provide your final response or decision."
        
        $UserPrompt = "The current mock working directory contains the following files:`n"
        if ($ScenarioObj.MockRepoState) {
            foreach ($Prop in $ScenarioObj.MockRepoState.psobject.properties) {
                $FilePath = $Prop.Name
                $UserPrompt += "- $FilePath`n"
            }
        }
        $UserPrompt += "`nUSER MESSAGE:`n" + $ScenarioObj.UserInput

        $AgentOutput = Invoke-Llm -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt

        # 3. Deterministic Assertions
        $PassedAll = $true
        $FailedReasons = @()

        if ($ScenarioObj.Assertions.psobject.properties.Match("structural").Count -gt 0) {
            foreach ($Assertion in $ScenarioObj.Assertions.structural) {
                if ($Assertion.type -eq "contains") {
                    if (-not $AgentOutput.Contains($Assertion.value)) {
                        $PassedAll = $false
                        $FailedReasons += "Failed to find expected string: '$($Assertion.value)'"
                    }
                }
            }
        }

        if ($PassedAll) {
            Write-Host "  [Behavioral Dry Run] PASSED" -ForegroundColor Green
        } else {
            Write-Host "  [Behavioral Dry Run] FAILED: $($FailedReasons -join ', ')" -ForegroundColor Red
        }

        return @{ Passed = $PassedAll; AgentOutput = $AgentOutput; Reasons = $FailedReasons }
    } finally {
        # Cleanup
        if (Test-Path $SandboxDir) { Remove-Item $SandboxDir -Recurse -Force }
    }
}

function Run-SemanticJudging {
    param($ScenarioObj, $AgentOutput)
    Write-Host "  [Semantic Judging] Evaluating with LLM Judge..." -ForegroundColor Cyan

    if (-not $ScenarioObj.Assertions.psobject.properties.Match("semantic").Count -gt 0 -or $ScenarioObj.Assertions.semantic.Count -eq 0) {
        Write-Host "  [Semantic Judging] SKIP (No semantic assertions)" -ForegroundColor DarkGray
        return @{ Passed = $true; Confidence = 1.0; Reason = "Skipped" }
    }

    $JudgeSystemPromptPath = Join-Path $JudgePromptsDir "semantic-judge.prompt.md"
    if (-not (Test-Path $JudgeSystemPromptPath)) {
        throw "Missing judge prompt: $JudgeSystemPromptPath"
    }
    $JudgeSystemPrompt = Get-Content $JudgeSystemPromptPath -Raw

    $SemanticConstraints = $ScenarioObj.Assertions.semantic -join "`n- "
    $JudgeUserPrompt = "AGENT OUTPUT TO EVALUATE:`n---`n$AgentOutput`n---`n`nCONSTRAINTS TO VERIFY:`n- $SemanticConstraints"

    $JudgeResponse = Invoke-Llm -SystemPrompt $JudgeSystemPrompt -UserPrompt $JudgeUserPrompt -JsonMode
    $JudgeResult = $JudgeResponse | ConvertFrom-Json

    if ($JudgeResult.pass) {
        Write-Host "  [Semantic Judging] PASSED (Confidence: $($JudgeResult.confidence))" -ForegroundColor Green
    } else {
        Write-Host "  [Semantic Judging] FAILED: $($JudgeResult.reason)" -ForegroundColor Red
    }

    return @{ Passed = $JudgeResult.pass; Confidence = $JudgeResult.confidence; Reason = $JudgeResult.reason }
}

# --- Main Logic ---

Write-Host "Starting Copilot Forge SDD Semantic Testing Framework..." -ForegroundColor Magenta

# Find Scenarios
$ScenariosToRun = @()
if ([string]::IsNullOrEmpty($Scenario)) {
    $PromptsDir = Join-Path $RootDir "tests\prompts"
    if (Test-Path $PromptsDir) {
        $ScenariosToRun = Get-ChildItem -Path $PromptsDir -Filter "*.scenario.md" -File
    }
} else {
    $ScenariosToRun = @(Get-Item $Scenario)
}

if ($ScenariosToRun.Count -eq 0) {
    Write-Host "No scenarios found." -ForegroundColor Yellow
    exit 0
}

foreach ($File in $ScenariosToRun) {
    Write-Host "`nRunning Scenario: $($File.Name)" -ForegroundColor Cyan
    $Global:Report.Summary.Total++
    
    $ScenarioPassed = $true
    $ScenarioResult = @{ File = $File.Name; Status = "PASSED"; Details = @{} }

    try {
        $Parsed = Parse-Scenario -FilePath $File.FullName

        # Phase 1: Structural
        if ($Mode -in "structural", "all") {
            $ScenarioResult.Details.Structural = "PASSED"
            Run-StructuralPreflight -ScenarioObj $Parsed | Out-Null
        }

        # Phase 2: Behavioral
        $AgentOutput = ""
        if ($Mode -in "behavioral", "all") {
            $BehavioralResult = Run-BehavioralDryRun -ScenarioObj $Parsed
            $AgentOutput = $BehavioralResult.AgentOutput
            if (-not $BehavioralResult.Passed) {
                $ScenarioPassed = $false
                $ScenarioResult.Details.Behavioral = "FAILED"
                $ScenarioResult.Details.BehavioralReasons = $BehavioralResult.Reasons
            } else {
                $ScenarioResult.Details.Behavioral = "PASSED"
            }
        }

        # Phase 3: Semantic
        if ($Mode -in "semantic", "all" -and $ScenarioPassed) {
            $SemanticResult = Run-SemanticJudging -ScenarioObj $Parsed -AgentOutput $AgentOutput
            if (-not $SemanticResult.Passed) {
                $ScenarioPassed = $false
                $ScenarioResult.Details.Semantic = "FAILED"
                $ScenarioResult.Details.SemanticReason = $SemanticResult.Reason
            } else {
                $ScenarioResult.Details.Semantic = "PASSED"
            }

            if ($SemanticResult.Confidence -lt 0.8) {
                $ScenarioResult.Status = "NEEDS_HUMAN_REVIEW"
                $Global:Report.Summary.NeedsHumanReview++
                Write-Host "  -> Flagged for human review due to low judge confidence." -ForegroundColor Yellow
            }
        }

    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        $ScenarioPassed = $false
        $ScenarioResult.Details.Error = $_.Exception.Message
    }

    if (-not $ScenarioPassed -and $ScenarioResult.Status -ne "NEEDS_HUMAN_REVIEW") {
        $ScenarioResult.Status = "FAILED"
        $Global:Report.Summary.Failed++
        # Determine aggregate health
        $Severity = $Parsed.Metadata["severity_if_failed"]
        if ($Severity -eq "BROKEN") { $Global:Report.OverallStatus = "BROKEN" }
        elseif ($Severity -eq "DEGRADED" -and $Global:Report.OverallStatus -ne "BROKEN") { $Global:Report.OverallStatus = "DEGRADED" }
    } elseif ($ScenarioResult.Status -eq "PASSED") {
        $Global:Report.Summary.Passed++
    }

    $Global:Report.Scenarios += $ScenarioResult
}

# --- Health Reporting ---
Write-Host "`n========================================="
Write-Host "EVALUATION COMPLETE: $($Global:Report.OverallStatus)" -ForegroundColor $(
    if ($Global:Report.OverallStatus -eq "HEALTHY") { "Green" } 
    elseif ($Global:Report.OverallStatus -eq "DEGRADED") { "Yellow" } 
    else { "Red" }
)
Write-Host "Total: $($Global:Report.Summary.Total) | Passed: $($Global:Report.Summary.Passed) | Failed: $($Global:Report.Summary.Failed) | Review: $($Global:Report.Summary.NeedsHumanReview)"
Write-Host "=========================================`n"

$ReportJsonPath = Join-Path $ReportsDir "forge-eval-$( (Get-Date).ToString('yyyyMMdd-HHmmss') ).json"
$Global:Report | ConvertTo-Json -Depth 5 | Set-Content $ReportJsonPath
Write-Host "Report saved to $ReportJsonPath" -ForegroundColor DarkGray
