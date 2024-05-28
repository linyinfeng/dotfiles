{ lib, pkgs, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      mobile-nixos = prev.mobile-nixos // {
        kernel-builder = prev.mobile-nixos.kernel-builder.override { stdenv = pkgs.ccacheStdenv; };
      };
    })
  ];
}
