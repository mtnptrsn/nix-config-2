# nix-config

NixOS and nix-darwin desktop configuration using Nix flakes.

## Hosts

| Host | System | Platform |
| --- | --- | --- |
| `personal-desktop` | NixOS (GNOME) | x86_64-linux |
| `personal-macbook` | nix-darwin | aarch64-darwin |
| `office-macbook` | nix-darwin | aarch64-darwin |

## Installation

### Prerequisites

Install [Determinate Nix](https://github.com/DeterminateSystems/nix-installer):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

This gives you Nix with flakes enabled out of the box.

### NixOS (personal-desktop)

1. Copy your `hardware-configuration.nix` into the profile:

   ```bash
   cp /etc/nixos/hardware-configuration.nix profiles/personal/desktop/nixos/
   ```

2. Apply:

   ```bash
   sudo nixos-rebuild switch --flake .#personal-desktop
   ```

### macOS (personal-macbook / office-macbook)

1. Bootstrap nix-darwin (first time only):

   ```bash
   nix run nix-darwin -- switch --flake .#personal-macbook
   ```

2. For subsequent rebuilds:

   ```bash
   darwin-rebuild switch --flake .#personal-macbook
   ```
