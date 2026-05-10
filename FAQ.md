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
