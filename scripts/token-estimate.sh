#!/usr/bin/env bash
set -e

# Defaults
ReqId=""
RepoRoot="$(pwd)"
OutputJson=0
UpdatePipelineState=0

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -ReqId) ReqId="$2"; shift ;;
        -RepoRoot) RepoRoot="$2"; shift ;;
        -OutputJson) OutputJson=1 ;;
        -UpdatePipelineState) UpdatePipelineState=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Helpers
Get-Tokens() {
    local path="$1"
    if [ -f "$path" ]; then
        if [ "$(uname)" == "Darwin" ]; then
            bytes=$(stat -f "%z" "$path")
        else
            bytes=$(stat -c "%s" "$path")
        fi
        echo $(( (bytes + 3) / 4 ))
    else
        echo 0
    fi
}

Get-DirTokens() {
    local dir="$1"
    local pattern="$2"
    if [ ! -d "$dir" ]; then echo 0; return; fi
    local total=0
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            if [ "$(uname)" == "Darwin" ]; then
                bytes=$(stat -f "%z" "$file")
            else
                bytes=$(stat -c "%s" "$file")
            fi
            total=$(( total + (bytes + 3) / 4 ))
        fi
    done < <(find "$dir" -type f -name "$pattern" 2>/dev/null || true)
    echo $total
}

Get-DirDetails() {
    local dir="$1"
    local pattern="$2"
    local topN="$3"
    if [ ! -d "$dir" ]; then return; fi
    
    # Sort files by size descending
    if [ "$(uname)" == "Darwin" ]; then
        find "$dir" -type f -name "$pattern" -exec stat -f "%z %N" {} + 2>/dev/null | sort -nr
    else
        find "$dir" -type f -name "$pattern" -exec stat -c "%s %n" {} + 2>/dev/null | sort -nr
    fi | head -n "$topN" | while read -r bytes path; do
        name=$(basename "$path")
        tokens=$(( (bytes + 3) / 4 ))
        echo "$tokens|$name"
    done
}

Pad() {
    local s="$1"
    local width="$2"
    printf "%-${width}s" "$s" | cut -c 1-$width
}

