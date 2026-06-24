param (
    [Parameter(Mandatory=$false)]
    [string]$TargetDir = $PWD.Path
)

# Ensure the target directory exists
if (-not (Test-Path -Path $TargetDir)) {
    Write-Host "Target directory does not exist: $TargetDir" -ForegroundColor Red
    exit 1
}

Write-Host "Fetching latest Copilot Forge engine..." -ForegroundColor Cyan

$RepoUrl = "https://github.com/AI-Corner/copilot-forge/archive/refs/heads/master.zip"
$TempZip = Join-Path $env:TEMP "copilot-forge-master.zip"
$ExtractPath = Join-Path $env:TEMP "copilot-forge-extract"

# Clean up any previous extraction
if (Test-Path $ExtractPath) {
    Remove-Item -Path $ExtractPath -Recurse -Force
}

try {
    # Download the latest master branch as a zip
    Write-Host "Downloading latest release..."
    Invoke-WebRequest -Uri $RepoUrl -OutFile $TempZip
    
    # Extract the zip
    Write-Host "Extracting files..."
    Expand-Archive -Path $TempZip -DestinationPath $ExtractPath -Force
    
    $SourceDir = Join-Path $ExtractPath "copilot-forge-master"
    
    Write-Host "Updating Copilot Forge engine in $TargetDir..." -ForegroundColor Cyan

    # 1. Update the core engine directories (overwrite existing)
    Write-Host "Updating .github (prompts and instructions)..."
    Copy-Item -Path (Join-Path $SourceDir ".github") -Destination $TargetDir -Recurse -Force
    
    Write-Host "Updating .vscode (workspace settings)..."
    Copy-Item -Path (Join-Path $SourceDir ".vscode") -Destination $TargetDir -Recurse -Force

    Write-Host "Updating scripts (pipeline scripts)..."
    Copy-Item -Path (Join-Path $SourceDir "scripts") -Destination $TargetDir -Recurse -Force

    # 2. Intelligently merge the templates
    $SourceTemplates = Join-Path $SourceDir "templates"
    $TargetTemplates = Join-Path $TargetDir "templates"
    
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
    Write-Host "✅ Copilot Forge successfully updated in $TargetDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Open Copilot Chat in your project."
    Write-Host "2. Run '#init' to safely apply any new structure or context migrations to your .forge directory."

} finally {
    # Cleanup
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
    if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
}
