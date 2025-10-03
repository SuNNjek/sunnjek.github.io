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
      default =
        let 
          name = "sunnjek.github.io";
        in pkgs.stdenv.mkDerivation {
          inherit name;
          version = self.rev or self.dirtyRev;

          src = self;

          # Install modules in separate derivation so that the module install get access the internet
          # The hash also won't change here all too often
          modules = pkgs.stdenv.mkDerivation {
            name = "${name}-modules";
            src = self;

            nativeBuildInputs = with pkgs; [
              gitMinimal
              cacert
              hugo
              go
            ];

            configurePhase = ''
              export HUGO_CACHEDIR=$TMPDIR/hugo-cache
            '';

            buildPhase = ''
              hugo mod get
            '';

            installPhase = ''
              cp -r --reflink=auto $HUGO_CACHEDIR/modules/filecache/modules/pkg/mod/cache/download $out
            '';

            dontFixup = true;

            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = "sha256-0eJnYjEKl/nwayo902a6JApINDqfW38x0r4SyDXGlK8=";
          };

          nativeBuildInputs = with pkgs; [
            gitMinimal
            go
            hugo
          ];

          configurePhase = ''
            export HUGO_MODULE_PROXY="file://$modules"
          '';

          buildPhase = ''
            hugo build --minify -d public
          '';

          installPhase = ''
            cp -r --reflink=auto public $out
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