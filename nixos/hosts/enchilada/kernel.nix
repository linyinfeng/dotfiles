{ lib, pkgs, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (_final: prev: {
      mobile-nixos = prev.mobile-nixos // {
        kernel-builder = prev.mobile-nixos.kernel-builder.override { stdenv = pkgs.ccacheStdenv; };
      };
    })
  ];
}
