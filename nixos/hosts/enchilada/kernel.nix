{
  lib,
  pkgs,
  ...
}: {
  mobile.boot.stage-1.kernel.package = lib.mkForce (pkgs.callPackage ./kernel {});
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      mobile-nixos =
        prev.mobile-nixos
        // {
          kernel-builder = prev.mobile-nixos.kernel-builder.override {
            stdenv = pkgs.ccacheStdenv;
          };
        };
    })
  ];
}
