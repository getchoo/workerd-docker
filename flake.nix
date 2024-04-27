{
  description = "workerd...but in a cool docker container!";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    forAllSystems = fn: nixpkgs.lib.genAttrs systems (system: fn nixpkgs.legacyPackages.${system});
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (
      pkgs: let
        pkgs' = import ./. {
          nixpkgs = pkgs;
          inherit (pkgs.stdenv.hostPlatform) system;
        };
      in
        pkgs' // {default = pkgs'.workerd;}
    );

    overlays.default = final: prev: import ./overlay.nix final prev;
  };
}
