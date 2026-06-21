<#
.SYNOPSIS
Generates a dynamic dependency graph for Copilot Forge.
.DESCRIPTION
Scans prompts, templates, and scripts for dependencies and exports them as a JSON for the D3 frontend,
and as a native Mermaid flowchart.
#>

$ErrorActionPreference = "Stop"
$ForgeRoot = (Resolve-Path "$PSScriptRoot\..").Path

$nodes = @{}
$links = @()

# Helpers
function Add-Node($id, $group) {
    if (-not $script:nodes.ContainsKey($id)) {
        $script:nodes[$id] = @{ id = $id; group = $group }
    }
}

function Add-Link($source, $target, $type) {
    if ($source -ne $target) {
        $script:links += [pscustomobject]@{ source = $source; target = $target; type = $type }
    }
}

Write-Host "Scanning Copilot Forge directory..."

# Scan all files for Internal Reference blocks
$files = @()
$files += Get-ChildItem -Path "$ForgeRoot\.github\prompts" -Filter "*.prompt.md" -Recurse
$files += Get-ChildItem -Path "$ForgeRoot\templates" -File -Recurse
$files += Get-ChildItem -Path "$ForgeRoot\scripts" -Filter "*.ps1" -Recurse

foreach ($file in $files) {
    $path = $file.FullName
    $id = $null
    $group = $null

    if ($path -match "\\\.github\\prompts\\agents\\(.*)\.prompt\.md$") {
        $id = "#agents/" + $matches[1]; $group = "agent"
    } elseif ($path -match "\\\.github\\prompts\\(.*)\.prompt\.md$") {
        $id = "#" + $matches[1]; $group = "prompt"
    } elseif ($path -match "\\templates\\(.*)(\.md|\.env)$") {
        $id = $matches[1] + $matches[2]; $group = "template"
    } elseif ($path -match "\\scripts\\(.*)\.ps1$") {
        $id = $matches[1] + ".ps1"; $group = "script"
    }

    if (-not $id) { continue }
    
    # Skip utility scripts
    if ($id -match "^(generate-graph|install)\.ps1$") {
        continue
    }

    Add-Node $id $group

    $content = Get-Content $file.FullName -Raw
    
    # Parse Outgoing Dependencies (Skill and Agent)
    $outgoingMatches = [regex]::Matches($content, "(?m)^- \*\*Outgoing (?:Skill|Agent) Dependencies\*\*: (.*)$")
    foreach ($m in $outgoingMatches) {
        $outStr = $m.Groups[1].Value.Trim()
        if ($outStr -ne "*None*") {
            $deps = [regex]::Matches($outStr, '`([^`]+)`').Value | ForEach-Object { $_ -replace '`', '' }
            foreach ($dep in $deps) {
                # Behavioral dependencies are almost exclusively prompts or agents
                $tgtGroup = "prompt"
                if ($dep -match "^#agents/") { $tgtGroup = "agent" }
                elseif ($dep -match "\.ps1$") { $tgtGroup = "script" }
                elseif ($dep -match "(\.md|\.env)$") { $tgtGroup = "template" }
                
                Add-Node $dep $tgtGroup
                Add-Link $id $dep "behavioral"
            }
        }
    }

    # Parse Resource Dependencies
    if ($content -match "(?m)^- \*\*Resource Dependencies\*\*: (.*)$") {
        $resStr = $matches[1].Trim()
        if ($resStr -ne "*None*") {
            $deps = [regex]::Matches($resStr, '`([^`]+)`').Value | ForEach-Object { $_ -replace '`', '' }
            foreach ($dep in $deps) {
                $tgtGroup = "prompt"
                if ($dep -match "^#agents/") { $tgtGroup = "agent" }
                elseif ($dep -match "\.ps1$") { $tgtGroup = "script" }
                elseif ($dep -match "(\.md|\.env)$") { $tgtGroup = "template" }
                
                Add-Node $dep $tgtGroup
                Add-Link $id $dep "resource"
            }
        }
    }
}

# Remove duplicate links
$uniqueLinks = $links | Sort-Object source, target -Unique

# Generate JS data structure
$jsNodes = $nodes.Values | ForEach-Object {
    @"
                    {
                        "id":  "$($_.id)",
                        "group":  "$($_.group)"
                    }
"@
}
$jsNodesStr = $jsNodes -join ",`r`n"

$jsLinks = $uniqueLinks | ForEach-Object {
    @"
                    {
                        "source":  "$($_.source)",
                        "target":  "$($_.target)",
                        "type": "$($_.type)"
                    }
"@
}
$jsLinksStr = $jsLinks -join ",`r`n"

$outJsPath = "$ForgeRoot\docs\graph\data.js"
$outDir = Split-Path $outJsPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$jsStr = @"
const graphData = {
    "nodes": [
$jsNodesStr
    ],
    "links": [
$jsLinksStr
    ]
};
"@
$jsStr | Set-Content $outJsPath
Write-Host "Exported JS graph data to $outJsPath"

# Generate Mermaid
$mermaidStr = "graph TD`n"
foreach ($link in $uniqueLinks) {
    $src = $link.source
    $tgt = $link.target
    
    # Format for mermaid
    $srcClean = $src -replace '#', '' -replace '\.', '_' -replace '-', '_'
    $tgtClean = $tgt -replace '#', '' -replace '\.', '_' -replace '-', '_'
    
    $arrow = if ($link.type -eq "resource") { "-.->" } else { "-->" }
    $mermaidStr += "    $srcClean(`"$src`") $arrow $tgtClean(`"$tgt`")`n"
}

# Add styles based on group
foreach ($node in $nodes.Values) {
    $idClean = $node.id -replace '#', '' -replace '\.', '_' -replace '-', '_'
    if ($node.group -eq "prompt") {
        $mermaidStr += "    style $idClean fill:#d4edda,stroke:#28a745,color:#155724`n"
    } elseif ($node.group -eq "agent") {
        $mermaidStr += "    style $idClean fill:#e2d9f3,stroke:#6f42c1,color:#381c63`n"
    } elseif ($node.group -eq "script") {
        $mermaidStr += "    style $idClean fill:#cce5ff,stroke:#007bff,color:#004085`n"
    } elseif ($node.group -eq "template") {
        $mermaidStr += "    style $idClean fill:#fff3cd,stroke:#ffc107,color:#856404`n"
    }
}

$outMermaidPath = "$ForgeRoot\.forge\knowledge\forge-dependency-graph.md"
$mermaidDir = Split-Path $outMermaidPath
if (-not (Test-Path $mermaidDir)) {
    New-Item -ItemType Directory -Path $mermaidDir | Out-Null
}

$mermaidContent = "# Copilot Forge Dependency Graph`n`nAuto-generated by \`scripts/generate-graph.ps1\`.`n`n``````mermaid`n$mermaidStr`n``````"

$mermaidContent | Set-Content $outMermaidPath
Write-Host "Exported Mermaid graph to $outMermaidPath"
