#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./install.sh <TargetDir>"
    exit 1
fi

TargetDir="$1"

# Ensure the target directory exists
if [ ! -d "$TargetDir" ]; then
    echo -e "\e[31mTarget directory does not exist: $TargetDir\e[0m"
    exit 1
fi

SourceDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

echo -e "\e[36mInstalling Copilot Forge engine to $TargetDir...\e[0m"

# 1. Copy the toolkit engine
echo "Copying .github (prompts and instructions)..."
cp -r "$SourceDir/.github" "$TargetDir/"

echo "Copying .vscode (workspace settings)..."
cp -r "$SourceDir/.vscode" "$TargetDir/"

echo "Copying scripts (toolkit helpers)..."
cp -r "$SourceDir/scripts" "$TargetDir/"

# 2. Intelligently merge the templates
TargetTemplates="$TargetDir/.forge/templates"
SourceTemplates="$SourceDir/templates"

if [ ! -d "$TargetTemplates" ]; then
    echo "Copying standard templates..."
    mkdir -p "$TargetDir/.forge"
    cp -r "$SourceTemplates" "$TargetDir/.forge/"
else
    echo "Merging new templates (preserving your customizations)..."
    # Only copy files that don't exist in the target
    find "$SourceTemplates" -type f | while read -r srcFile; do
        relativePath="${srcFile#$SourceTemplates/}"
        destinationFile="$TargetTemplates/$relativePath"
        destinationDir="$(dirname "$destinationFile")"
        
        if [ ! -d "$destinationDir" ]; then
            mkdir -p "$destinationDir"
        fi
        
        if [ ! -f "$destinationFile" ]; then
            echo "  Adding new template: $relativePath"
            cp "$srcFile" "$destinationFile"
        fi
    done
fi

echo ""
echo -e "\e[32m✅ Copilot Forge successfully installed in $TargetDir\e[0m"
echo ""
echo -e "\e[33mNext steps:\e[0m"
echo "1. Open $TargetDir in VS Code"
echo "2. Open Copilot Chat and run '#forge-init' to scaffold the project context"
