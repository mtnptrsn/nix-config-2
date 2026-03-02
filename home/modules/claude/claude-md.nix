# Shared base for ~/.claude/CLAUDE.md across all profiles.
# Profile-specific content is concatenated after this by the module.
''
  This file has two sections. "Base" applies to all machines and is shared across profiles. "Profile" is appended per host by Nix and contains machine- or project-specific instructions.

  # Base

  ## Instructions

  - When running multiple independent commands, run them in parallel using `parallel` if available
  - Never use em dashes (-). Use hyphens (-) or other punctuation instead.
  - Use practical, plain language. Avoid pretentious or overly formal words. Prefer simpler alternatives.
  - Use `sudo -A` instead of `sudo` to get a GUI password prompt

  ## Git

  - Use semantic commit messages: `feat(scope): description`, `fix(scope): description`, `refactor(scope): description`, etc.
  - Never add a Co-Authored-By line to commit messages.
''
