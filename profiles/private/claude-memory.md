# Host

This is the `private` host. When running NixOS rebuild or evaluating flake outputs, use `private` as the host name (e.g. `nixos-rebuild switch --flake ~/nixos-config#private`).

# Git

## Worktrees

- Always create a new worktree when starting a new task or feature.
- Use `git worktree add` to check out branches in separate directories instead of switching branches with `git checkout` or `git switch`.
