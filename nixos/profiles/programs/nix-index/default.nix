{ pkgs, lib, ... }:
{
  programs.nix-index = {
    enable = pkgs ? nix-index-with-db;
    package = pkgs.nix-index-with-db;
  };
  programs.command-not-found.enable = lib.mkDefault false;
}
