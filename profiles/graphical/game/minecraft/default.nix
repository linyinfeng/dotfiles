{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lunar-client
    polymc
    minecraft
  ];

  environment.global-persistence.user.directories = [
    ".minecraft"
    ".local/share/polymc"
    ".lunarclient"
    ".config/lunarclient"
  ];
}
