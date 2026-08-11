{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  binutils,
  patchelf,
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

  libPath = lib.makeLibraryPath [ stdenv.cc.cc.lib ]; # libgcc_s
in
stdenvNoCC.mkDerivation {
  pname = "linear-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-${target.triple}.tar.xz";
    inherit (target) hash;
  };

  sourceRoot = "linear-${target.triple}";

  nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [
    binutils
    patchelf
  ];

  # Deno appends its bundle after the ELF image and locates it by seeking back
  # from EOF. Anything that adds bytes at the end (patchelf's relocated section
  # headers) or rewrites the file (strip) makes the binary die with "Could not
  # find standalone binary section", so both hooks stay off and we patch the
  # ELF part by hand below.
  dontStrip = true;
  dontPatchELF = true;

  installPhase =
    ''
      runHook preInstall
    ''
    + lib.optionalString stdenvNoCC.isLinux ''
      # Split off the ELF image (everything up to the end of the section header
      # table), patch just that, then glue the Deno bundle back on. The bundle
      # is found relative to EOF, so growing the ELF part is harmless.
      elfEnd=$(readelf -h linear | awk '
        /Start of section headers/ { off = $5 }
        /Size of section headers/ { size = $5 }
        /Number of section headers/ { num = $5 }
        END { print off + size * num }
      ')

      head -c "$elfEnd" linear > stub
      tail -c "+$((elfEnd + 1))" linear > bundle

      patchelf \
        --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
        --set-rpath ${libPath} \
        stub

      cat stub bundle > linear.patched
      mv linear.patched linear
    ''
    + ''
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
