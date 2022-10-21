{ config, pkgs, lib, ... }:

lib.mkIf config.home.graphical {
  home.packages = with pkgs; [
    lunar-client
    minecraft
  ];

  home.global-persistence.directories = [
    ".minecraft"
    ".lunarclient"
    ".config/lunarclient"
  ];
}
