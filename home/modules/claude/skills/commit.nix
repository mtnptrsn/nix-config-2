# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a SKILL.md variant when working in this repo.
''
  ---
  name: commit
  description: Create git commits with validation. Use when the user asks to commit, create a commit, or save changes to git.
  ---

  ## Context

  - Current git status: !`git status`
  - Current git diff (staged and unstaged changes): !`git diff HEAD`
  - Current branch: !`git branch --show-current`
  - Recent commits: !`git log --oneline -10`

  ## Rules

  - Use semantic commit messages: `feat(scope): description`, `fix(scope): description`, `refactor(scope): description`, etc.
  - Never add a Co-Authored-By line to commit messages.
  - Separate changes into distinct commits by concern. Group related changes together and keep unrelated changes in separate commits. If all changes are related, a single commit is fine.
  - Do not commit files that likely contain secrets (.env, credentials, etc.).

  ## Validation

  First, read `package.json` in the project root to check for any of the following validation scripts: `typecheck`, `type-check`, `lint`, `check`, `validate`.

  If any exist, run them in parallel before committing using `nix run nixpkgs#parallel`. Determine the package manager: `pnpm` if `pnpm-lock.yaml` exists, `yarn` if `yarn.lock` exists, otherwise `npm`. For monorepos with `--filter` support, use `pnpm typecheck --filter <package>` and `pnpm lint --filter <package>` style invocations.

  Example with two scripts found:
  ```
  nix run nixpkgs#parallel ::: "pnpm typecheck" "pnpm lint"
  ```

  If validation fails, fix the issues and re-validate before committing. If you cannot fix the issues, report them to the user instead of committing.

  If no validation scripts are found, skip validation and proceed directly to committing.

  ## Your task

  1. Analyze the changes and determine how to group them into commits (by concern).
  2. Run validation if applicable (see above).
  3. Stage and commit the changes using semantic commit messages.
  4. Show the result with `git status` and `git log --oneline -5`.
''
