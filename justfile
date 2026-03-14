# Run all checks in parallel (default recipe)
check:
    parallel --halt now,fail=1 ::: \
        'just fmt' \
        'just lint' \
        'just eval' \
        'just tea-lint' \
        'just tea-fmt-check'

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

# Run pytest on tea module
tea-test:
    pytest home/modules/tea/test_tea.py -v

# Auto-fix what's possible
fix:
    nixfmt **/*.nix
    statix fix .
    ruff format home/modules/tea/
    ruff check --fix home/modules/tea/
