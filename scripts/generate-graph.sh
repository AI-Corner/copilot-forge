#!/usr/bin/env bash
set -e

ForgeRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export LC_ALL=C

declare -A nodes_id
declare -A nodes_group
declare -A links_map

add_node() {
    local id="$1"
    local group="$2"
    if [ -z "${nodes_id["$id"]}" ]; then
        nodes_id["$id"]="$id"
        nodes_group["$id"]="$group"
    fi
}

add_link() {
    local source="$1"
    local target="$2"
    local type="$3"
    if [ "$source" != "$target" ]; then
        links_map["$source|$target|$type"]="1"
    fi
}

echo "Scanning Copilot Forge directory..."

# Collect all files
files=()
while IFS= read -r file; do files+=("$file"); done < <(find "$ForgeRoot/.github/prompts" -type f -name "*.prompt.md" 2>/dev/null || true)
while IFS= read -r file; do files+=("$file"); done < <(find "$ForgeRoot/templates" -type f 2>/dev/null || true)
while IFS= read -r file; do files+=("$file"); done < <(find "$ForgeRoot/scripts" -type f -name "*.sh" 2>/dev/null || true)
while IFS= read -r file; do files+=("$file"); done < <(find "$ForgeRoot/scripts" -type f -name "*.ps1" 2>/dev/null || true)

