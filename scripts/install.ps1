param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDir
)

# Ensure the target directory exists
if (-not (Test-Path -Path $TargetDir)) {
    Write-Host "Target directory does not exist: $TargetDir" -ForegroundColor Red
    exit 1
}

$SourceDir = Split-Path -Path $PSScriptRoot -Parent

Write-Host "Installing Copilot Forge engine to $TargetDir..." -ForegroundColor Cyan

# 1. Copy the toolkit engine (.github and .vscode)
Write-Host "Copying .github (prompts and instructions)..."
Copy-Item -Path (Join-Path $SourceDir ".github") -Destination $TargetDir -Recurse -Force

Write-Host "Copying .vscode (workspace settings)..."
Copy-Item -Path (Join-Path $SourceDir ".vscode") -Destination $TargetDir -Recurse -Force

# 2. Intelligently merge the templates
$TargetTemplates = Join-Path $TargetDir ".forge\templates"
$SourceTemplates = Join-Path $SourceDir "templates"

if (-not (Test-Path -Path $TargetTemplates)) {
    Write-Host "Copying standard templates..."
    Copy-Item -Path $SourceTemplates -Destination $TargetDir -Recurse -Force
} else {
    Write-Host "Merging new templates (preserving your customizations)..."
    # Only copy files that don't exist in the target
    Get-ChildItem -Path $SourceTemplates -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($SourceTemplates.Length + 1)
        $destinationFile = Join-Path $TargetTemplates $relativePath
        $destinationDir = Split-Path $destinationFile -Parent
        
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        
        if (-not (Test-Path $destinationFile)) {
            Write-Host "  Adding new template: $relativePath"
            Copy-Item -Path $_.FullName -Destination $destinationFile -Force
        }
    }
}

Write-Host ""
Write-Host "✅ Copilot Forge successfully installed in $TargetDir" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open $TargetDir in VS Code"
Write-Host "2. Open Copilot Chat and run '#init' to scaffold the project context"
