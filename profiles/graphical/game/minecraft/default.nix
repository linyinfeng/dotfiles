{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lunar-client
    minecraft
  ];

  environment.global-persistence.user.directories = [
    ".minecraft"
    ".lunarclient"
    ".config/lunarclient"
  ];
}
