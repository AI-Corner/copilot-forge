#!/usr/bin/env bash
# Scans and fixes encoding issues (BOM, U+FFFD) across the repo.
# Safe to run repeatedly — idempotent.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." > /dev/null 2>&1 && pwd)"
cd "$REPO_ROOT"

DRY_RUN=0
if [ "$1" = "-DryRun" ] || [ "$1" = "--dry-run" ]; then
    DRY_RUN=1
fi

FIXED=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    changed=0

    # Check for BOM (EF BB BF)
    first3=$(od -A n -t x1 -N 3 "$file" 2>/dev/null | tr -d ' \n' || true)
    if [ "$first3" = "efbbbf" ]; then
        changed=1
    fi

    # Check for U+FFFD (EF BF BD)
    if od -A n -t x1 "$file" 2>/dev/null | tr -d ' \n' | grep -q "efbfbd"; then
        changed=1
    fi

    if [ $changed -eq 1 ]; then
        rel="${file#$REPO_ROOT/}"
        if [ $DRY_RUN -eq 1 ]; then
            echo "WOULD FIX: $rel"
        else
            # Strip BOM
            if [ "$first3" = "efbbbf" ]; then
                tail -c +4 "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            fi
            # Remove U+FFFD (EF BF BD)
            if command -v perl > /dev/null 2>&1; then
                perl -i -pe 's/\x{FFFD}//g' "$file"
            elif command -v sed > /dev/null 2>&1; then
                sed -i "s/$(printf '\xef\xbf\xbd')//g" "$file"
            fi
            echo "FIXED: $rel"
        fi
        FIXED=$((FIXED + 1))
    fi
done < <(find . -type f \( -name "*.md" -o -name "*.ps1" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.txt" -o -name "*.html" -o -name "*.css" -o -name "*.js" \) -not -path "./.git/*" 2>/dev/null)

if [ $FIXED -eq 0 ]; then
    echo "All files clean — no issues found."
else
    if [ $DRY_RUN -eq 1 ]; then
        echo "$FIXED file(s) would be fixed."
    else
        echo "$FIXED file(s) fixed."
    fi
fi
