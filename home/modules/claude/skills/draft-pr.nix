# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a SKILL.md variant when working in this repo.
''
  ---
  name: draft-pr
  description: Draft a pull request title and description. Use when the user asks to draft, prepare, or describe a pull request.
  ---

  ## Context

  - Current branch: !`git branch --show-current`
  - Commits since base branch: !`git log main..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline 2>/dev/null; true`
  - Uncommitted changes: !`git status --short`
  - Diff against base branch: !`git diff main...HEAD 2>/dev/null || git diff master...HEAD 2>/dev/null; true`

  ## Tone and style

  - Keep language normal - not too formal, not too casual
  - Be concise but informative
  - Prioritize making the reviewer's life easier

  ## Steps

  ### 1. Build the PR title

  The title should be:

  - Short and descriptive (under 72 characters total)
  - Based on the branch name, commits, and diff - pick the phrasing that best summarizes the overall change
  - Written in imperative mood (e.g. "Add", "Fix", "Update", "Remove")

  ### 2. Build the PR description

  Use this structure:

  ```
  ## Background

  {1-3 sentences explaining why this PR exists. What problem does it solve? What's the intent? Mention any limitations or trade-offs the reviewer should know about. Infer this from the commits and diff.}

  ## Changes

  {Bullet point list of the meaningful changes. Group related changes together. Add a brief explanation for non-obvious changes. Don't list every single file - focus on what matters to a reviewer.}

  ## How to test

  {If testing steps can be reasonably inferred from the changes (e.g. "run the test suite", "visit /settings and toggle X"), include them. Otherwise, write "TODO" so the author can fill this in.}
  ```

  ### 3. Output

  Do NOT push, create the PR, or run any git commands that modify state. Just output the final title and description as a single copyable markdown block that the user can paste into their PR themselves.
''
