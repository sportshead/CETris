{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        version = "v0.8";
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "cetris";
          inherit version;

          src = ./.;

          nativeBuildInputs = [
            pkgs.spasm-ng
            pkgs.convbin
          ];

          buildPhase = ''
            runHook preBuild

            mkdir -p bin

            echo "Creating and building tests file"
            cat test.asm graphic.asm > test_full.asm
            spasm -E -T test_full.asm bin/TEST.8xp

            echo "Building tetrice_dat.asm"
            cat tetrice_dat.asm > cetrisdt.asm
            echo -e "versionString:\n .db \"${version}\",0\nversionStringEnd:\nversionStringSize = versionStringEnd-versionString" >> cetrisdt.asm
            spasm -E -T cetrisdt.asm bin/CETRISDT.8xp || true
            spasm -E -L cetrisdt.asm || true
            convbin -j 8x -k 8xv -i bin/CETRISDT.8xp -o bin/CETrisDT.8xv -n CETrisDT

            echo "Creating and building CETRIS"
            cat tetrice.asm graphic.asm > cetris.asm
            spasm -E -T -DMETA=${version} cetris.asm bin/CETRIS.8xp
            spasm -E -L cetris.asm
            spasm -E -T cetris.asm

            echo "Build artifacts:"
            ls -lh bin/CETRIS.8xp bin/CETrisDT.8xv

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out

            cp bin/CETRIS.8xp bin/CETrisDT.8xv $out
            cp bin/TEST.8xp $out || true

            runHook postInstall
          '';
        };
      }
    );
}
