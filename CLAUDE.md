# Core Principles
- **Simplicity first**: Make every change as simple as possible, but not simpler. Impact minimal code.
- **No Laziness**: Find root causes. Avoid temporary fixes. Senior Dev standards.
- **Correct inconsistencies**: Architecture & Code must be consistent in form, structure and design. Check for any inconsistencies and reiterate until it fits.
- **Self-explainable**: FORBIDDEN from writing long comments. Long comment necessary -> analyse how this method can be broken down into simpler/more logical and straightforward code and refactor.

# Commit rules
Every commit must be strictly granular, touching one feature/fix/part of the codebase, so that on a revert, each commit can be reverted without crossfire influence on other 
parts of the codebase. DO NOT run pushes => your role is branching and committing. Commit messages need to be brief and self-explainable. Check the results of the commit hooks git-lrc before deeming this commit done. 
- LiveReview: run `lrc review --agent-mode` before committing — the non-interactive agent path that writes the attestation so the pre-commit hook lets `git commit` through. 
- *Special case*: Docs/markdown-only no-code-changes commits: run `lrc review --skip` before the commit so no AI review runs on them.

# Project Context
## Development Practices:
- Clean short code with high component reusability & abstraction.
- OVERRIDE: If architecture is flawed, state is duplicated, or patterns are inconsistent - propose and implement structural fixes. Ask yourself: "What would a senior, experienced, perfectionist dev reject in code review?" Fix all of it.
-  FORCED VERIFICATION: Your internal tools mark file writes as successful even if the code does not compile. You are FORBIDDEN from reporting a task as complete until you have: 
   - Run `npx tsc --noEmit` equivalent for the backend AND frontend both (or the project's equivalent type-check)
   - Run `npx eslint . --quiet` equivalent for the backend AND frontend both (if configured)
   - Fixed ALL resulting errors
- NO LOCAL CODE IMPORTS. All imports go sorted out at the top of the file/in __init__.py
- Address all advisor concerns/comments until that field is clear. 

# Agent Directives: Mechanical Overrides
## Pre-Work
- DEAD CODE: accelerates context compaction. Before ANY structural refactor on a file >300 LOC, first remove all dead props, unused exports, unused imports, and debug logs. Commit this cleanup separately before starting real work.
- PHASED EXECUTION: Never attempt multi-file refactors in a single response. Break work into explicit phases. Complete Phase 1, run verification, and wait for explicit approval before Phase 2. Each phase must touch no more than 8-10 files.
- Refer to plan.md (if stated) for detailed plan on the implementation. If none, ask questions and verify every code/arch decision.
## Context Management
- FILE READ BUDGET: Each file read is capped at 2,000 lines. For files over 500 LOC, you MUST use offset and limit parameters to read in sequential chunks. Never assume you have seen a complete file from a single read.
- TOOL RESULT BLINDNESS: Tool results over 50,000 characters are silently truncated to a 2,000-byte preview. If any search or command returns suspiciously few results, re-run it with narrower scope (single directory, stricter glob). State when you suspect truncation occurred.
## Demand elegance(Balance)
- For non-trivial changes: pause and ask "Is there a more efficient and elegant way to implement this?" If yes, re-implement/re-spec.
- For trivial changes: implement in the most straightforward way; NO additional functionalities, NO consideration for features not yet shipped, NO consideration for deprecated code.
- Do not over-engineer.
## Edit Safety
-  EDIT INTEGRITY: Before EVERY file edit, re-read the file. After editing, read it again to confirm the change applied correctly. The Edit tool fails silently when old_string doesn't match due to stale context. Never batch more than 3 edits to the same file without a verification read.
- NO SEMANTIC SEARCH: You have grep, not an AST. When renaming or
  changing any function/type/variable, you MUST search separately for:
  - Direct calls and references
  - Type-level references (interfaces, generics)
  - String literals containing the name
  - Dynamic imports and require() calls
  - Re-exports and barrel file entries
  - Test files and mocks
  Do not assume a single grep caught everything.

# Boundaries
- **ALWAYS**
  - write to destined folder
  - run tests after making changes
  - double-check code/feature YAGNI. cut down on unnecessary code and features.
  - document into an existing README.md if the functionality is already described/fits into an existing file. Only create a new README if absolutely necessary and keep content to a minimum
- **Ask first** before making any of the following changes:
  - database schema change
  - adding dependencies
  - saving tests and adding new .md documentation
- **Never**
- commit or explicitly write out secrets and API keys
- edit the pyproject.toml, requirements.txt, *.env files (sid allowed)
- delete code/files without consulting
- change unrelated code
- make components out of functions that are only used once in code; turn it into a component only if it has already been used >=2 and there is a clear need for reusability
- make components out of 1-3 line functions, or longer with try-except blocks