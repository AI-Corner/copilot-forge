# Copilot Forge — Frequently Asked Questions (FAQ)

### 1. Will running `#spec` or `#analyze` consume a huge amount of tokens by reading all my docs every time?
**No.** Copilot Forge is specifically engineered to be extremely token-efficient.
- **It reads summaries, not raw code:** The `.forge/context/` files (like `architecture.md` and `project-overview.md`) are explicitly designed to be high-level summaries. Reading these takes a fraction of the tokens compared to standard Copilot attempting to read your entire raw codebase.
- **Built-in Retrieval Augmented Generation (RAG):** When searching your past specs, bugs, or lessons learned, the agent acts like a search engine. It first parses your prompt to generate search tags, scans the metadata of your past docs, and only pulls the full text for the absolute most relevant documents (usually just 1 or 2 files). 

### 2. Can I use an external LLM (like OpenAI API) instead of Copilot for initialization to save tokens?
**Yes, via a hybrid approach.** 
While you cannot plug a raw OpenAI API key directly into the GitHub Copilot Chat extension, Copilot Forge is entirely file-based (Markdown). If you have a massive legacy codebase and want to use an external tool (like Aider, Cline, or a custom script) with a massive context window for the initial `#init` sweep, you can! 
Just have your external tool generate the `architecture.md`, `project-overview.md`, and `conventions.md` files and save them in the `.forge/context/` directory. From there, you can switch back to the native Copilot Chat extension for your daily `#spec` and `#analyze` tasks.

### 3. Does Copilot Forge automatically update the documentation if someone makes manual changes or I run `git pull`?
**No, but resolving the drift is easy.**
Copilot Forge does not run as a background daemon, so your `.forge/context/` files will drift if massive changes are made out-of-band. To fix this, run `#analyze`.
Copilot Forge features an **Incremental Analysis engine**: it stores the git commit hash of its last run. When you invoke `#analyze`, it uses `git diff` to identify exactly which files were added or modified since the last run. It then audits *only* those new files and automatically updates your architecture and convention docs to match the new codebase reality without rescanning the entire project.

### 4. Why didn't `#init` create the `copilot-instructions.md` file for me?
Copilot Forge separates the **Toolkit Engine** from the **Project Context**.
- The Toolkit Engine (`.github/` and `.vscode/`) contains the instructions and prompts. This must be manually copied into your repository first (or by running `install.ps1`). If it isn't there, VS Code won't even recognize the `#init` command.
- The Project Context (`.forge/`) is what `#init` generates—the unique architectural artifacts and requirements for your specific project.

### 5. Can I generate a single "Global Brain" documentation set for a multi-repo workspace?
**Yes, you have three options depending on your preference.**
If your enterprise system spans multiple repositories (e.g., frontend, backend, infra), Copilot Forge supports these architectural patterns natively:
- **Approach 1: The "Global Brain" (Centralized):** Open all your repositories in a single VS Code Multi-Root Workspace. Create a central folder (e.g., `system-docs`) and run `#init Please read the /frontend, /backend, and /infra directories and generate a unified architecture.md`. Because the Copilot `codebase` tool sees the entire workspace, it will generate one massive, inter-connected documentation set in that single `.forge/` folder.
- **Approach 2: Native Cross-Repo (Decentralized):** Run `#init` in each individual repository. Then, inside each repo's `.forge/config.yml`, use the `repos:` block to link them together as siblings. The architecture docs stay perfectly separated by repo, but when you run `#spec` or `#proceed`, Copilot automatically reads the configs and orchestrates code changes across all linked repos simultaneously!
- **Approach 3: The Hybrid (Micro & Macro Brains):** Run `#init` in each individual repository to generate localized `.forge/` documentation for individual teams. Then, open a single VS Code Multi-Root Workspace, create a central folder, and run `#init Please read the .forge/architecture.md files inside the /frontend, /backend, and /infra directories to generate a high-level global architecture.md`. Copilot will read the highly structured localized docs and effortlessly synthesize a perfect, high-level macro architecture that understands exactly how all the repositories connect!

### 6. Should I commit the `.github` and `.forge` folders to Git, or keep them local?
**Absolutely commit them!** They are the single source of truth for your team.
- The `.github/` folder ensures every developer on your team is using the exact same agent workflows and prompts.
- The `.forge/context/` folder ensures the AI operates on a unified architectural vision instead of hallucinating differently for each developer.
- The `.forge/specs/`, `bugs/`, and `knowledge/` folders act as your historical decision log. 

*Note: The Copilot Forge `.gitignore` template is specifically designed to ignore local state files (like `.forge/.last-analyzed-commit` and `.forge/.next-req`) so that developers don't encounter merge conflicts on their local counters.*

### 7. What is the difference between `#security_scan` and the `security-auditor` checklist?
They serve different roles in the security lifecycle:
- **`security-auditor` (Broad Audit)**: A comprehensive checklist used during `#review` or `#analyze` to find architectural and logical vulnerabilities (e.g., input validation flaws, authentication bypasses, insecure dependencies).
- **`#security_scan` (Focused Safety Gate)**: A dedicated, interactive pre-commit tool used during `#wrapup` specifically to detect and prevent hardcoded credentials (API keys, tokens, passwords) from being committed to version control. It allows users to confirm findings and flag false positives before the `git commit` is executed.

