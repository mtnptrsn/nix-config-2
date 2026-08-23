{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.just
    pkgs.nixfmt
    pkgs.statix
    pkgs.ruff
    (pkgs.python3.withPackages (ps: [
      ps.pytest
      ps.typer
      # splitwise-mcp: httpx for the tests, fastmcp to run server.py by hand.
      ps.httpx
      ps.fastmcp
    ]))
  ];
}
