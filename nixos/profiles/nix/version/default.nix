{ pkgs, lib, ... }:
{
  nix.package = lib.mkDefault pkgs.nixVersions.latest;
}
