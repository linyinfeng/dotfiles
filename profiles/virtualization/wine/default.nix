{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    wineWowPackages.staging
    winetricks
  ];
}