### 8. Why doesn't Copilot Forge use standard Agile "User Stories"?
Traditional Agile User Stories (e.g., "As a user, I want X so that Y") are designed for human-to-human communication. They rely heavily on shared intuition and "common sense" to fill in the gaps. 
When an AI reads a User Story, it fills those gaps with statistical probability—which often results in hallucinated logic, broken security boundaries, or incorrect infrastructure choices.
Instead, Copilot Forge relies on **System-First Specifications** based on the modernized **Zachman Framework (5W1H)**. We force the AI (and the user) to deterministically define the WHAT (Data), WHO (Actors), WHEN (Triggers), WHERE (Infrastructure), WHY (Invariants), and HOW (Stack). By providing these exact system boundaries, we eliminate ambiguity and prevent the AI from making dangerous assumptions during the `#architect` and implementation phases.

### 9. Are subagents more token consuming?
**Yes and No. It shifts how you pay for tokens.**

- **The "Context Tax" (Why it uses more input tokens):** In a single long thread, the AI already knows the spec because you talked about it 20 minutes ago. If you use subagents, every time you spin up a new subagent for a new task, you have to re-feed it the Zachman spec, the architecture rules, and the codebase state. You are paying for that baseline context over and over again.
- **The "Hallucination Tax" (Why it saves tokens in the long run):** In a long continuous pipeline (like running a massive feature through `#proceed` in one thread), the context window grows linearly. By the time it reaches Task 5, the prompt is massive, which makes every single LLM call wildly expensive. Worse, the AI starts hallucinating, mixing up code from Task 1 with Task 5. You end up spending thousands of output tokens arguing with the AI to fix bugs it created due to context confusion.
- **The Verdict:** Subagents trade slightly higher input token usage for a massive reduction in output tokens, rework, and bugs. Also, with modern features like Prompt Caching (which Anthropic and Google now use), feeding the same Zachman spec to 10 subagents is heavily discounted, making subagents much cheaper than they were a year ago.

### 10. Can I see how many tokens a Copilot Forge session uses?
**Yes, via the built-in Token Usage Estimator.**
GitHub Copilot does not expose live token counts from the VS Code extension. However, since every file that Copilot Forge loads is a known, version-controlled Markdown file, Copilot Forge can accurately *estimate* token consumption by scanning those files directly.

**Two ways to use it:**

> **Recommended: use the PowerShell script.** Running `#token-estimate` inside Copilot Chat is itself a token-consuming operation — Copilot has to load the prompt, read all the files via the `codebase` tool, and generate the report as output. For routine use, the `.ps1` script runs entirely locally with **zero token cost** and produces identical output.
>
> **Why is the PowerShell script free (zero tokens)?**
> Think of tokens like "stamps" you pay when sending data to the AI over the internet. When you use Copilot Chat, it gathers your files and mails them to the AI to read, which costs stamps. The PowerShell script doesn't use the internet or talk to the AI at all. It simply looks at the file sizes on your own hard drive and does basic math (`file size ÷ 4`) to guess what the AI *would* charge you. Since nothing leaves your computer, it costs absolutely nothing.

- **From the terminal** *(zero token cost — recommended)*:
- **In Copilot Chat** *(convenient, but costs ~1,000–2,000 tokens to run)* — type `#token-estimate REQ-023`:

```powershell
# Baseline only (useful before starting a REQ)
.\token-estimate.ps1

# Estimate for a specific REQ
.\token-estimate.ps1 -ReqId REQ-023

# Estimate + write results into pipeline-state.json
.\token-estimate.ps1 -ReqId REQ-023 -UpdatePipelineState

# JSON output for scripting or dashboards
.\token-estimate.ps1 -ReqId REQ-023 -OutputJson
```

**What the output looks like:**

```
  [TOKEN ESTIMATE] Copilot Forge
  REQ-023 - My Feature Title
  --------------------------------------------------------------
  Phase                           Est. Tokens  % Total
  --------------------------------------------------------------
  Step 0: Preflight                     5,326   11.7%
  Phase 1: Validate Spec                1,119    2.4%
  Phase 2: Architect                   11,154   24.4%
  Phase 3: Validate Arch                1,119    2.4%
  Phase 3.5: TDD                          507    1.1%
  Phase 4: Implement                    5,866   12.8%
  Phase 5: Verify                      12,357     27% << largest
  Phase 6-7: PR + CI                      801    1.8%
  Phase 7.5: Canary                     1,085    2.4%
  Phase 8: Wrapup                       6,358   13.9%
  --------------------------------------------------------------
  TOTAL Input Tokens                   45,692    100%
  Est. Output Tokens (~27%)            12,337
  Est. GRAND TOTAL                     58,029
  --------------------------------------------------------------
```

**How it works:**
- It scans every file that would be loaded across each pipeline phase (context files, prompt files, spec artifacts, tasks, RAG lessons).
- **Variable Source Payload:** How does the script know which source files you're changing? It simply reads your `TASK-*.md` text files. Since you list the files to modify under the `## Files to Create/Modify` heading during the architecture phase, the script just extracts those paths, finds the files on your hard drive, and measures their size.
- It applies the standard approximation: **~4 characters = 1 token** for English/Markdown text.
- Output tokens are estimated at **~27% of input** — a conservative average for agentic implementation tasks.
- Results are written to `pipeline-state.json` (via `-UpdatePipelineState`) and automatically surfaced in the `#wrapup` ship summary under **Metrics**.

**Accuracy:** ±15–20%. Useful for comparing token costs across REQs and identifying the heaviest phases (typically Phase 5: Verify, which loads all 6 agent checklists simultaneously). Not a substitute for official GitHub Copilot billing data.

