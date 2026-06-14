param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDir
)

# Ensure the target directory exists
if (-not (Test-Path -Path $TargetDir)) {
    Write-Host "Target directory does not exist: $TargetDir" -ForegroundColor Red
    exit 1
}

$SourceDir = $PSScriptRoot

Write-Host "Installing Copilot Forge engine to $TargetDir..." -ForegroundColor Cyan

# 1. Copy the toolkit engine (.github and .vscode)
Write-Host "Copying .github (prompts and instructions)..."
Copy-Item -Path (Join-Path $SourceDir ".github") -Destination $TargetDir -Recurse -Force

Write-Host "Copying .vscode (workspace settings)..."
Copy-Item -Path (Join-Path $SourceDir ".vscode") -Destination $TargetDir -Recurse -Force

# 2. Copy the toolkit templates
$TargetTemplates = Join-Path $TargetDir "templates"
if (-not (Test-Path -Path $TargetTemplates)) {
    Write-Host "Copying standard templates..."
    Copy-Item -Path (Join-Path $SourceDir "templates") -Destination $TargetDir -Recurse -Force
}

Write-Host ""
Write-Host "✅ Copilot Forge successfully installed in $TargetDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open $TargetDir in VS Code"
Write-Host "2. Open Copilot Chat and run '#init' to scaffold the project context"
