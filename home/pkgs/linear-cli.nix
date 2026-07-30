{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "2.2.0";

  # Prebuilt, Deno-compiled binaries published per release. Keyed by Nix
  # system; `triple` is the Rust/Deno target used in the asset name.
  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-VkDDqAypDhQYAJrswtSQ7hNZ0tzW3w8ZogIqzktsAEc=";
    };
    x86_64-darwin = {
      triple = "x86_64-apple-darwin";
      hash = "sha256-JC0AhGLQhapj3r4K3Ny36GfyWQGgYFx0AI1A3LvVH7o=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      hash = "sha256-VUNeUhypt9L6uve4XEOmDBNqjwg617e0qTzkdAPTbvM=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      hash = "sha256-UKq5/G6IBR5fAur9cbMSfOesUHDXAXV2ScMnipXkhdo=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "linear-cli: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "linear-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-${target.triple}.tar.xz";
    inherit (target) hash;
  };

  sourceRoot = "linear-${target.triple}";

  nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.isLinux [ stdenv.cc.cc.lib ]; # libgcc_s

  installPhase = ''
    runHook preInstall
    install -Dm755 linear -t $out/bin
    runHook postInstall
  '';

  meta = {
    description = "linear without leaving the command line: list, start, and create PRs for linear issues";
    homepage = "https://github.com/schpet/linear-cli";
    license = lib.licenses.mit;
    mainProgram = "linear";
    platforms = builtins.attrNames targets;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
