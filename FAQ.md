# Copilot Forge — Frequently Asked Questions (FAQ)

### 1. What is Spec-Driven Development (SDD)?
**SDD (Spec-Driven Development)** in the absolute simplest way is: **"Think first, write it down, *then* code."**

Instead of jumping straight into your editor and typing code (or asking an AI, *"build me a login page"*), you first write a plain-English **Specification** (the Spec). This Spec acts as a rigid blueprint. It mathematically defines:
1. Exactly what the feature should do.
2. The rules it must follow.
3. The exact checkboxes it must pass to be considered "done".

Only *after* the Spec is reviewed and locked in do you (or the AI) actually write a single line of code. 

**Why is it important for AI?**
If you tell an AI to just "build a feature," it will hallucinate, guess your architecture, and output messy code (often called "vibe coding"). In **Spec-Driven Development**, you give the AI your strict blueprint first. It is forced to follow the blueprint exactly, which eliminates hallucinations and results in enterprise-grade, production-ready code.

### 2. Will running `#spec` or `#analyze` consume a huge amount of tokens by reading all my docs every time?
**No.** Copilot Forge is specifically engineered to be extremely token-efficient.
- **It reads summaries, not raw code:** The `.forge/context/` files (like `architecture.md` and `project-overview.md`) are explicitly designed to be high-level summaries. Reading these takes a fraction of the tokens compared to standard Copilot attempting to read your entire raw codebase.
- **Built-in Retrieval Augmented Generation (RAG):** When searching your past specs, bugs, or lessons learned, the agent acts like a search engine. It first parses your prompt to generate search tags, scans the metadata of your past docs, and only pulls the full text for the absolute most relevant documents (usually just 1 or 2 files). 

### 3. Can I use an external LLM (like OpenAI API) instead of Copilot for initialization to save tokens?
**Yes, via a hybrid approach.** 
While you cannot plug a raw OpenAI API key directly into the GitHub Copilot Chat extension, Copilot Forge is entirely file-based (Markdown). If you have a massive legacy codebase and want to use an external tool (like Aider, Cline, or a custom script) with a massive context window for the initial `#init` sweep, you can! 
Just have your external tool generate the `architecture.md`, `project-overview.md`, and `conventions.md` files and save them in the `.forge/context/` directory. From there, you can switch back to the native Copilot Chat extension for your daily `#spec` and `#analyze` tasks.

### 4. Does Copilot Forge automatically update the documentation if someone makes manual changes or I run `git pull`?
**No, but resolving the drift is easy.**
Copilot Forge does not run as a background daemon, so your `.forge/context/` files will drift if massive changes are made out-of-band. To fix this, run `#analyze`.
Copilot Forge features an **Incremental Analysis engine**: it stores the git commit hash of its last run. When you invoke `#analyze`, it uses `git diff` to identify exactly which files were added or modified since the last run. It then audits *only* those new files and automatically updates your architecture and convention docs to match the new codebase reality without rescanning the entire project.

### 5. Why didn't `#init` create the `copilot-instructions.md` file for me?
Copilot Forge separates the **Toolkit Engine** from the **Project Context**.
- The Toolkit Engine (`.github/` and `.vscode/`) contains the instructions and prompts. This must be manually copied into your repository first (or by running `install.ps1`). If it isn't there, VS Code won't even recognize the `#init` command.
- The Project Context (`.forge/`) is what `#init` generates—the unique architectural artifacts and requirements for your specific project.

