#!/usr/bin/env bash
set -e

# Parse arguments
Phase=""
ReqId=""
RepoRoot="$(pwd)"
Force=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -Phase) Phase="$2"; shift ;;
        -ReqId) ReqId="$2"; shift ;;
        -RepoRoot) RepoRoot="$2"; shift ;;
        -Force) Force=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$Phase" ]; then
    echo "Error: -Phase is required."
    exit 1
fi

if [[ ! "$Phase" =~ ^(spec|architect|tdd|reflect|review|wrapup)$ ]]; then
    echo "Error: -Phase must be one of: spec, architect, tdd, reflect, review, wrapup"
    exit 1
fi

divider="--------------------------------------------------------"

# Helpers
Pass() {
    echo ""
    echo -e "  \e[32m✓ GATE PASSED [$Phase]\e[0m"
    echo -e "  \e[90m$1\e[0m"
    echo ""
}

Fail() {
    echo ""
    echo -e "  \e[90m$divider\e[0m"
    echo -e "  \e[31m⛔ GATE FAILED [$Phase]\e[0m"
    echo -e "  \e[33m$1\e[0m"
    if [ -n "$2" ]; then
        echo ""
        echo -e "  \e[36mRemedy: $2\e[0m"
    fi
    echo -e "  \e[90m$divider\e[0m"
    echo ""
    exit 1
}

Warn() {
    echo -e "  \e[33m⚠  $1\e[0m"
}

Get-ReqFile() {
    local specsRoot="$RepoRoot/.forge/specs"
    if [ ! -d "$specsRoot" ]; then return; fi

    if [ -n "$ReqId" ]; then
        local num=$(echo "$ReqId" | sed 's/[^0-9]//g')
        local normalized=$(printf "REQ-%03d" "$num")
        local dir=$(find "$specsRoot" -type d -name "$normalized-*" 2>/dev/null | head -n 1)
        if [ -n "$dir" ] && [ -f "$dir/requirement.md" ]; then
            echo "$dir/requirement.md"
            return
        fi
    fi

    if [ "$(uname)" == "Darwin" ]; then
        find "$specsRoot" -type f -name "requirement.md" -exec stat -f "%m %N" {} + 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true
    else
        find "$specsRoot" -type f -name "requirement.md" -exec stat -c "%Y %n" {} + 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2- || true
    fi
}

Get-FrontmatterValue() {
    local filePath="$1"
    local key="$2"
    awk -v k="$key" '
        /^---$/ { if(in_fm) exit; else in_fm=1; next }
        in_fm && $0 ~ "^" k "[[:space:]]*:" {
            sub("^" k "[[:space:]]*:[[:space:]]*", "")
            gsub(/^["\047]|["\047]$/, "")
            gsub(/\r/, "")
            print
            exit
        }
    ' "$filePath"
}

Log-ForcedTransition() {
    local reqSpecDir="$1"
    if [ -z "$reqSpecDir" ]; then return; fi
    local stateFile="$reqSpecDir/pipeline-state.json"
    if [ ! -f "$stateFile" ]; then return; fi
    
    if command -v jq >/dev/null 2>&1; then
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local operator="${USER:-$USERNAME}"
        local entry="{\"phase\":\"$Phase\",\"timestamp\":\"$timestamp\",\"operator\":\"$operator\",\"note\":\"Gate bypassed with --Force flag\"}"
        
        jq --argjson newEntry "$entry" '
            if has("forcedTransitions") then
                .forcedTransitions += [$newEntry]
            else
                . + {forcedTransitions: [$newEntry]}
            end
        ' "$stateFile" > "$stateFile.tmp" && mv "$stateFile.tmp" "$stateFile"
        Warn "Forced transition logged to pipeline-state.json"
    else
        Warn "Could not log forced transition: jq not found"
    fi
}

if [ $Force -eq 1 ]; then
    Warn "FORCE flag set — bypassing gate for phase: $Phase"
    reqFile=$(Get-ReqFile)
    reqSpecDir=$([ -n "$reqFile" ] && dirname "$reqFile" || echo "")
    Log-ForcedTransition "$reqSpecDir"
    echo -e "  \e[33mProceeding under --Force. This transition has been logged.\e[0m\n"
    exit 0
