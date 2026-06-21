# Context Budget Guide

> **Severity: 🔵 RULE**
> Standard operating procedure.

1. **Read Enough, No More**: Do not blindly dump entire large files into context if you only need a specific function. Use symbol search or read specific line ranges when possible.
2. **Respect the Token Limit**: Be mindful of the context window size. If a file is over 1000 lines long, consider whether you truly need to read the whole thing or just the interface/headers.
3. **Prune Stale Context**: If you have opened many files during an investigation, mentally drop the ones that proved irrelevant before formulating your final plan.