### 6. Can I generate a single "Global Brain" documentation set for a multi-repo workspace?
**Yes, you have three options depending on your preference.**
If your enterprise system spans multiple repositories (e.g., frontend, backend, infra), Copilot Forge supports these architectural patterns natively:
- **Approach 1: The "Global Brain" (Centralized):** Open all your repositories in a single VS Code Multi-Root Workspace. Create a central folder (e.g., `system-docs`) and run `#init Please read the /frontend, /backend, and /infra directories and generate a unified architecture.md`. Because the Copilot `codebase` tool sees the entire workspace, it will generate one massive, inter-connected documentation set in that single `.forge/` folder.
- **Approach 2: Native Cross-Repo (Decentralized):** Run `#init` in each individual repository. Then, inside each repo's `.forge/config.yml`, use the `repos:` block to link them together as siblings. The architecture docs stay perfectly separated by repo, but when you run `#spec` or `#proceed`, Copilot automatically reads the configs and orchestrates code changes across all linked repos simultaneously!
- **Approach 3: The Hybrid (Micro & Macro Brains):** Run `#init` in each individual repository to generate localized `.forge/` documentation for individual teams. Then, open a single VS Code Multi-Root Workspace, create a central folder, and run `#init Please read the .forge/architecture.md files inside the /frontend, /backend, and /infra directories to generate a high-level global architecture.md`. Copilot will read the highly structured localized docs and effortlessly synthesize a perfect, high-level macro architecture that understands exactly how all the repositories connect!

### 7. Should I commit the `.github` and `.forge` folders to Git, or keep them local?
**Absolutely commit them!** They are the single source of truth for your team.
- The `.github/` folder ensures every developer on your team is using the exact same agent workflows and prompts.
- The `.forge/context/` folder ensures the AI operates on a unified architectural vision instead of hallucinating differently for each developer.
- The `.forge/specs/`, `bugs/`, and `knowledge/` folders act as your historical decision log. 

*Note: The Copilot Forge `.gitignore` template is specifically designed to ignore local state files (like `.forge/.last-analyzed-commit` and `.forge/.next-req`) so that developers don't encounter merge conflicts on their local counters.*

### 8. What is the difference between `#security_scan` and the `security-auditor` checklist?
They serve different roles in the security lifecycle:
- **`security-auditor` (Broad Audit)**: A comprehensive checklist used during `#review` or `#analyze` to find architectural and logical vulnerabilities (e.g., input validation flaws, authentication bypasses, insecure dependencies).
- **`#security_scan` (Focused Safety Gate)**: A dedicated, interactive pre-commit tool used during `#wrapup` specifically to detect and prevent hardcoded credentials (API keys, tokens, passwords) from being committed to version control. It allows users to confirm findings and flag false positives before the `git commit` is executed.

### 9. Why doesn't Copilot Forge use standard Agile "User Stories"?
Traditional Agile User Stories (e.g., "As a user, I want X so that Y") are designed for human-to-human communication. They rely heavily on shared intuition and "common sense" to fill in the gaps. 
When an AI reads a User Story, it fills those gaps with statistical probability—which often results in hallucinated logic, broken security boundaries, or incorrect infrastructure choices.
Instead, Copilot Forge relies on **System-First Specifications** based on the modernized **Zachman Framework (5W1H)**. We force the AI (and the user) to deterministically define the WHAT (Data), WHO (Actors), WHEN (Triggers), WHERE (Infrastructure), WHY (Invariants), and HOW (Stack). By providing these exact system boundaries, we eliminate ambiguity and prevent the AI from making dangerous assumptions during the `#architect` and implementation phases.

### 10. Are subagents more token consuming?
**Yes and No. It shifts how you pay for tokens.**

- **The "Context Tax" (Why it uses more input tokens):** In a single long thread, the AI already knows the spec because you talked about it 20 minutes ago. If you use subagents, every time you spin up a new subagent for a new task, you have to re-feed it the Zachman spec, the architecture rules, and the codebase state. You are paying for that baseline context over and over again.
- **The "Hallucination Tax" (Why it saves tokens in the long run):** In a long continuous pipeline (like running a massive feature through `#proceed` in one thread), the context window grows linearly. By the time it reaches Task 5, the prompt is massive, which makes every single LLM call wildly expensive. Worse, the AI starts hallucinating, mixing up code from Task 1 with Task 5. You end up spending thousands of output tokens arguing with the AI to fix bugs it created due to context confusion.
- **The Verdict:** Subagents trade slightly higher input token usage for a massive reduction in output tokens, rework, and bugs. Also, with modern features like Prompt Caching (which Anthropic and Google now use), feeding the same Zachman spec to 10 subagents is heavily discounted, making subagents much cheaper than they were a year ago.

