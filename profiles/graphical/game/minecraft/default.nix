{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lunar-client
    # TODO https://github.com/NixOS/nixpkgs/pull/196476
    # OVE-20221017-0001
    # polymc
    minecraft
  ];

  environment.global-persistence.user.directories = [
    ".minecraft"
    ".local/share/polymc"
    ".lunarclient"
    ".config/lunarclient"
  ];
}
