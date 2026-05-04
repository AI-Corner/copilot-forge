# Task 001: Create Variables Template

## Objective
Create the `templates/variables-template.md` file to standardize how environment and configuration variables are documented in Copilot Forge projects.

## Implementation Steps
1. Create `templates/variables-template.md`.
2. Include a prominent security warning at the top reminding users/agents NOT to store real production secrets in this file.
3. Define markdown tables for the following categories:
   - Frontend Variables
   - Backend Properties
   - Infrastructure & Secrets
4. Ensure each table has the columns: `Variable Key`, `Type/Format`, `Default Value`, `Purpose`, and `Consumers`.
5. Provide a brief example row in each table.

## Acceptance Criteria
- `templates/variables-template.md` exists and contains the required structure and security warnings.
