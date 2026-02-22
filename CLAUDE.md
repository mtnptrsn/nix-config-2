# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS desktop configuration using Nix flakes. Hosts: `personal-desktop` (GNOME on x86_64-linux) and `personal-macbook` (aarch64-darwin). Uses nixpkgs-unstable.

## Architecture

- **flake.nix** — Entry point. Inputs: nixpkgs-unstable, home-manager, nix-darwin, nix-homebrew, maccel, nixvim. Defines `mkHost` and `mkDarwinHost` helpers that assemble shared modules per host. Outputs: `nixosConfigurations.personal-desktop`, `darwinConfigurations.personal-macbook`.
- **profiles/** — Per-host overrides in a nested `<category>/<device>/` structure (e.g., `personal/desktop/`, `personal/macbook/`). Each contains a `default.nix` (hostname, system-level overrides) and a `home.nix` (enables home-manager modules + per-host user config).
- **nixos/** — System-level config via NixOS modules. `default.nix` is the entry point (networking, nixpkgs config, nix settings, stateVersion). Submodules: `boot.nix`, `locale.nix`, `desktop.nix`, `audio.nix`, `hardware.nix`, `users.nix`.
- **home/** — User-level config via Home Manager. `default.nix` imports all opt-in modules and sets stateVersion. Modules in `home/modules/` use `modules.<name>.enable` with `mkEnableOption`/`mkIf` so profiles control what's active.
- **home/modules/** — Opt-in home-manager modules: `nixvim.nix`, `alacritty.nix`, `zsh.nix`, `tmux.nix`, `gnome.nix`, `git.nix`, `packages.nix`, `firefox.nix`, `dictation.nix`.

## Scripts

The `cw` command (defined in `home/scripts/cw.sh`, registered in `home/modules/packages.nix`) provides worktree-related subcommands. Run `cw help` for usage.

## Key Details

- User account: `mtnptrsn` (wheel, networkmanager groups)
- Desktop: GNOME with GDM, X11
- Audio: PipeWire (with PulseAudio/ALSA compat)
- Locale: en_US.UTF-8 default, Swedish (sv_SE.UTF-8) for LC_* categories
- Keyboard: Swedish layout (`se`)
- `nixpkgs.config.allowUnfree = true`
- `system.stateVersion = "25.11"` — do not change without understanding migration implications

## Workflow

- Always apply configuration changes after editing by running `sudo nixos-rebuild switch --flake .#<host>` (replace `<host>` with the target host name)

## Pre-commit Checks

Skip these checks if the `nix` binary is not available (e.g., in cloud environments).

Before committing, always run the formatter, linter, and eval in parallel:

```bash
parallel --halt now,fail=1 ::: \
  'nixfmt **/*.nix' \
  'statix check .' \
  'nix eval .#nixosConfigurations.personal-desktop.config.system.build.toplevel'
```

Fix any issues before committing. For statix, auto-fix is available with `statix fix .`.

## Git

- Do not add `Co-Authored-By` lines to commit messages
- When committing, separate changes into distinct commits by concern. Group related changes together and keep unrelated changes in separate commits.
- Do not use the GitHub CLI (`gh`) in cloud environments — git push/pull and PR creation are handled automatically by the cloud integration. Only use `gh` when it is available locally.
