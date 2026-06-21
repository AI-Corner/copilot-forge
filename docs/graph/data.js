const graphData = {
    "nodes": [
                    {
                        "id":  "#vibe",
                        "group":  "prompt"
                    },
                    {
                        "id":  "requirement-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#agents/db-perf-scanner",
                        "group":  "agent"
                    },
                    {
                        "id":  "#token-estimate",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#validate",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#template-drift",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/latency-scanner",
                        "group":  "agent"
                    },
                    {
                        "id":  "#agents/task-implementer",
                        "group":  "agent"
                    },
                    {
                        "id":  "#forge-admin",
                        "group":  "prompt"
                    },
                    {
                        "id":  "manual-qa-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#agents/architecture-mapper",
                        "group":  "agent"
                    },
                    {
                        "id":  "#bugfix",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#reflect",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/test-auditor",
                        "group":  "agent"
                    },
                    {
                        "id":  "#agents/api-cost-scanner",
                        "group":  "agent"
                    },
                    {
                        "id":  "lesson-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#sprint",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/quality-reviewer",
                        "group":  "agent"
                    },
                    {
                        "id":  "taxonomy-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "forge-test.ps1",
                        "group":  "script"
                    },
                    {
                        "id":  "#agents/security-auditor",
                        "group":  "agent"
                    },
                    {
                        "id":  "#spec",
                        "group":  "prompt"
                    },
                    {
                        "id":  "assumption-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#issue_epic_creation",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#security_scan",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#deploy",
                        "group":  "prompt"
                    },
                    {
                        "id":  "forge-context.ps1",
                        "group":  "script"
                    },
                    {
                        "id":  "#proceed",
                        "group":  "prompt"
                    },
                    {
                        "id":  "deployment-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "forge-gate.ps1",
                        "group":  "script"
                    },
                    {
                        "id":  "variables-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#tdd",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/code-quality-auditor",
                        "group":  "agent"
                    },
                    {
                        "id":  "#agents/architecture-reviewer",
                        "group":  "agent"
                    },
                    {
                        "id":  "#status",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/integration-explorer",
                        "group":  "agent"
                    },
                    {
                        "id":  "#wrapup",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#canary",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#review",
                        "group":  "prompt"
                    },
                    {
                        "id":  "env-local-template.env",
                        "group":  "template"
                    },
                    {
                        "id":  "adr-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#architect",
                        "group":  "prompt"
                    },
                    {
                        "id":  "support-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#query",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/correctness-reviewer",
                        "group":  "agent"
                    },
                    {
                        "id":  "#agents/convention-auditor",
                        "group":  "agent"
                    },
                    {
                        "id":  "task-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#optimize",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#init",
                        "group":  "prompt"
                    },
                    {
                        "id":  "bug-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "#agents/feature-tracer",
                        "group":  "agent"
                    },
                    {
                        "id":  "vibe-template.md",
                        "group":  "template"
                    },
                    {
                        "id":  "token-estimate.ps1",
                        "group":  "script"
                    },
                    {
                        "id":  "#analyze",
                        "group":  "prompt"
                    },
                    {
                        "id":  "#agents/reflector",
                        "group":  "agent"
                    }
    ],
    "links": [
                    {
                        "source":  "#analyze",
                        "target":  "#agents/code-quality-auditor",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#analyze",
                        "target":  "#agents/convention-auditor",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#analyze",
                        "target":  "#agents/security-auditor",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#analyze",
                        "target":  "#agents/test-auditor",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#architect",
                        "target":  "#agents/architecture-mapper",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#architect",
                        "target":  "#agents/feature-tracer",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#architect",
                        "target":  "#agents/integration-explorer",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#architect",
                        "target":  "adr-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#architect",
                        "target":  "forge-gate.ps1",
                        "type": "resource"
                    },
                    {
                        "source":  "#architect",
                        "target":  "task-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#bugfix",
                        "target":  "#canary",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#bugfix",
                        "target":  "#wrapup",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#bugfix",
                        "target":  "bug-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#bugfix",
                        "target":  "lesson-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#forge-admin",
                        "target":  "forge-gate.ps1",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "adr-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "assumption-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "bug-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "deployment-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "env-local-template.env",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "lesson-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "requirement-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "support-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "task-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "taxonomy-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#init",
                        "target":  "variables-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#issue_epic_creation",
                        "target":  "env-local-template.env",
                        "type": "resource"
                    },
                    {
                        "source":  "#optimize",
                        "target":  "#agents/api-cost-scanner",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#optimize",
                        "target":  "#agents/db-perf-scanner",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#optimize",
                        "target":  "#agents/latency-scanner",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#agents/reflector",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#agents/task-implementer",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#architect",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#canary",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#reflect",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#review",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#tdd",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#validate",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "#wrapup",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#proceed",
                        "target":  "forge-gate.ps1",
                        "type": "resource"
                    },
                    {
                        "source":  "#query",
                        "target":  "adr-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#query",
                        "target":  "assumption-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#query",
                        "target":  "lesson-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#query",
                        "target":  "manual-qa-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#query",
                        "target":  "support-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#reflect",
                        "target":  "#agents/reflector",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#reflect",
                        "target":  "#review",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#review",
                        "target":  "#agents/architecture-reviewer",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#review",
                        "target":  "#agents/correctness-reviewer",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#review",
                        "target":  "#agents/quality-reviewer",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#review",
                        "target":  "#agents/security-auditor",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#review",
                        "target":  "#agents/test-auditor",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#review",
                        "target":  "#wrapup",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#spec",
                        "target":  "#validate",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#spec",
                        "target":  "#vibe",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#spec",
                        "target":  "requirement-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#sprint",
                        "target":  "#proceed",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#token-estimate",
                        "target":  "token-estimate.ps1",
                        "type": "resource"
                    },
                    {
                        "source":  "#vibe",
                        "target":  "vibe-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "#security_scan",
                        "type": "behavioral"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "adr-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "assumption-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "lesson-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "manual-qa-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "support-template.md",
                        "type": "resource"
                    },
                    {
                        "source":  "#wrapup",
                        "target":  "token-estimate.ps1",
                        "type": "resource"
                    }
    ]
};
