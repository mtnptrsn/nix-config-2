# Run all checks (default recipe)
check:
    just fmt
    just lint
    just eval
    just tea-lint
    just tea-fmt-check
    just splitwise-lint
    just splitwise-fmt-check
    just splitwise-test
    just matchi-lint
    just matchi-fmt-check
    just matchi-test

# Format all nix files
fmt:
    nixfmt **/*.nix

# Run statix linter
lint:
    statix check .

# Evaluate all nixos configurations
eval:
    #!/usr/bin/env bash
    for cfg in $(nix eval --raw ".#nixosConfigurations" --apply 'x: builtins.concatStringsSep " " (builtins.attrNames x)'); do
        nix eval .#nixosConfigurations.$cfg.config.system.build.toplevel
    done

# Run ruff check on tea module
tea-lint:
    ruff check home/modules/tea/

# Format tea module
tea-fmt:
    ruff format home/modules/tea/

# Run ruff format check on tea module
tea-fmt-check:
    ruff format --check home/modules/tea/

# Build the garmin-mcp container image (nix does not build it; upstream is a
# git-only Python package). Run after bumping the pinned commit in its Dockerfile.
garmin-image:
    docker build -t garmin-mcp:local profiles/personal/desktop/nixos/garmin-mcp/

# Run ruff check on splitwise-mcp
splitwise-lint:
    ruff check profiles/personal/desktop/nixos/splitwise-mcp/

# Format splitwise-mcp
splitwise-fmt:
    ruff format profiles/personal/desktop/nixos/splitwise-mcp/

# Run ruff format check on splitwise-mcp
splitwise-fmt-check:
    ruff format --check profiles/personal/desktop/nixos/splitwise-mcp/

# Run pytest on splitwise-mcp
splitwise-test:
    pytest profiles/personal/desktop/nixos/splitwise-mcp/test_client.py -v

# Run ruff check on matchi-mcp
matchi-lint:
    ruff check profiles/personal/desktop/nixos/matchi-mcp/

# Format matchi-mcp
matchi-fmt:
    ruff format profiles/personal/desktop/nixos/matchi-mcp/

# Run ruff format check on matchi-mcp
matchi-fmt-check:
    ruff format --check profiles/personal/desktop/nixos/matchi-mcp/

# Run pytest on matchi-mcp
matchi-test:
    pytest profiles/personal/desktop/nixos/matchi-mcp/test_client.py -v

# Run pytest on tea module
tea-test:
    pytest home/modules/tea/test_tea.py -v

# Auto-fix what's possible
fix:
    nixfmt **/*.nix
    statix fix .
    ruff format home/modules/tea/
    ruff check --fix home/modules/tea/
    ruff format profiles/personal/desktop/nixos/splitwise-mcp/
    ruff check --fix profiles/personal/desktop/nixos/splitwise-mcp/
    ruff format profiles/personal/desktop/nixos/matchi-mcp/
    ruff check --fix profiles/personal/desktop/nixos/matchi-mcp/

# Print the profile name matching this machine
profile:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$(uname -s)" in
        Darwin) output=darwinConfigurations ;;
        Linux) output=nixosConfigurations ;;
        *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
    esac
    host=$(hostname -s)
    for cfg in $(nix eval --raw ".#$output" --apply 'x: builtins.concatStringsSep " " (builtins.attrNames x)'); do
        if [ "$(nix eval --raw ".#$output.$cfg.config.networking.hostName")" = "$host" ]; then
            echo "$cfg"
            exit 0
        fi
    done
    echo "no profile in $output has hostName '$host'" >&2
    exit 1

# Apply the configuration for this machine
apply:
    #!/usr/bin/env bash
    set -euo pipefail
    profile=$(just profile)
    echo "applying $profile"
    case "$(uname -s)" in
        Darwin) sudo -A darwin-rebuild switch --flake ".#$profile" ;;
        Linux) sudo -A nixos-rebuild switch --flake ".#$profile" ;;
    esac