FmtN() {
    # Add commas to numbers
    echo "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

normalizedReqId=""
reqSpecDir=""
reqTitle=""

if [ -n "$ReqId" ]; then
    num=$(echo "$ReqId" | sed 's/[^0-9]//g')
    normalizedReqId=$(printf "REQ-%03d" "$num")

    specsRoot="$RepoRoot/.forge/specs"
    reqSpecDir=$(find "$specsRoot" -type d -name "$normalizedReqId-*" 2>/dev/null | head -n 1)
    
    if [ -n "$reqSpecDir" ]; then
        reqFile="$reqSpecDir/requirement.md"
        if [ -f "$reqFile" ]; then
            titleMatch=$(awk '/^title:/{print}' "$reqFile" | sed -E 's/^title:[[:space:]]*"?([^"]+)"?/\1/')
            if [ -n "$titleMatch" ]; then reqTitle=$(echo "$titleMatch" | tr -d '\r\n'); fi
        fi
    else
        echo -e "\e[33mWarning: No spec directory found for $normalizedReqId under $specsRoot\e[0m" >&2
        echo -e "\e[33mContinuing with baseline context estimate only.\e[0m" >&2
        normalizedReqId=""
    fi
fi

forge="$RepoRoot/.forge"
context="$forge/context"
prompts="$RepoRoot/.github/prompts"
agents="$prompts/agents"
knowledge="$forge/knowledge"

# Baseline
tBaseline=0
for f in "$RepoRoot/.github/copilot-instructions.md" "$context/project-overview.md" "$context/architecture.md" "$context/conventions.md" "$context/variables.md" "$context/taxonomy.md" "$context/deployment.md"; do
    tBaseline=$((tBaseline + $(Get-Tokens "$f")))
done

# Prompts
tSpec=$(Get-Tokens "$prompts/spec.prompt.md")
tValidate=$(Get-Tokens "$prompts/validate.prompt.md")
tArchitect=$(Get-Tokens "$prompts/architect.prompt.md")
tTdd=$(Get-Tokens "$prompts/tdd.prompt.md")
tProceed=$(Get-Tokens "$prompts/proceed.prompt.md")
tReflect=$(Get-Tokens "$prompts/reflect.prompt.md")
tReview=$(Get-Tokens "$prompts/review.prompt.md")
tWrapup=$(Get-Tokens "$prompts/wrapup.prompt.md")
tCanary=$(Get-Tokens "$prompts/canary.prompt.md")
tAgents=$(Get-DirTokens "$agents" "*.md")

# RAG
tRagLessons=0
while IFS='|' read -r tokens name; do
    if [ -n "$tokens" ]; then tRagLessons=$((tRagLessons + tokens)); fi
done < <(Get-DirDetails "$knowledge/lessons" "*.md" 5)

tRagSupport=0
while IFS='|' read -r tokens name; do
    if [ -n "$tokens" ]; then tRagSupport=$((tRagSupport + tokens)); fi
done < <(Get-DirDetails "$knowledge/support" "*.md" 3)

tRag=$((tRagLessons + tRagSupport))

tReqArtifacts=0
tTasks=0
taskCount=0
tSourcePayload=0
sourceFilesCount=0

if [ -n "$reqSpecDir" ]; then
    reqFile="$reqSpecDir/requirement.md"
    tasksDir="$reqSpecDir/tasks"
    tReqArtifacts=$(Get-Tokens "$reqFile")
    
    if [ -d "$tasksDir" ]; then
        taskFiles=()
        while IFS= read -r file; do
            if [ -n "$file" ]; then taskFiles+=("$file"); fi
        done < <(find "$tasksDir" -type f -name "*.md" 2>/dev/null || true)
        
        taskCount=${#taskFiles[@]}
        for tf in "${taskFiles[@]}"; do
            tTasks=$((tTasks + $(Get-Tokens "$tf")))
            
            # Extract files
            content=$(cat "$tf")
            filesSection=$(echo "$content" | awk '/^## Files to Create\/Modify/{flag=1; next} /^##/{flag=0} flag' || true)
            if [ -n "$filesSection" ]; then
                sourcePaths=$(echo "$filesSection" | grep -oE '^[-*][[:space:]]+[`"]?[^`" -]+[`"]?' | sed -E 's/^[-*][[:space:]]+[`"]?([^`" -]+)[`"]?/\1/' || true)
                for sp in $sourcePaths; do
                    fullPath="$RepoRoot/$sp"
                    if [ -f "$fullPath" ]; then
                        tSourcePayload=$((tSourcePayload + $(Get-Tokens "$fullPath")))
                        sourceFilesCount=$((sourceFilesCount + 1))
                    fi
                done
            fi
        done
    fi
fi

# Phases
declare -A phases
phases["Step 0: Preflight"]=$((tBaseline + tReqArtifacts))
phases["Phase 1: Validate Spec"]=$((tValidate + tReqArtifacts))
phases["Phase 2: Architect"]=$((tArchitect + tBaseline + tRag))
phases["Phase 3: Validate Arch"]=$((tValidate + tReqArtifacts + tTasks))
phases["Phase 3.5: TDD"]=$((tTdd + tReqArtifacts + tTasks))
phases["Phase 4: Implement"]=$((tProceed + tTasks + tBaseline / 2 + tSourcePayload))
phases["Phase 5: Verify"]=$((tReflect + tReview + tAgents + tTasks))
phases["Phase 6-7: PR + CI"]=$((tProceed / 4))
phases["Phase 7.5: Canary"]=$((tCanary))
phases["Phase 8: Wrapup"]=$((tWrapup + tRag))

keys=("Step 0: Preflight" "Phase 1: Validate Spec" "Phase 2: Architect" "Phase 3: Validate Arch" "Phase 3.5: TDD" "Phase 4: Implement" "Phase 5: Verify" "Phase 6-7: PR + CI" "Phase 7.5: Canary" "Phase 8: Wrapup")

totalInput=0
maxPhaseVal=-1
maxPhaseKey=""

phasesJson="{"
first=1
for k in "${keys[@]}"; do
    val=${phases["$k"]}
    totalInput=$((totalInput + val))
    if [ "$val" -gt "$maxPhaseVal" ]; then
        maxPhaseVal=$val
        maxPhaseKey=$k
    fi
    if [ $first -eq 0 ]; then phasesJson+=","; fi
    phasesJson+="\"$k\": $val"
    first=0
done
phasesJson+="}"

estOutput=$((totalInput * 27 / 100))
grandTotal=$((totalInput + estOutput))

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ $OutputJson -eq 1 ]; then
    cat <<EOF
{
    "reqId": "$normalizedReqId",
    "reqTitle": "$reqTitle",
    "estimatedAt": "$timestamp",
    "formula": "ceil(bytes / 4)",
    "taskCount": $taskCount,
    "phases": $phasesJson,
    "totalInputTokens": $totalInput,
    "estimatedOutputTokens": $estOutput,
    "estimatedGrandTotal": $grandTotal,
    "largestPhase": "$maxPhaseKey",
    "note": "Approximation only (~4 chars/token). Actual Copilot usage may vary ±20%."
}
EOF
    exit 0
fi

if [ -n "$normalizedReqId" ]; then
    header="$normalizedReqId - $reqTitle"
else
    header="Baseline Context Estimate (no REQ specified)"
fi

divider="--------------------------------------------------------------"
echo ""
echo -e "  \e[36m[TOKEN ESTIMATE] Copilot Forge\e[0m"
echo -e "  \e[97m$header\e[0m"
echo "  $divider"
printf "  \e[90m%-30s %12s  %6s\e[0m\n" "Phase" "Est. Tokens" "% Total"
echo "  $divider"

for k in "${keys[@]}"; do
    val=${phases["$k"]}
    pct=0
    if [ $totalInput -gt 0 ]; then pct=$((val * 1000 / totalInput)); fi
    pctWhole=$((pct / 10))
    pctDec=$((pct % 10))
    marker=$([ "$k" == "$maxPhaseKey" ] && echo " << largest" || echo "")
    
    printf "  %-30s %12s  %5s%%%s\n" "$(Pad "$k" 30)" "$(FmtN $val)" "${pctWhole}.${pctDec}" "$marker"
done

echo "  $divider"
printf "  \e[32m%-30s %12s  %6s\e[0m\n" "TOTAL Input Tokens" "$(FmtN $totalInput)" "100%"
printf "  \e[33m%-30s %12s\e[0m\n" "Est. Output Tokens (~27%)" "$(FmtN $estOutput)"
printf "  \e[36m%-30s %12s\e[0m\n" "Est. GRAND TOTAL" "$(FmtN $grandTotal)"
echo "  $divider"

if [ $taskCount -gt 0 ]; then echo -e "  \e[90mTasks in REQ: $taskCount\e[0m"; fi
if [ $sourceFilesCount -gt 0 ]; then echo -e "  \e[90mSource files identified: $sourceFilesCount (~$(FmtN $tSourcePayload) tokens)\e[0m"; fi
echo -e "  \e[90mAccuracy: +/-15-20%  |  Formula: ceil(bytes / 4)\e[0m"
echo ""

echo -e "  \e[36m>> Insights\e[0m"
printf "     Largest phase : %s (~%s tokens)\n" "$maxPhaseKey" "$(FmtN $maxPhaseVal)"

if [ ${phases["Phase 5: Verify"]} -gt 0 ]; then
    verifyPct=$(( phases["Phase 5: Verify"] * 100 / totalInput ))
    echo "     Phase 5 (Verify) loads all 6 agent checklists - accounts for ~$verifyPct% of input."
fi

if [ $tRag -gt 0 ]; then echo "     RAG knowledge retrieval contributes ~$(FmtN $tRag) tokens (top lessons + support docs)."; fi
if [ $tSourcePayload -gt 0 ]; then echo "     Variable payload: ~$(FmtN $tSourcePayload) tokens from $sourceFilesCount source files."; fi

echo ""

if [ $UpdatePipelineState -eq 1 ] && [ -n "$reqSpecDir" ]; then
    stateFile="$reqSpecDir/pipeline-state.json"
    if [ -f "$stateFile" ]; then
        if command -v jq >/dev/null 2>&1; then
            tokenBlock=$(cat <<EOF
{
    "estimatedAt": "$timestamp",
    "formula": "ceil(bytes / 4)",
    "taskCount": $taskCount,
    "phases": $phasesJson,
    "totalInputTokens": $totalInput,
    "estimatedOutputTokens": $estOutput,
    "estimatedGrandTotal": $grandTotal,
    "note": "Approximation only (~4 chars/token). Actual Copilot usage may vary ±20%."
}
EOF
)
            jq --argjson block "$tokenBlock" '. + {tokenEstimate: $block}' "$stateFile" > "$stateFile.tmp" && mv "$stateFile.tmp" "$stateFile"
            echo -e "  \e[32m[OK] Token estimate written to: $stateFile\e[0m\n"
        else
            echo -e "\e[33mWarning: jq is required to update pipeline-state.json from bash.\e[0m"
        fi
    else
        echo -e "\e[33mWarning: pipeline-state.json not found at $stateFile - skipping update.\e[0m"
    fi
fi
