{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    wget
    aria2
    rsync
    axel
  ];
}
