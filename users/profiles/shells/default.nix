{ config, pkgs, lib, nixosConfig, ... }:

{
  programs.fish.enable = true;
  programs.skim.enable = true;
  programs.zoxide.enable = true;

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
