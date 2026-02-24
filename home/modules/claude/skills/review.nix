# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a SKILL.md variant when working in this repo.
''
  ---
  name: review
  description: Review local code changes. Use when the user asks to review, review changes, or do a code review.
  ---

  ## Context

  - Current branch: !`git branch --show-current`
  - Recent commits on this branch: !`git log --oneline -10`
  - Uncommitted changes: !`git status --short`

  ## Steps

  ### 1. Determine what to review

  - If the user specifies files, commits, or a range - review that.
  - If there are uncommitted changes (staged or unstaged), review those using `git diff HEAD`.
  - If the working tree is clean, review the commits on the current branch that diverge from the base branch (typically `main` or `master`) using `git diff main...HEAD` and `git log main..HEAD`.
  - If nothing to review, tell the user.

  ### 2. Read the full diff

  Get the complete diff for the scope determined above. For each changed file, also read surrounding context if the diff alone is not enough to understand the change.

  ### 3. Review the changes

  Focus on things that actually matter:

  - **Bugs and logic errors** - incorrect conditions, off-by-one errors, null/undefined access, wrong variable used, missing return statements
  - **Edge cases** - unhandled inputs, boundary conditions, race conditions, empty/nil states
  - **Security** - injection vulnerabilities, exposed secrets, unsafe deserialization, missing auth checks
  - **Performance** - unnecessary allocations in hot paths, O(n^2) where O(n) is possible, missing indexes
  - **Readability** - misleading names, confusing control flow, code that will trip up the next reader

  Skip:
  - Style and formatting nitpicks (that's what formatters are for)
  - Generic best practices that don't apply to the specific change
  - Suggestions that would make the code more "robust" without a realistic failure scenario

  ### 4. Output

  For each finding, include:
  - The file and relevant line(s)
  - What the issue is (1-2 sentences)
  - Why it matters
  - A suggested fix (code snippet if helpful)

  Group findings by severity:
  - **Must fix** - bugs, security issues, data loss risks
  - **Should fix** - logic gaps, meaningful readability problems
  - **Consider** - minor improvements worth thinking about

  If there are no findings, say so. Don't invent issues.

  ### 5. Summary

  End with a short overall assessment: what the changes do, whether they look good, and any high-level concerns.
''