fi

echo ""
echo -e "  \e[36m[FORGE-GATE] Checking: $Phase\e[0m"
echo -e "  \e[90m$divider\e[0m"

case "$Phase" in
    "spec")
        overview="$RepoRoot/.forge/context/project-overview.md"
        if [ ! -f "$overview" ]; then
            Fail ".forge/context/project-overview.md not found." "Run #forge-init to initialize the .forge/ structure."
        fi
        Pass "project-overview.md exists. Safe to run #forge-spec."
        ;;
    "architect")
        reqFile=$(Get-ReqFile)
        if [ -z "$reqFile" ] || [ ! -f "$reqFile" ]; then
            Fail "No requirement.md found under .forge/specs/." "Run #forge-spec first to create a requirement."
        fi
        status=$(Get-FrontmatterValue "$reqFile" "status")
        if [ "$status" == "complete" ]; then
            Fail "Requirement '$(basename "$reqFile")' is already complete." "Start a new #forge-spec for a new requirement."
        fi
        if [ "$status" != "draft" ] && [ "$status" != "approved" ]; then
            Fail "Requirement status is '$status'. Expected: draft or approved." "Check the requirement.md frontmatter."
        fi
        Pass "$(basename "$reqFile") | status: $status"
        ;;
    "tdd")
        reqFile=$(Get-ReqFile)
        if [ -z "$reqFile" ] || [ ! -f "$reqFile" ]; then
            Fail "No requirement.md found." "Run #forge-spec and #forge-architect first."
        fi
        status=$(Get-FrontmatterValue "$reqFile" "status")
        if [ "$status" != "approved" ]; then
            Fail "Requirement status is '$status'. Must be 'approved' to write tests." "Run #forge-architect to approve the requirement."
        fi
        taskDir="$(dirname "$reqFile")/tasks"
        taskCount=$(find "$taskDir" -name "TASK-*.md" 2>/dev/null | wc -l || echo 0)
        taskCount=$((taskCount))
        if [ "$taskCount" -eq 0 ]; then
            Fail "No TASK-*.md files found in $taskDir." "Run #forge-architect to generate tasks first."
        fi
        Pass "$(basename "$reqFile") | status: $status | tasks: $taskCount"
        ;;
    "reflect"|"review")
        cd "$RepoRoot" || exit 1
        diff=$(git diff main...HEAD --name-only 2>&1 || true)
        if [ -z "$(echo "$diff" | tr -d ' \n')" ]; then
            Fail "No changes detected vs main. Nothing to $Phase." "Make sure you are on a feature branch with committed changes."
        fi
        fileCount=$(echo "$diff" | grep -c "^" || echo 0)
        Pass "$fileCount changed file(s) detected vs main. Safe to $Phase."
        ;;
    "wrapup")
        reqFile=$(Get-ReqFile)
        if [ -z "$reqFile" ] || [ ! -f "$reqFile" ]; then
            Fail "No requirement.md found. Nothing to wrap up." ""
        fi
        status=$(Get-FrontmatterValue "$reqFile" "status")
        if [ "$status" == "complete" ]; then
            Warn "Requirement is already marked complete. Proceeding (idempotent wrapup)."
        fi
        taskDir="$(dirname "$reqFile")/tasks"
        tasks=()
        while IFS= read -r f; do
            if [ -n "$f" ]; then tasks+=("$f"); fi
        done < <(find "$taskDir" -name "TASK-*.md" 2>/dev/null || true)
        
        if [ ${#tasks[@]} -eq 0 ]; then
            Fail "No task files found in $taskDir." "Run #forge-architect first."
        fi
        
        incomplete=()
        for t in "${tasks[@]}"; do
            ts=$(Get-FrontmatterValue "$t" "status")
            if [ "$ts" != "complete" ]; then
                incomplete+=("    - $(basename "$t")")
            fi
        done
        
        if [ ${#incomplete[@]} -gt 0 ]; then
            names=$(printf "%s\n" "${incomplete[@]}")
            Fail "${#incomplete[@]} task(s) not yet complete:\n$names" "Complete all tasks before running #forge-wrapup."
        fi
        Pass "${#tasks[@]} tasks — all complete. Safe to wrap up."
        ;;
esac
