#!/usr/bin/env bash
set -e

# Defaults
TargetDir=()
DryRun=0
SkipGitPull=0
Force=0
NoBackup=0
Branch=""
HealthOnly=0
JsonReport=0

GithubDir=""
PromptsDir=""
TemplatesDir=""
ScriptsDir=""
VscodeDir=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -TargetDir)
            shift
            IFS=',' read -ra DIRS <<< "$1"
            for d in "${DIRS[@]}"; do
                TargetDir+=("$d")
            done
            ;;
        -DryRun) DryRun=1 ;;
        -SkipGitPull) SkipGitPull=1 ;;
        -Force) Force=1 ;;
        -NoBackup) NoBackup=1 ;;
        -Branch) Branch="$2"; shift ;;
        -HealthOnly) HealthOnly=1 ;;
        -JsonReport) JsonReport=1 ;;
        -GithubDir) GithubDir="$2"; shift ;;
        -PromptsDir) PromptsDir="$2"; shift ;;
        -TemplatesDir) TemplatesDir="$2"; shift ;;
        -ScriptsDir) ScriptsDir="$2"; shift ;;
        -VscodeDir) VscodeDir="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ ${#TargetDir[@]} -eq 0 ]; then
    echo "Usage: ./update.sh -TargetDir \"/path/a,/path/b\" [-DryRun] [-HealthOnly] ..."
    exit 1
fi

Write-Header() { if [ $JsonReport -eq 0 ]; then echo -e "\n\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n  $1\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"; fi; }
Write-Ok()     { if [ $JsonReport -eq 0 ]; then echo -e "  \e[32m✅  $1\e[0m"; fi; }
Write-Warn()   { if [ $JsonReport -eq 0 ]; then echo -e "  \e[33m⚠️   $1\e[0m"; fi; }
Write-Info()   { if [ $JsonReport -eq 0 ]; then echo -e "  \e[36mℹ️   $1\e[0m"; fi; }
Write-New()    { if [ $JsonReport -eq 0 ]; then echo -e "  \e[35m🆕  $1\e[0m"; fi; }
Write-Upd()    { if [ $JsonReport -eq 0 ]; then echo -e "  \e[33m✏️   $1\e[0m"; fi; }
Write-Skip()   { if [ $JsonReport -eq 0 ]; then echo -e "  \e[90m⏭️   $1\e[0m"; fi; }
Write-Err()    { if [ $JsonReport -eq 0 ]; then echo -e "  \e[31m❌  $1\e[0m"; fi; }

Get-MD5Hash() {
    local file="$1"
    if [ -f "$file" ]; then
        if command -v md5sum >/dev/null 2>&1; then
            md5sum "$file" | awk '{print $1}'
        elif command -v md5 >/dev/null 2>&1; then
            md5 -q "$file"
        fi
    fi
}

