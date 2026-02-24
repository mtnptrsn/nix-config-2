# Stored in a .nix file instead of .md to avoid being picked up by Claude
# as a CLAUDE.md variant when working in this repo.
''
  # Nix

  - Profile: `office-macbook`
  - Architecture: aarch64-darwin

  # Instructions

  - Use `nix run github:NixOS/nixpkgs/nixpkgs-unstable#gh -- <args>` instead of `gh` directly
  - Use `pnpm typecheck --filter <package>` and `pnpm lint --filter <package>` instead of running `tsc --noEmit` or linters directly
  - When running multiple independent commands, run them in parallel using `nix run nixpkgs#parallel`
  - When running validation scripts (typecheck, lint, test, etc.), run them in parallel using `nix run nixpkgs#parallel`
  - Never use em dashes (—). Use hyphens (-) or other punctuation instead.
  - Use practical, plain language. Avoid pretentious or overly formal words (e.g., "consolidate", "leverage", "utilize", "facilitate"). Prefer simpler alternatives.
''
