#!/usr/bin/env bash
set -e

# Defaults
ReqId=""
RepoRoot="$(pwd)"
MaxFailures=10

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -ReqId) ReqId="$2"; shift ;;
        -RepoRoot) RepoRoot="$2"; shift ;;
        -MaxFailures) MaxFailures="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

forgeDir="$RepoRoot/.forge"
outputFile="$forgeDir/.last-test-run.md"

# Helpers
Write-Header() { echo -e "\n  \e[36m[FORGE-TEST] $1\e[0m"; }
Write-Step()   { echo -e "  > \e[90m$1\e[0m"; }
Write-Ok()     { echo -e "  \e[32m[OK] $1\e[0m"; }
Write-Fail()   { echo -e "  \e[31m[FAIL] $1\e[0m"; }
Write-Warning(){ echo -e "  \e[33m[WARNING] $1\e[0m"; }

Write-Header "Detecting test runner..."

runner=""
runCmd=""
parseMode=""

if [ -f "$RepoRoot/package.json" ]; then
    if grep -q '"test"' "$RepoRoot/package.json"; then
        runCmd="npm test -- --reporter=json 2>&1"
        runner="npm/jest-vitest"
        parseMode="json"
    fi
    Write-Step "Detected: $runner (package.json)"
elif [ -f "$RepoRoot/pom.xml" ]; then
    runCmd="mvn test -q 2>&1"
    runner="maven"
    parseMode="text"
    Write-Step "Detected: Maven (pom.xml)"
elif [ -f "$RepoRoot/build.gradle" ]; then
    runCmd="./gradlew test 2>&1"
    runner="gradle"
    parseMode="text"
    Write-Step "Detected: Gradle (build.gradle)"
elif [ -f "$RepoRoot/pyproject.toml" ] || [ -f "$RepoRoot/setup.py" ]; then
    runCmd="pytest --tb=short -q 2>&1"
    runner="pytest"
    parseMode="text"
    Write-Step "Detected: pytest"
else
    Write-Warning "No supported test runner detected."
fi

if [ -z "$runCmd" ]; then
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    mkdir -p "$forgeDir"
    cat <<EOF > "$outputFile"
---
req: $ReqId
runner: unknown
status: skipped
timestamp: $timestamp
---

## Test Run: SKIPPED

No supported test runner was detected in the repository root.

