# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-machine NixOS desktop configuration using Nix flakes. Two hosts (`private`, `work`) sharing a common base config, running GNOME on x86_64-linux with nixpkgs-unstable.

## Architecture

- **flake.nix** — Entry point. Inputs: nixpkgs-unstable, home-manager, maccel, nixvim. Defines a `mkHost` helper that assembles shared modules (system, profile, home-manager) per host. Outputs: `nixosConfigurations.private` and `nixosConfigurations.work`.
- **profiles/** — Per-host overrides. Each subdirectory (`private/`, `work/`) contains a `default.nix` (hostname, system-level overrides, hardware-configuration import) and a `home.nix` (enables home-manager modules + per-host user config).
- **system/** — System-level config via NixOS modules. `default.nix` is the entry point (networking, nixpkgs config, nix settings, stateVersion). Submodules: `boot.nix`, `locale.nix`, `desktop.nix`, `audio.nix`, `hardware.nix`, `gaming.nix`, `users.nix`.
- **home/** — User-level config via Home Manager. `default.nix` imports all opt-in modules and sets stateVersion. Modules in `home/modules/` use `modules.<name>.enable` with `mkEnableOption`/`mkIf` so profiles control what's active.
- **home/modules/** — Opt-in home-manager modules: `nixvim.nix`, `alacritty.nix`, `zsh.nix`, `tmux.nix`, `gnome.nix`, `git.nix`, `packages.nix`.

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

- Always apply configuration changes after editing by running `sudo nixos-rebuild switch --flake /home/mtnptrsn/nixos-config#<host>` (replace `<host>` with the target host name)

## Pre-commit Checks

Skip these checks if the `nix` binary is not available (e.g., in cloud environments).

Before committing, always run the formatter, linter, and eval in parallel:

```bash
# Format all .nix files
nix run nixpkgs#nixfmt -- **/*.nix

# Lint all .nix files (check only)
nix run nixpkgs#statix -- check .

# Verify config evaluates (check all hosts)
nix eval /home/mtnptrsn/nixos-config#nixosConfigurations.private.config.system.build.toplevel
nix eval /home/mtnptrsn/nixos-config#nixosConfigurations.work.config.system.build.toplevel
```

Fix any issues before committing. For statix, auto-fix is available with `nix run nixpkgs#statix -- fix .`.

## Git

- Do not add `Co-Authored-By` lines to commit messages
- When committing, separate changes into distinct commits by concern. Group related changes together and keep unrelated changes in separate commits.
- Do not use the GitHub CLI (`gh`) in cloud environments — git push/pull and PR creation are handled automatically by the cloud integration. Only use `gh` when it is available locally.
