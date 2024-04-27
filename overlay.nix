final: prev: {
  workerd = prev.callPackage ./workerd.nix {};

  container-x86_64 = final.callPackage ./container.nix {
    inherit (final.pkgsCross.gnu64) bashInteractive;
    workerd = final.workerd.override {inherit (final.pkgsCross.gnu64) stdenvNoCC;};
  };

  container-aarch64 = final.callPackage ./container.nix {
    inherit (final.pkgsCross.aarch64-multiplatform) bashInteractive;
    workerd = final.workerd.override {inherit (final.pkgsCross.aarch64-multiplatform) stdenvNoCC;};
  };
}
