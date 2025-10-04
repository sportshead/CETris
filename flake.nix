{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version = "v0.8";
      in
      {
        packages = {
          # Derivation to build cetris
          cetris = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            pname = "cetris";
            inherit version;

            # Custom variable to control icons
            enableIcon = "TRUE";

            src = ./.;

            nativeBuildInputs = with pkgs; [
              spasm-ng
              convbin
            ];

            buildPhase = ''
              runHook preBuild

              mkdir bin

              # Run the repo build script with corresponding arguments
              ${./build.sh} ${version} ${finalAttrs.enableIcon}

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out

              cp bin/CETRIS.8xp bin/CETrisDT.8xv $out
              cp bin/TEST.8xp $out || true

              runHook postInstall
            '';
          });

          # Build cetris without an icon
          cetris_without_icon = self.packages.${system}.cetris.overrideAttrs {
            enableIcon = "";
          };

          # Set the default package to cetris with an icon
          default = self.packages.${system}.cetris;
        };

        formatter = pkgs.nixfmt;
      }
    );
}