### 11. Can I see how many tokens a Copilot Forge session uses?
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

### 12. What is the "Ethos" mentioned in all the prompts?
The **Ethos** refers to a core set of 6 foundational development principles that the AI is instructed to follow whenever it executes any of the Copilot Forge prompts. You'll find it defined in `.github/copilot-instructions.md`. It guarantees that the AI behaves consistently and adheres to strict engineering standards (like "Spec First, Code Second", "Verify, Don't Trust", and "Process Is Not Optional") regardless of the specific task it is performing.

### 13. How does Copilot Forge's philosophy compare to GitHub's Spec Kit?
When comparing the two on a purely philosophical level, both tools share the same core belief: AI should be guided by structured specifications rather than "vibe coding" from a single prompt.

However, they differ significantly in scope, rigidity, and how they view the software lifecycle. Here is how Copilot Forge's philosophy compares to Spec Kit's four core pillars:

**1. Intent-Driven Development ("What" before "How")**
- **Spec Kit:** Focuses on capturing the user's intent in plain English first, then translates that into a technical plan, and finally into code. The transition is fluid and relies on the AI to connect the dots.
- **Copilot Forge:** Takes a much more rigid, analytical approach to intent. Instead of just writing "what" you want, Forge enforces the System-First / Zachman 5W1H Framework (What, Who, When, Where, Why, How). It forces ambiguity out of user stories before a single line of architecture is even considered.

