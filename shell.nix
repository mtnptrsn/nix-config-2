{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.just
    pkgs.nixfmt
    pkgs.statix
    pkgs.ruff
    pkgs.parallel
    (pkgs.python3.withPackages (ps: [
      ps.pytest
      ps.typer
    ]))
  ];
}
