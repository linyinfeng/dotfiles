{ pkgs, lib, ... }:
{
  #        default = 1000
  #   this default = 1250
  # option default = 1500
  boot.kernelPackages = lib.mkOverride 1250 pkgs.linuxPackages_latest;
}
