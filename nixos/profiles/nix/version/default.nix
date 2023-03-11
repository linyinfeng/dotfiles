{pkgs, ...}: {
  nix.package = pkgs.nixVersions.selected;
}