**2. Guardrails and Organizational Principles**
- **Spec Kit:** Establishes guardrails upfront. You define a Constitution (your project's principles, testing standards, UX consistency), and the AI is expected to keep those principles in mind as it generates code.
- **Copilot Forge:** Enforces guardrails continuously through auditing. It doesn't just ask the AI to follow the rules; it uses dedicated Agent Reference Checklists (e.g., `security-auditor`, `architecture-reviewer`, `test-auditor`) to actively audit the AI's work at every stage. It believes in strict, interactive gates (like `#validate` and `#review`) rather than just upfront guidance.

**3. Multi-Step Refinement**
- **Spec Kit:** Uses a lightweight, high-level refinement process: Constitution -> Spec -> Plan -> Tasks -> Implement. It's designed to be simple enough to fit into any workflow.
- **Copilot Forge:** Views refinement as a full enterprise Software Development Life Cycle (SDLC). Its pipeline is deeply granular and highly prescriptive: `#spec → #validate → #architect → #validate → implement → #reflect → #review → merge → #wrapup`. It believes that refinement doesn't end when the code is written—it mandates self-reflection, multi-dimensional peer reviews, and automated documentation updates before a feature is considered "done."

**4. Relying on AI for Specification Interpretation**
- **Spec Kit:** Trusts the AI's advanced reasoning capabilities to read the specs, look at your codebase, and figure out the implementation.
- **Copilot Forge:** Believes the AI needs a living, stateful memory to interpret specs accurately. Rather than relying purely on the AI's contextual reasoning, Forge actively maintains a `.forge/context/` directory. It uses Incremental Analysis (`#analyze`) to constantly detect code drift and update architecture documents, ensuring the AI's "brain" perfectly matches the reality of the codebase at all times.

**Summary**
- **Spec Kit's Philosophy:** "Give the AI clear principles, write a good spec, break it into tasks, and let the AI build it. Keep the process lightweight, adaptable, and agent-agnostic."
- **Copilot Forge's Philosophy:** "Software engineering requires rigid discipline. Eliminate ambiguity with strict frameworks, maintain a stateful architecture context, and force the AI to rigorously audit, test (TDD), and peer-review its own work before allowing it to ship."

### 14. How does Copilot Forge's philosophy compare to Superpowers?
Superpowers outlines four explicit philosophical pillars. Interestingly, Copilot Forge shares almost the exact same foundational beliefs, but implements them through explicit enterprise pipelines rather than implicit interception:

- **1. Test-Driven Development:** Both completely agree on TDD-first.
- **2. Systematic over ad-hoc:** Both completely agree, with Forge using the strict Zachman framework.
- **3. Complexity reduction:** Slight difference—Superpowers focuses on task simplicity/YAGNI, while Forge focuses on large-scale architectural management and drift reduction.
- **4. Evidence over claims:** Both completely agree on strict self-review and quality gates.

**Intervention vs. Orchestration**
- **Superpowers:** Relies on *implicit intervention*. It automatically detects when you try to write code and stops you, stepping back to tease out a specification through conversation before allowing you to proceed. It acts as a seamless, automatic guardrail.
- **Copilot Forge:** Relies on *explicit orchestration*. It provides a defined, manual pipeline (`#spec → #validate → #architect → #proceed`). The developer remains the conductor, explicitly telling the AI which phase of the Software Development Life Cycle (SDLC) to execute.

**Execution Model**
- **Superpowers:** Heavily champions **subagent-driven-development**. Once the plan is approved, it dispatches multiple autonomous subagents to handle individual engineering tasks, self-review their work, and run for hours at a time.
- **Copilot Forge:** Champions **contextual, checklist-driven pipelines**. Its core power lies in passing an evolving, living architectural state (`.forge/context/`) sequentially through specialized, interactive reviewer personas (e.g., `security-auditor`, `architecture-reviewer`) within orchestrated cycles.

**Summary**
Both tools fight the same enemy: undisciplined AI code generation. **Superpowers** solves it by acting as an automatic behavioral interceptor that orchestrates subagents based on its four pillars. **Copilot Forge** solves it by providing the developer with an explicit, enterprise-grade SDLC control panel that bakes those exact same pillars into strict architectural checklists and pipelines.

### 15. How does Copilot Forge's philosophy compare to Open-Spec?
Open-Spec advocates for a lightweight, highly adaptable approach to specification. In contrast, Copilot Forge leans heavily into enterprise governance and strict architectural control. 

Here is how Copilot Forge aligns (or contrasts) with Open-Spec's five core tenets:

- **Fluid not rigid:** **Opposites.** Open-Spec prefers fluidity, while Copilot Forge intentionally enforces rigid discipline. Forge uses strict templates (like the Zachman 5W1H Framework) and hard quality gates to mathematically remove ambiguity.
- **Iterative not waterfall:** **Different approaches.** Open-Spec encourages loose iteration. Copilot Forge forces a highly structured, sequential micro-waterfall for every feature (`#spec` → `#architect` → `implement` → `#review`), ensuring strict architectural compliance before any code is merged.
- **Easy not complex:** **Opposites.** Open-Spec prioritizes sheer simplicity. Copilot Forge embraces the necessary complexity of enterprise development, providing advanced tools like cross-repo PR orchestration, Incremental Analysis (`#analyze`), and Canary deployment routing.
- **Built for brownfield not just greenfield:** **Both completely agree.** Copilot Forge was engineered explicitly for massive legacy codebases. Its `#analyze` engine is designed to constantly read and reverse-engineer existing code to keep its architectural memory (`.forge/context/`) perfectly synced with reality.
- **Scalable from personal projects to enterprises:** **Different sweet spots.** Open-Spec scales smoothly from tiny personal scripts up to larger projects. Copilot Forge *can* be used for personal projects (using single-repo mode), but its true sweet spot is at the massive enterprise level where teams, security policies, and cross-repo dependencies require strict orchestration.

### 16. Why is Copilot Forge described as a "micro-waterfall"?
In traditional software engineering, the **Waterfall methodology** means you must completely finish and lock in one phase before you are allowed to move to the next:
1. Requirements Phase (Specs) -> *Locked*
2. Design Phase (Architecture) -> *Locked*
3. Implementation Phase (Coding) -> *Locked*
4. Testing/Review Phase -> *Locked*

Agile and iterative models push against this by blending those phases together—letting you write a little code, adjust the spec, write more code, and adjust the architecture on the fly.

**Copilot Forge, however, intentionally brings Waterfall back—but shrinks it down to the feature level.**

Look at the required sequence for a single feature in Forge: 
`#spec` → `#validate` → `#architect` → `#validate` → `#tdd` → `implement` → `#reflect` → `#review` → `#wrapup`

- You cannot generate architecture until the spec passes validation.
- You cannot write functional code until the architecture passes validation.
- You cannot merge until the code passes the `#review` checklists.

It acts exactly like the strict, phase-gated Waterfall model where every step requires sign-off before the next begins. It's a **"micro" waterfall** because instead of this process taking 6 months for an entire software release, the AI executes this rigid, phase-gated sequence for a single feature in a matter of minutes or hours.

### 17. What exactly is validated during the `#validate` phase?
When you run `#validate` on a Requirement (REQ) or Architecture phase, Copilot Forge acts as a strict technical reviewer and runs through a rigorous checklist to mathematically eliminate ambiguity and prevent "vibe coding" errors.

**In the REQ Phase (`requirement.md`)**
The goal here is to ensure the "What" and "Why" are rock-solid before *any* technical decisions are made:
* **No Implementation Details:** It strictly rejects the spec if you tried to include technical implementation details (those belong in architecture!).
* **Scope Creep Prevention:** It checks that "Out of Scope" items are explicitly defined so the AI doesn't hallucinate extra features.
* **Testability:** It verifies that Acceptance Criteria are specific, highly testable, and formatted as checkboxes.
* **Metadata & Clarity:** Checks that the frontmatter (ID, status, dates) is valid, explicit assumptions are stated, and external dependencies are identified.
* **Conflicts:** Checks to ensure this requirement doesn't duplicate or overlap with existing specs in your project.

**In the Architecture Phase (`architecture.md`)**
The goal here is to ensure the proposed technical solution perfectly matches your existing codebase rules:
* **Pattern Enforcement:** It cross-references your `.forge/context/architecture.md` and `.forge/context/conventions.md` to ensure the new design perfectly matches your existing architectural patterns and REST conventions.
* **ADR Rationale:** If Architectural Decision Records (ADRs) are made, it forces them to include the *rationale*, not just the final decision.
* **Data Model Safety:** It checks that proposed data model changes are actually compatible with your existing database schema.
* **Layered Architecture:** It ensures the service layer adheres to your established layered pattern (e.g., routes → services → repositories).
* **Conflict Resolution:** It checks for architectural conflicts with any other *in-progress* requirements being built by you or your team.

If any of these checks fail, `#validate` categorizes them as **Blockers**, **Warnings**, or **Info**, and explicitly halts the pipeline until the blockers are fixed!

### 18. What problem is Copilot Forge really solving?
Standard AI tools like Copilot are incredible at "local code generation" (writing snippets, generating tests for a single file, or explaining a block of code). 

However, there is a massive gap between **local code generation** and **production‑ready engineering**. Standard AI does not understand your enterprise architecture, strict security controls, or cross‑system dependencies. This often leads to a cycle where AI generates code quickly, but senior engineers have to spend hours supervising, debugging, and cleaning up architectural violations before it can be merged.

**Copilot Forge solves this gap.**
It forces the AI to work through a strict, governed delivery process. Instead of just generating code from a prompt, Forge requires the AI to pass through formal requirements gathering (`#spec`), architecture design, test-driven development (`#tdd`), and multiple peer-review quality gates. 

By enforcing this governed execution, Forge's goal is to deliver:
- Less rework from AI‑generated code.
- Fewer architecture and standards violations.
- Drastically lower review times per change, especially on repetitive enterprise tasks.

### 19. Where does the organizational context actually come from?
To prevent the AI from generating generic ideas that violate your organization's specific standards, Copilot Forge merges three sources of context during every single run:

1. **Global Rules:** Your established architecture standards, coding conventions, guardrails, and "never do this" patterns.
2. **Specialized Agents:** Targeted persona checklists (e.g., Security Auditor, Architecture Reviewer) that strictly check output against those global rules.
3. **Local State:** The `.forge/` directory inside each repository. This stores your current specs, architecture records (`architecture.md`), and the living state of your pipelines. 

When you run `#spec`, it pulls in past incidents and architecture rules relevant to *your* codebase. When you run `#proceed`, every validation gate and code review is grounded in those exact same artifacts.

In Copilot Forge, context is not abstract or hallucinated—it is version‑controlled directly in your repository and evolves alongside your project.

### 20. How does Copilot Forge interact with our existing SDLC and CI/CD toolchain?
Copilot Forge **does not replace** your existing SDLC or CI/CD pipelines; it augments them at the developer level.

Everything Forge does ultimately results in standard Git commits, branches, and Pull Requests/Merge Requests. 
- For issue tracking, commands like `#issue_epic_creation` push work directly into your existing Jira/GitLab epics.
- For delivery, the `#wrapup` command integrates perfectly with your existing PR/MR documentation practices.

Think of Copilot Forge as an **intelligent front‑end** to your pipeline. By the time code is pushed and hits your CI/CD server, Forge has already enforced spec quality, architectural compliance, TDD, and peer review locally. It drastically reduces noise and failures downstream instead of attempting to bypass your established enterprise processes.

### 21. How do you handle monitoring and observability?
We approach monitoring on two distinct levels: **Tool Telemetry** (monitoring the AI itself) and **Application Observability** (teaching the AI how to monitor your code).

**1. Tool Telemetry (Monitoring the AI Pipeline)**
Copilot Forge tracks its own execution metrics locally to give you visibility and auditability into what the AI is doing:
* **Pipeline State:** The `#token-estimate` phase tracks token consumption, phase durations, and validation results, saving them to `.forge/pipeline-state.json`.
* **Ship Summary:** At the end of every pipeline, `#wrapup` generates a final Metrics report summarizing the run, which is appended directly to your Pull Requests.
* **Agent Telemetry:** Advanced hooks (like `emit-telemetry.sh`) can log granular agent decisions, detect "ghost-skips" (when the AI tries to bypass a review), and track API errors into local TSV files for strict enterprise auditability.

**2. Application Observability (Monitoring Your Code)**
To ensure the applications you build are observable by default, Forge uses **Contextual Observability Knowledge**:
* By creating a `.forge/context/observability.md` artifact, you document your organization's specific APM tools (e.g., Datadog, Prometheus), structured logging formats, and alert thresholds.
* The AI reads this context during the implementation phase and automatically generates the correct logging statements and telemetry hooks for every new feature, eliminating the need for senior engineers to retroactively add monitoring.

### 22. How does Knowledge Retrieval work in Copilot Forge?
To ensure the AI has the exact right context without exceeding token limits, Copilot Forge utilizes a **weighted-score retriever** at context-loading time over the `.forge/knowledge/` directory.

Rather than blindly loading all past documentation, prompts dynamically retrieve relevant prior knowledge based on what is being executed:

* **Lessons (`.forge/knowledge/lessons/*.md`)** — Surfaced during `#spec`, `#architect`, `#reflect`, and `#review` phases to prevent the AI from repeating past mistakes.
* **Specs (`.forge/specs/*/requirement.md`)** — Surfaced during the `#spec` phase to find related prior requirements and prevent overlapping work.
* **Bugs (`.forge/bugs/*.md`)** — Surfaced during the `#spec` phase to load context about related resolved bugs.

**The Scoring System:**
When searching, Forge evaluates the available knowledge files using a strict mathematical weighting:
* **+3** for a Component match
* **+2** for a Domain match
* **+2×** for overlapping concerns
* **+1×** for overlapping tags

Once scored, only the **Top 15** files by score are read in full and injected into the AI's context. This guarantees that the AI has a hyper-relevant "memory" of your project's history without wasting tokens or suffering from context-bloat.
