# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a SKILL.md variant when working in this repo.
''
  ---
  name: review
  description: Review local code changes. Use when the user asks to review, check, or critique their current changes.
  ---

  ## Context

  - Current branch: !`git branch --show-current`
  - Default branch candidates: !`git branch --list main master 2>/dev/null`
  - Uncommitted changes: !`git status --short`
  - Staged changes: !`git diff --cached --stat 2>/dev/null; true`
  - Unstaged changes: !`git diff --stat 2>/dev/null; true`

  ## Tone and style

  - Keep language normal - not too formal, not too casual
  - Be direct and constructive

  ## Steps

  ### 1. Determine review scope

  Determine the default branch from the candidates above (main or master, whichever exists). Then run `git branch --merged HEAD --no-merged <default>` (excluding the current branch) to find intermediate branches.

  Use AskUserQuestion to ask:

  - If an intermediate branch was found, ask which branch to compare against. Offer the intermediate branch (closest parent) and the default branch as options. If no intermediate branch was found, skip this question and use the default branch.
  - If there are uncommitted changes (staged or unstaged), ask whether to include those in the review.

  After the user confirms, gather the full diff for the chosen scope:
  - Run `git log <base>..HEAD --oneline` to get commits
  - Run `git diff <base>...HEAD` to get the branch diff
  - If including staged changes, run `git diff --cached`
  - If including unstaged changes, run `git diff`

  ### 2. Ask which review perspectives to include

  Use AskUserQuestion with a single multi-select question asking which review perspectives to run. The options are:

  - **Correctness & Logic** - Bugs, edge cases, error handling gaps, race conditions, resource leaks, broken control flow
  - **Design & Maintainability** - Poor abstractions, tight coupling, unnecessary complexity, misleading names, pattern violations
  - **Security & Data Handling** - Injection vectors, hardcoded secrets, auth gaps, unvalidated input, information leakage
  - **Duplication & Reuse** - Existing functions, utilities, or helpers that overlap with newly introduced code

  ### 3. Spawn parallel review agents

  Use the Task tool to launch one agent per selected perspective in a single message.

  Each agent must:
  - Read relevant source files for surrounding context when the diff alone is not enough
  - Assign a confidence score (1-10) per finding and only report findings with confidence >= 7
  - Provide file:line, a one-line summary, and a brief explanation with a suggested fix for each finding

  ### 4. Synthesize findings

  After all agents return, deduplicate overlapping findings and classify each by severity:

  - **Critical** - likely bug, security vulnerability, or data loss risk
  - **Important** - design issue, missing edge case, maintainability concern
  - **Minor** - small improvement suggestion

  ### 5. Output

  Output findings grouped by severity. For each finding, include:

  - file:line reference
  - One-line summary
  - Brief explanation with suggested fix

  Omit empty severity sections. If there are no findings, say so plainly.
''
