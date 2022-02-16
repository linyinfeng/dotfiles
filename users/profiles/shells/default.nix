{ config, pkgs, lib, ... }:

let
  cfg = config.home.global-persistence;
  sysCfg = config.passthrough.systemConfig.environment.global-persistence;
in
{
  programs.fish.enable = true;
  programs.skim.enable = true;
  programs.zoxide.enable = true;

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
