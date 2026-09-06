# Copilot Forge — Sanity Check Runbook

> Run this periodically (or before any major release) to ensure the toolkit is consistent, compliant, and drift-free.
>
> **Automated checks** → run `scripts/forge-sanity.ps1`
> **AI-agent checks** → follow the prompts in Section 2 below

---

## Section 1: Automated Checks (run `forge-sanity.ps1`)

These are deterministic and script-enforced. Run:

```powershell
.\scripts\forge-sanity.ps1
```

The script will automatically verify:

| # | Check | What it validates |
|---|---|---|
| 1 | **Prompt frontmatter** | Every `.prompt.md` must start with `---` on line 1, contain `agent:`, `tools:`, and `description:` fields |
| 2 | **Duplicate content detection** | No prompt file should contain two copies of the same phase/section header |
| 3 | **Agent frontmatter delimiter** | Every file in `agents/`, `agents/computational/`, and `agents/inferential/` must start with `---` |
| 4 | **Template presence** | All canonical templates in `templates/` must exist and be non-empty |
| 5 | **Context file presence** | All `.forge/context/corpus/*.md` and `.forge/context/rules/*.rules.md` must exist |
| 6 | **Knowledge index integrity** | Every file listed in `.forge/knowledge/support/_index.md` must exist on disk |
| 7 | **Script presence** | All expected scripts in `scripts/` must exist |
| 8 | **YAML frontmatter on knowledge docs** | Every file in `.forge/knowledge/lessons/` and `.forge/knowledge/support/` must have `id:`, `title:`, `tags:` frontmatter |
| 9 | **Encoding check** | Scan for Unicode replacement character (U+FFFD) mojibake in all markdown files |
| 10 | **Ethos reference** | Every main prompt must contain a reference to `.github/copilot-instructions.md` |

---

## Section 2: AI-Agent Checks (run manually in Copilot Chat)

These checks require LLM inference and cannot be automated with a script.

### Check A — Knowledge Misclassification Audit
Runs an AI audit of every file in `lessons/` and `support/` to detect any that are in the wrong folder.

```
#forge-admin Audit the files in .forge/knowledge/lessons and .forge/knowledge/support. Read the contents of each file and identify any misclassifications. Flag any file in "lessons" that reads like a "how-to" support guide, and flag any file in "support" that reads like a historical ADR or lesson.
```

### Check B — Template Drift
Detects if the templates in a consumer project's `.forge/templates/` have drifted from the canonical `templates/` in this toolkit.

```
#forge-template-drift
```

### Check C — Convention Drift
Checks if the codebase or context files have drifted away from the conventions documented in `.forge/context/corpus/conventions.md`.

```
#forge-check-drift
```

### Check D — Incremental Analysis
Analyzes files changed since the last recorded commit to see if `architecture.md` or `conventions.md` need to be updated to reflect those changes.

```
#forge-analyze
```

### Check E — Dependency Graph Freshness
Re-generates the dependency graph from all prompt `Internal Reference` blocks to verify all edges are up to date.

```powershell
.\scripts\generate-graph.ps1
```
Then visually inspect `docs/graph/index.html` for stale nodes.

---

## Section 3: Manual Visual Checks

These require a human eye.

| # | Check |
|---|---|
| 1 | Open `docs/graph/index.html` in a browser and verify there are no orphaned nodes (nodes with no edges) |
| 2 | Verify the Mermaid diagram in `.forge/context/project-overview.md` renders correctly in GitHub or VS Code preview |
| 3 | Spot-check 2–3 recent REQ spec files in `.forge/specs/` to verify they follow the `requirement-template.md` shape |

---

## Reporting

After each sanity check run, save the output report to:
```
sanity-checks/sanity-check-report-YYYY-MM-DD.md
```
