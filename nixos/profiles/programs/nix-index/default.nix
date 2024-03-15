{ pkgs, lib, ... }:
{
  programs.nix-index = {
    enable = true;
    package = pkgs.nix-index-with-db;
  };
  programs.command-not-found.enable = lib.mkDefault false;
}
