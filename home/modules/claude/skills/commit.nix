# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a SKILL.md variant when working in this repo.
''
  ---
  name: commit
  description: Create git commits with validation. Use when the user asks to commit, create a commit, or save changes to git.
  ---

  ## Context

  - Current branch: !`git branch --show-current`
  - Recent commits: !`git log --oneline -10`
  - Uncommitted changes: !`git status`
  - Diff (staged and unstaged): !`git diff HEAD`

  ## Commit style

  - Use semantic commit messages: `feat(scope): description`, `fix(scope): description`, `refactor(scope): description`, etc.
  - Never add a Co-Authored-By line to commit messages.
  - If the scope is unclear, ask the user.
  - Separate changes into distinct commits by concern. Group related changes together and keep unrelated changes in separate commits. If all changes are related, a single commit is fine.

  ## Steps

  ### 1. Analyze changes and discover validation

  Use the Task tool to launch these agents in parallel:

  1. **Analyze changes** - Look at the diff and determine how to group the changes into commits by concern.
  2. **Discover validation** - Find all available validation methods in the project (linters, type checkers, formatters, test suites) by checking project config files, scripts, CI configs, and CLAUDE.md. Return a list of what's available, but do not run anything yet.

  ### 2. Select and run validation

  Use AskUserQuestion with multiSelect to present the discovered validation options and let the user pick which ones to run. Include a "Skip all" option. Only run the checks the user selects.

  If validation failed, fix the issues and re-validate. If you cannot fix the issues, report them to the user instead of committing.

  ### 3. Stage and commit

  Stage and commit the changes using semantic commit messages.

  ### 4. Show result

  Show the result with `git status` and `git log --oneline -5`.
''
