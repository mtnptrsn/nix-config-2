---
name: nix
description: Use this skill when the user asks to add, remove, or modify NixOS packages, system settings, or home-manager configuration. Activates for tasks involving Nix, NixOS, nixpkgs, flakes, home-manager, or system rebuilds.
---

# NixOS Configuration

This skill provides guidance for working with this multi-host flake-based NixOS configuration.

## Repository Structure

- **flake.nix** — Entry point with nixpkgs-unstable, home-manager, maccel, nixvim inputs
- **hosts/** — Per-host overrides (private/, work/) with default.nix and home.nix
- **system/** — System-level NixOS modules (boot, locale, desktop, audio, hardware, gaming, users)
- **home/** — Home Manager modules (nixvim, alacritty, zsh, tmux, gnome, packages, git)
- User account: mtnptrsn

## Determine Current Host

Run `hostname` to determine which host you are on (private or work).

## Where to Place Changes

### Adding/Removing Packages
- **User packages** go in `home/packages.nix`
- **Host-specific packages** go in `hosts/<host>/default.nix`
- **System packages** go in the relevant `system/*.nix` module
- Search nixpkgs for the correct attribute name when unsure

### Modifying System Configuration
- Identify the correct module in `system/` or `home/`
- Read the existing file before making changes
- Follow existing patterns and conventions in the codebase

### Modifying Home Manager Configuration
- Identify the correct module in `home/`
- For new program configs, consider whether they belong in an existing module or need a new one

## Applying Changes

After making configuration changes, run pre-commit checks:
```
nix run nixpkgs#nixfmt -- **/*.nix
nix run nixpkgs#statix -- check .
```
Fix any issues, then apply:
```
sudo nixos-rebuild switch --flake /home/mtnptrsn/nixos-config#<host>
```
Replace `<host>` with the hostname determined earlier.

## Guidelines
- Always read files before editing them
- Follow existing code patterns and formatting
- Use nixpkgs-unstable package names
- Remember `nixpkgs.config.allowUnfree = true` is set
- Do not modify hardware-configuration.nix
- Do not change system.stateVersion
