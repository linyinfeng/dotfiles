{
  pkgs,
  lib,
  ...
}: {
  nix.package = lib.mkDefault pkgs.nixVersions.selected;
}
