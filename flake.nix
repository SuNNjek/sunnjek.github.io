{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    allSystems = builtins.attrNames nixpkgs.legacyPackages;

    forAllSystems = (f:
      nixpkgs.lib.genAttrs allSystems (system:
        f nixpkgs.legacyPackages.${system}
      )
    );
  in {
    packages = forAllSystems (pkgs: {
      default = pkgs.stdenv.mkDerivation {
        name = "sunnjek.github.io";
        version = self.rev or self.dirtyRev;

        src = self;

        buildInputs = [pkgs.hugo];

        buildPhase = ''
          hugo build -d public
        '';

        installPhase = ''
          cp -R public $out
        '';
      };
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          hugo
          go
        ];
      };
    });
  };
}