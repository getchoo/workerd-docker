{
  description = "worked...but in a cool docker container!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      });

    forEachSystem = fn:
      forAllSystems (system:
        fn {
          inherit system;
          pkgs = nixpkgsFor.${system};
        });
  in {
    formatter = forEachSystem ({pkgs, ...}: pkgs.alejandra);

    packages = forEachSystem ({pkgs, ...}: {
      inherit (pkgs) workerd workerd-docker;
      default = pkgs.workerd-docker;
    });

    overlays.default = final: prev: {
      workerd = let
        inherit (prev) fetchurl llvmPackages stdenv system;
        inherit (prev.lib) makeLibraryPath optionalAttrs;
      in
        stdenv.mkDerivation rec {
          pname = "workerd";
          version = "1.20230628.0";
          src =
            optionalAttrs (system
              == "x86_64-linux") (fetchurl {
              url = "https://github.com/cloudflare/workerd/releases/download/v${version}/workerd-linux-64.gz";
              hash = "sha256-McY39ud6NHgUM8QN8kXO73oLvTcv+zm35xxkWxvOvHA=";
            })
            // optionalAttrs (system == "aarch64-linux") (fetchurl {
              url = "https://github.com/cloudflare/workerd/releases/download/v${version}/workerd-linux-arm64.gz";
              hash = "sha256-/UA49cbyjqzE82sxpPnVBVT+gd6VA5dDkcpRS7FZjc8=";
            });

          buildInputs = [llvmPackages.libcxx llvmPackages.libunwind];

          unpackPhase = ":";

          installPhase = ''
            mkdir -p $out/bin
            cp ${src} workerd.gz
            gzip -d workerd.gz
            install -Dm755 workerd $out/bin/workerd
          '';

          preFixup = let
            libPath = makeLibraryPath [
              llvmPackages.libcxx
              llvmPackages.libunwind
            ];
          in ''
            patchelf \
            	--set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
            	--set-rpath ${libPath} \
            	$out/bin/workerd
          '';
        };

      workerd-docker = let
        inherit (prev) dockerTools;
        env = prev.buildEnv {
          name = "image-root";
          paths = [dockerTools.binSh final.workerd];
          pathsToLink = ["/bin" "/etc"];
        };
      in
        dockerTools.buildLayeredImage {
          name = final.workerd.pname;
          tag = "latest";
          contents = [
            env
            dockerTools.caCertificates
          ];
          config.Cmd = ["${final.workerd}/bin/workerd"];
        };
    };
  };
}
