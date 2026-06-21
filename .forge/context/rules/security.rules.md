# Security Rules

1. **No Hardcoded Secrets**: Ensure no Personal Access Tokens (e.g., `glpat-`, `ghp_`, `xoxb-`), API Keys (e.g., `AIZA...`, `sk-...`), or Private Keys (`-----BEGIN RSA PRIVATE KEY-----`) are committed.
2. **Verification**: Always run `git diff --cached` and scan for secrets before committing. 
3. **User Confirmation**: Any potential secret must be explicitly verified or removed by the user before proceeding. Do not assume any value is a false positive without confirmation.