**Action required**: Configure a test runner (npm test, mvn test, pytest, etc.) and re-run \`forge-test.sh\`.
EOF
    Write-Warning "Output written to $outputFile"
    exit 0
fi

Write-Header "Running: $runCmd"

startTime=$(date +%s)
cd "$RepoRoot" || exit 1

set +e
rawOutput=$(eval "$runCmd")
exitCode=$?
set -e

endTime=$(date +%s)
durationMs=$(( (endTime - startTime) * 1000 ))

Write-Header "Parsing results..."

totalTests=0
passed=0
failed=0
skipped=0
failures=()

if [ "$parseMode" == "json" ]; then
    jsonLine=$(echo "$rawOutput" | grep '^{.*"testResults".*}$' || true)
    if [ -n "$jsonLine" ]; then
        if command -v jq >/dev/null 2>&1; then
            totalTests=$(echo "$jsonLine" | jq -r '.numTotalTests // 0')
            passed=$(echo "$jsonLine" | jq -r '.numPassedTests // 0')
            failed=$(echo "$jsonLine" | jq -r '.numFailedTests // 0')
            skipped=$(echo "$jsonLine" | jq -r '.numPendingTests // 0')
            
            fail_msgs=$(echo "$jsonLine" | jq -r --arg max "$MaxFailures" '.testResults[]? | .testResults[]? | select(.status == "failed") | "- **\(.fullName)** — \(.failureMessages | join(" ") | gsub("\n"; " ") | gsub("\\s+"; " "))"' | head -n "$MaxFailures" | cut -c 1-200 || true)
            while IFS= read -r line; do
                if [ -n "$line" ]; then failures+=("$line..."); fi
            done <<< "$fail_msgs"
        else
            Write-Warning "jq not found. Falling back to text parsing."
            parseMode="text"
        fi
    else
        parseMode="text"
    fi
fi

if [ "$parseMode" == "text" ]; then
    mavenSummary=$(echo "$rawOutput" | grep -E "Tests run:\s*[0-9]+,\s*Failures:\s*[0-9]+" || true)
    if [ -n "$mavenSummary" ]; then
        while IFS= read -r line; do
            if [[ "$line" =~ Tests\ run:\ *([0-9]+),\ *Failures:\ *([0-9]+),\ *Errors:\ *([0-9]+),\ *Skipped:\ *([0-9]+) ]]; then
                totalTests=$((totalTests + BASH_REMATCH[1]))
                failed=$((failed + BASH_REMATCH[2] + BASH_REMATCH[3]))
                skipped=$((skipped + BASH_REMATCH[4]))
            fi
        done <<< "$mavenSummary"
        passed=$((totalTests - failed - skipped))
    fi

    if echo "$rawOutput" | grep -q "[0-9]\+ passed"; then
        if [[ "$rawOutput" =~ ([0-9]+)\ passed ]]; then passed=${BASH_REMATCH[1]}; fi
        if [[ "$rawOutput" =~ ([0-9]+)\ failed ]]; then failed=${BASH_REMATCH[1]}; fi
        totalTests=$((passed + failed))
    fi

    failLines=$(echo "$rawOutput" | grep -E "FAILED|ERROR|AssertionError|expected|but was" | head -n "$MaxFailures" || true)
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            clean=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+/ /g' | cut -c 1-200)
            failures+=("- $clean")
        fi
    done <<< "$failLines"
fi

status=$([ "$exitCode" -eq 0 ] && echo "PASS" || echo "FAIL")
statusEmoji=$([ "$status" == "PASS" ] && echo "✅" || echo "❌")
truncNote=$([ ${#failures[@]} -ge $MaxFailures ] && echo "\n> _Showing first $MaxFailures failures. Run tests locally for full output._" || echo "")

failureBlock="_No individual failure details extracted._"
if [ ${#failures[@]} -gt 0 ]; then
    failureBlock=$(printf "%s\n" "${failures[@]}")
fi

mkdir -p "$forgeDir"
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat <<EOF > "$outputFile"
---
req: $ReqId
runner: $runner
status: $status
exit_code: $exitCode
timestamp: $timestamp
duration_ms: $durationMs
total: $totalTests
passed: $passed
failed: $failed
skipped: $skipped
---

## Test Run: $statusEmoji $status

| Metric | Value |
|---|---|
| Runner | \`$runner\` |
| Total | $totalTests |
| ✅ Passed | $passed |
| ❌ Failed | $failed |
| ⏭ Skipped | $skipped |
| Duration | ${durationMs}ms |

## Failures
$failureBlock
$truncNote

## Agent Instructions
EOF

if [ "$status" == "PASS" ]; then
    echo "All tests are passing. The Red Phase is complete — you may now proceed to the Green Phase (implementation)." >> "$outputFile"
else
    echo "Fix the failures listed above, then re-run \`./scripts/forge-test.sh\` to verify. Do NOT proceed to implementation until this file reports status: PASS." >> "$outputFile"
fi

echo -e "\n  \e[90m─────────────────────────────────────────\e[0m"
if [ "$status" == "PASS" ]; then
    Write-Ok "All tests passed ($passed / $totalTests) in ${durationMs}ms"
else
    Write-Fail "$failed test(s) failed out of $totalTests in ${durationMs}ms"
    echo ""
    for f in "${failures[@]}"; do
        echo -e "    \e[33m$f\e[0m"
    done
fi
echo -e "  \e[90m─────────────────────────────────────────\e[0m"
echo -e "  \e[90mSummary written to: $outputFile\e[0m\n"

exit $exitCode
