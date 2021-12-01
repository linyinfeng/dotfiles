{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lunar-client
    multimc
    minecraft
  ];

  environment.global-persistence.user.directories = [
    ".minecraft"
    ".local/share/multimc"
    ".lunarclient"
    ".config/lunarclient"
  ];
}