Get-DefaultBranch() {
    local repoPath="$1"
    local res=$(git -C "$repoPath" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
    if [ -n "$res" ]; then
        echo "$res" | awk -F'/' '{print $NF}'
    else
        echo "master"
    fi
}

Get-ToolkitVersion() {
    local toolkitPath="$1"
    local readme="$toolkitPath/README.md"
    if [ -f "$readme" ]; then
        # Look for vX.Y.Z
        local ver=$(grep -oE '[-–][[:space:]]*\*{0,2}(v[0-9]+\.[0-9]+\.[0-9]+)\*{0,2}' "$readme" | head -n 1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true)
        if [ -n "$ver" ]; then echo "$ver"; return; fi
    fi
    echo "unknown"
}

Get-InstalledVersion() {
    local projectPath="$1"
    local vf="$projectPath/.forge/.forge-version"
    if [ -f "$vf" ]; then
        cat "$vf" | tr -d ' \n\r'
    else
        echo "unknown"
    fi
}

New-Backup() {
    local projectPath="$1"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local backupRoot="$projectPath/.forge/.backups"
    local backupDir="$backupRoot/pre-update-$timestamp"
    
    local dirsToBack=()
    for d in ".github" ".vscode" ".forge/templates"; do
        if [ -d "$projectPath/$d" ]; then dirsToBack+=("$d"); fi
    done
    
    if [ ${#dirsToBack[@]} -eq 0 ]; then return; fi
    
    mkdir -p "$backupDir"
    for rel in "${dirsToBack[@]}"; do
        mkdir -p "$(dirname "$backupDir/$rel")"
        cp -r "$projectPath/$rel" "$backupDir/$(dirname "$rel")"
    done
    Write-Ok "Backup created -> $backupDir"
    echo "$backupDir"
}

Sync-Directory() {
    local srcRoot="$1"
    local dstRoot="$2"
    local subDir="$3"
    local excludePrefix="$4"
    
    if [ ! -d "$srcRoot" ]; then return; fi
    
    while IFS= read -r srcFile; do
        if [ -z "$srcFile" ]; then continue; fi
        local relPath="${srcFile#$srcRoot/}"
        if [ -n "$excludePrefix" ] && [[ "$relPath" == "$excludePrefix"* ]]; then continue; fi
        local dstFile="$dstRoot/$relPath"
        
        local srcHash=$(Get-MD5Hash "$srcFile")
        local dstHash=$(Get-MD5Hash "$dstFile")
        local fileName=$(basename "$relPath")
        
        if [ "$fileName" == "copilot-instructions.md" ] && [ -n "$dstHash" ] && [ "$srcHash" != "$dstHash" ]; then
            Write-Skip "[$subDir] $relPath  (protected — user-customised, kept as-is)"
            stats_Skipped=$((stats_Skipped + 1))
            log_entries+=("{\"Dir\":\"$subDir\",\"File\":\"$relPath\",\"Status\":\"SKIPPED\"}")
            continue
        fi
        
        if [ "$srcHash" == "$dstHash" ]; then
            stats_Identical=$((stats_Identical + 1))
            continue
        fi
        
        local isNew=0
        if [ -z "$dstHash" ]; then isNew=1; fi
        
        if [ $DryRun -eq 0 ] && [ $HealthOnly -eq 0 ]; then
            mkdir -p "$(dirname "$dstFile")"
            cp "$srcFile" "$dstFile"
        fi
        
        if [ $isNew -eq 1 ]; then
            if [ $HealthOnly -eq 0 ]; then Write-New "[$subDir] $relPath"; fi
            stats_Added=$((stats_Added + 1))
            log_entries+=("{\"Dir\":\"$subDir\",\"File\":\"$relPath\",\"Status\":\"NEW\"}")
        else
            if [ $HealthOnly -eq 0 ]; then Write-Upd "[$subDir] $relPath  <- updated"; fi
            stats_Updated=$((stats_Updated + 1))
            log_entries+=("{\"Dir\":\"$subDir\",\"File\":\"$relPath\",\"Status\":\"UPDATED\"}")
        fi
    done < <(find "$srcRoot" -type f 2>/dev/null || true)
}

Get-DiffStats() {
    local fileA="$1"
    local fileB="$2"
    local raw=$(git diff --no-index --numstat -- "$fileA" "$fileB" 2>/dev/null || true)
    if [ -n "$raw" ]; then
        local added=$(echo "$raw" | awk '{print $1}')
        local removed=$(echo "$raw" | awk '{print $2}')
        if [[ "$added" =~ ^[0-9]+$ ]] && [[ "$removed" =~ ^[0-9]+$ ]]; then
            echo "$added|$removed"
            return
        fi
    fi
    echo "?|?"
}

Invoke-TemplateDriftReport() {
    local toolkitPath="$1"
    local projectPath="$2"
    local srcDir="$toolkitPath/templates"
    local dstDir="$projectPath/.forge/templates"
    
    if [ $JsonReport -eq 0 ]; then
        Write-Header "Template Drift Health Report"
        printf "  %-30s %-10s %-10s %-15s %s\n" "Template" "+Lines" "-Lines" "Status" "Action"
        echo "  --------------------------------------------------------------------------------"
    fi
    
    if [ -d "$srcDir" ]; then
        while IFS= read -r srcFile; do
            if [ -z "$srcFile" ]; then continue; fi
            local name=$(basename "$srcFile")
            local dstFile="$dstDir/$name"
            local srcHash=$(Get-MD5Hash "$srcFile")
            local dstHash=$(Get-MD5Hash "$dstFile")
            
            if [ -z "$dstHash" ]; then
                if [ $JsonReport -eq 0 ]; then printf "  %-30s %-10s %-10s %-15s %s\n" "$name" "-" "-" "🆕 New" "Added automatically"; fi
                drift_entries+=("{\"Template\":\"$name\",\"+Lines\":\"-\",\"-Lines\":\"-\",\"Status\":\"🆕 New\",\"Action\":\"Added automatically\"}")
            elif [ "$srcHash" == "$dstHash" ]; then
                if [ $JsonReport -eq 0 ]; then printf "  %-30s %-10s %-10s %-15s %s\n" "$name" "-" "-" "✅ In sync" "None"; fi
                drift_entries+=("{\"Template\":\"$name\",\"+Lines\":\"-\",\"-Lines\":\"-\",\"Status\":\"✅ In sync\",\"Action\":\"None\"}")
            else
                local stats=$(Get-DiffStats "$dstFile" "$srcFile")
                local added="${stats%|*}"
                local removed="${stats#*|}"
                local action="Likely cosmetic — run #template-drift"
                if [[ "$added" =~ ^[0-9]+$ ]] && [ "$added" -gt 10 ]; then action="Run #template-drift to review"; fi
                if [[ "$removed" =~ ^[0-9]+$ ]] && [ "$removed" -gt 10 ]; then action="Run #template-drift to review"; fi
                if [ $JsonReport -eq 0 ]; then printf "  %-30s %-10s %-10s %-15s %s\n" "$name" "+$added" "-$removed" "⚠️ Drifted" "$action"; fi
                drift_entries+=("{\"Template\":\"$name\",\"+Lines\":\"+$added\",\"-Lines\":\"-$removed\",\"Status\":\"⚠️ Drifted\",\"Action\":\"$action\"}")
            fi
        done < <(find "$srcDir" -type f -name "*.md" 2>/dev/null || true)
    fi
    
    if [ -d "$dstDir" ]; then
        while IFS= read -r dstFile; do
            if [ -z "$dstFile" ]; then continue; fi
            local name=$(basename "$dstFile")
            if [ ! -f "$srcDir/$name" ]; then
                if [ $JsonReport -eq 0 ]; then printf "  %-30s %-10s %-10s %-15s %s\n" "$name" "-" "-" "🔒 Custom" "Untouched"; fi
                drift_entries+=("{\"Template\":\"$name\",\"+Lines\":\"-\",\"-Lines\":\"-\",\"Status\":\"🔒 Custom\",\"Action\":\"Untouched\"}")
            fi
        done < <(find "$dstDir" -type f -name "*.md" 2>/dev/null || true)
    fi
    if [ $JsonReport -eq 0 ]; then echo ""; fi
}

Update-Repo() {
    local toolkitPath="$1"
    local projectPath="$2"
    local toolkitVer="$3"
    
    cd "$projectPath" || return
    projectPath="$(pwd)"
    
    Write-Header "$projectPath"
    
    local installedVer=$(Get-InstalledVersion "$projectPath")
    Write-Info "Installed : $installedVer   |   Toolkit : $toolkitVer"
    
    if [ $HealthOnly -eq 0 ]; then
        local forgeConfig="$projectPath/.forge/config.yml"
        if [ ! -f "$forgeConfig" ] && [ $Force -eq 0 ]; then
            Write-Warn "Target does not appear to be a Forge project (no .forge/config.yml). Skipping. Use -Force to override."
            return
        fi
        
        if [ "$installedVer" == "$toolkitVer" ] && [ "$installedVer" != "unknown" ] && [ $Force -eq 0 ]; then
            Write-Ok "Already at $toolkitVer — nothing to sync."
            return
        fi
        
        if [ $DryRun -eq 1 ]; then Write-Warn "DRY RUN — no files will be written."; fi
        
        if [ $Force -eq 0 ] && [ $DryRun -eq 0 ]; then
            read -p "  Proceed with update? [Y/n] " ok
            if [[ "$ok" =~ ^[Nn] ]]; then
                Write-Warn "Skipped."
                return
            fi
        fi
        
        # Migrate old templates
        local oldTemplates="$projectPath/templates"
        local newTemplates="$projectPath/.forge/templates"
        if [ -d "$oldTemplates" ]; then
            Write-Info "Migrating legacy templates/ directory to .forge/templates/..."
            if [ $DryRun -eq 0 ]; then
                if [ ! -d "$newTemplates" ]; then
                    mkdir -p "$projectPath/.forge"
                    mv "$oldTemplates" "$newTemplates"
                else
                    cp -r "$oldTemplates/"* "$newTemplates/"
                    rm -rf "$oldTemplates"
                fi
            fi
        fi
    fi
    
    local backupDir=""
    if [ $DryRun -eq 0 ] && [ $NoBackup -eq 0 ] && [ $HealthOnly -eq 0 ]; then
        backupDir=$(New-Backup "$projectPath")
    fi
    
    stats_Added=0
    stats_Updated=0
    stats_Identical=0
    stats_Skipped=0
    log_entries=()
    drift_entries=()
    
    local targetGithub="${GithubDir:-$projectPath/.github}"
    local targetPrompts="${PromptsDir:-$targetGithub/prompts}"
    local targetVscode="${VscodeDir:-$projectPath/.vscode}"
    local targetScripts="${ScriptsDir:-$projectPath/scripts}"
    local targetTemplates="${TemplatesDir:-$projectPath/.forge/templates}"

    Sync-Directory "$toolkitPath/.github" "$targetGithub" ".github" "prompts/"
    Sync-Directory "$toolkitPath/.github/prompts" "$targetPrompts" ".github/prompts"
    Sync-Directory "$toolkitPath/.vscode" "$targetVscode" ".vscode"
    Sync-Directory "$toolkitPath/scripts" "$targetScripts" "scripts"
    
    if [ $HealthOnly -eq 0 ]; then
        local srcTemplates="$toolkitPath/templates"
        if [ -d "$srcTemplates" ]; then
            while IFS= read -r srcFile; do
                if [ -z "$srcFile" ]; then continue; fi
                local name=$(basename "$srcFile")
                local dstFile="$targetTemplates/$name"
                if [ ! -f "$dstFile" ]; then
                    if [ $DryRun -eq 0 ]; then
                        mkdir -p "$targetTemplates"
                        cp "$srcFile" "$dstFile"
                    fi
                    Write-New "[templates] $name"
                    stats_Added=$((stats_Added + 1))
                    log_entries+=("{\"Dir\":\"templates\",\"File\":\"$name\",\"Status\":\"NEW\"}")
                fi
            done < <(find "$srcTemplates" -type f -name "*.md" 2>/dev/null || true)
        fi
        
        if [ $DryRun -eq 0 ] && [ "$toolkitVer" != "unknown" ]; then
            if [ -d "$projectPath/.forge" ]; then
                echo "$toolkitVer" > "$projectPath/.forge/.forge-version"
            fi
        fi
    fi
    
    Invoke-TemplateDriftReport "$toolkitPath" "$projectPath"
    
    if [ $JsonReport -eq 0 ]; then
        Write-Header "Update Summary"
        echo "  🆕 Added     : $stats_Added"
        echo "  ✏️  Updated   : $stats_Updated"
        echo "  ⏭️  Skipped   : $stats_Skipped"
    fi
    
    local logsJson="["$(IFS=,; echo "${log_entries[*]}")"]"
    local driftsJson="["$(IFS=,; echo "${drift_entries[*]}")"]"
    
    local resJson="{\"Project\":\"$projectPath\",\"InstalledVersion\":\"$installedVer\",\"ToolkitVersion\":\"$toolkitVer\",\"FilesAdded\":$stats_Added,\"FilesUpdated\":$stats_Updated,\"FilesSkipped\":$stats_Skipped,\"TemplateDrift\":$driftsJson,\"BackupDir\":\"$backupDir\"}"
    allResults+=("$resJson")
}

ToolkitDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

if [ ! -d "$ToolkitDir/.github" ]; then
    Write-Err "Run update.sh from the copilot-forge toolkit root directory."
    exit 1
fi

if [ $SkipGitPull -eq 0 ] && [ $HealthOnly -eq 0 ]; then
    pullBranch=$Branch
    if [ -z "$pullBranch" ]; then pullBranch=$(Get-DefaultBranch "$ToolkitDir"); fi
    cd "$ToolkitDir"
    git pull origin "$pullBranch" 2>&1 || true
fi

toolkitVersion=$(Get-ToolkitVersion "$ToolkitDir")
allResults=()

for target in "${TargetDir[@]}"; do
    if [ -d "$target" ]; then
        Update-Repo "$ToolkitDir" "$target" "$toolkitVersion"
    fi
done

if [ $JsonReport -eq 1 ]; then
    echo "["$(IFS=,; echo "${allResults[*]}")"]"
fi
