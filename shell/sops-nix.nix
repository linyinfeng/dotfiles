{ pkgs, ... }:
let
  pkgWithCategory = category: package: { inherit package category; };
in
{
  commands = map (pkgWithCategory "sops") (with pkgs; [
    sops
    # sops-ssh-to-age # broken
  ]);
}