for path in "${files[@]}"; do
    id=""
    group=""
    
    if [[ "$path" =~ \.github/prompts/agents/([^/]+)\.prompt\.md$ ]]; then
        id="#agents/${BASH_REMATCH[1]}"; group="agent"
    elif [[ "$path" =~ \.github/prompts/([^/]+)\.prompt\.md$ ]]; then
        id="#${BASH_REMATCH[1]}"; group="prompt"
    elif [[ "$path" =~ templates/([^/]+\.(md|env))$ ]]; then
        id="${BASH_REMATCH[1]}"; group="template"
    elif [[ "$path" =~ scripts/([^/]+\.(sh|ps1))$ ]]; then
        id="${BASH_REMATCH[1]}"; group="script"
    fi

    if [ -z "$id" ]; then continue; fi
    
    if [[ "$id" =~ ^(generate-graph|install)\.(sh|ps1)$ ]]; then continue; fi

    add_node "$id" "$group"

    content=$(cat "$path")
    
    # Outgoing Dependencies
    outgoing=$(echo "$content" | grep -E "^- \*\*Outgoing (Skill|Agent) Dependencies\*\*: " || true)
    if [ -n "$outgoing" ]; then
        while IFS= read -r line; do
            outStr=$(echo "$line" | sed -E 's/^- \*\*Outgoing (Skill|Agent) Dependencies\*\*: //')
            if [ "$outStr" != "*None*" ]; then
                deps=$(echo "$outStr" | grep -o '`[^`]\+`' | tr -d '`' || true)
                for dep in $deps; do
                    tgtGroup="prompt"
                    if [[ "$dep" =~ ^#agents/ ]]; then tgtGroup="agent"
                    elif [[ "$dep" =~ \.(sh|ps1)$ ]]; then tgtGroup="script"
                    elif [[ "$dep" =~ \.(md|env)$ ]]; then tgtGroup="template"
                    fi
                    add_node "$dep" "$tgtGroup"
                    add_link "$id" "$dep" "behavioral"
                done
            fi
        done <<< "$outgoing"
    fi

    # Resource Dependencies
    resLine=$(echo "$content" | grep -E "^- \*\*Resource Dependencies\*\*: " || true)
    if [ -n "$resLine" ]; then
        while IFS= read -r line; do
            resStr=$(echo "$line" | sed -E 's/^- \*\*Resource Dependencies\*\*: //')
            if [ "$resStr" != "*None*" ]; then
                deps=$(echo "$resStr" | grep -o '`[^`]\+`' | tr -d '`' || true)
                for dep in $deps; do
                    tgtGroup="prompt"
                    if [[ "$dep" =~ ^#agents/ ]]; then tgtGroup="agent"
                    elif [[ "$dep" =~ \.(sh|ps1)$ ]]; then tgtGroup="script"
                    elif [[ "$dep" =~ \.(md|env)$ ]]; then tgtGroup="template"
                    fi
                    add_node "$dep" "$tgtGroup"
                    add_link "$id" "$dep" "resource"
                done
            fi
        done <<< "$resLine"
    fi

    # Inline Dependencies
    inlineDeps=$(echo "$content" | grep -oE '(#agents/[a-zA-Z0-9/-]+|#forge-[a-zA-Z0-9-]+)' || true)
    for dep in $inlineDeps; do
        if [ "$dep" == "$id" ]; then continue; fi
        tgtGroup="prompt"
        if [[ "$dep" =~ ^#agents/ ]]; then tgtGroup="agent"; fi
        add_node "$dep" "$tgtGroup"
        add_link "$id" "$dep" "behavioral"
    done
done

# Generate JS data
jsNodes=""
first=1
for id in "${!nodes_id[@]}"; do
    group="${nodes_group[$id]}"
    if [ $first -eq 0 ]; then jsNodes+=$',\n'; fi
    jsNodes+="                    { \"id\": \"$id\", \"group\": \"$group\" }"
    first=0
done

jsLinks=""
first=1
for key in "${!links_map[@]}"; do
    IFS='|' read -r source target type <<< "$key"
    if [ $first -eq 0 ]; then jsLinks+=$',\n'; fi
    jsLinks+="                    { \"source\": \"$source\", \"target\": \"$target\", \"type\": \"$type\" }"
    first=0
done

outJsPath="$ForgeRoot/docs/graph/data.js"
mkdir -p "$(dirname "$outJsPath")"

cat <<EOF > "$outJsPath"
const graphData = {
    "nodes": [
$jsNodes
    ],
    "links": [
$jsLinks
    ]
};
EOF
echo "Exported JS graph data to $outJsPath"

# Generate Mermaid
mermaidStr="graph TD\n"
for key in "${!links_map[@]}"; do
    IFS='|' read -r source target type <<< "$key"
    srcClean=$(echo "$source" | sed -e 's/#//g' -e 's/\./_/g' -e 's/-/_/g')
    tgtClean=$(echo "$target" | sed -e 's/#//g' -e 's/\./_/g' -e 's/-/_/g')
    arrow=$([ "$type" == "resource" ] && echo "-.->" || echo "-->")
    mermaidStr+="    $srcClean(\"$source\") $arrow $tgtClean(\"$target\")\n"
done

for id in "${!nodes_id[@]}"; do
    group="${nodes_group[$id]}"
    idClean=$(echo "$id" | sed -e 's/#//g' -e 's/\./_/g' -e 's/-/_/g')
    if [ "$group" == "prompt" ]; then
        mermaidStr+="    style $idClean fill:#d4edda,stroke:#28a745,color:#155724\n"
    elif [ "$group" == "agent" ]; then
        mermaidStr+="    style $idClean fill:#e2d9f3,stroke:#6f42c1,color:#381c63\n"
    elif [ "$group" == "script" ]; then
        mermaidStr+="    style $idClean fill:#cce5ff,stroke:#007bff,color:#004085\n"
    elif [ "$group" == "template" ]; then
        mermaidStr+="    style $idClean fill:#fff3cd,stroke:#ffc107,color:#856404\n"
    fi
done

outMermaidPath="$ForgeRoot/.forge/knowledge/forge-dependency-graph.md"
mkdir -p "$(dirname "$outMermaidPath")"

echo -e "# Copilot Forge Dependency Graph\n\nAuto-generated by \`scripts/generate-graph.sh\`.\n\n\`\`\`mermaid\n$mermaidStr\n\`\`\`" > "$outMermaidPath"
echo "Exported Mermaid graph to $outMermaidPath"
