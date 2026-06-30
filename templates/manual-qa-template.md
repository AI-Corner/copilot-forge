# Manual QA Guide: {Feature Name}

> **Note to AI**: Keep all sections extremely concise (short bullet points). Omit any sections that are not strictly relevant.

*REQ ID: {REQ-xxx}*
*Status: Draft / Final*

## 🎯 Objective
Briefly describe what this manual test is intended to verify. (Keep to 1-2 short sentences max)

## 🛠️ Prerequisites
- Environment (Local / Dev / Staging)
- Required permissions / credentials
- Initial state (e.g., "User must be logged out", "Database must be empty")

## 🧪 Test Steps
| Step # | Action | Expected Result |
| :--- | :--- | :--- |
| 1 | {Action} | {Expected outcome} |
| 2 | {Action} | {Expected outcome} |
| 3 | {Action} | {Expected outcome} |

## 💡 Verification Commands
```bash
# Example curl, grpcurl, or CLI commands
{command}
```

## ⚠️ Edge Cases to Verify (List a maximum of 3 core edge cases)
- [ ] {Edge case 1}
- [ ] {Edge case 2}

## 📝 Findings / Notes
(Space for the manual tester to leave comments or attach screenshots)

## Internal Reference
- **Incoming Dependencies**: `#forge-query`, `#forge-wrapup`
- **Outgoing Dependencies**: *None*
- **Resource Dependencies**: *None*