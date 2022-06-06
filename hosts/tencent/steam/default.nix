{ config, pkgs, ... }:

let
  gameHome = "/home/steam";
in
{
  imports = [
    ./dst
  ];

  programs.steam.enable = true;

  # don't starve togather
  users.users.steam = {
    isSystemUser = true;
    createHome = true;
    home = gameHome;
    group = "steam";
    # for debug
    shell = pkgs.bash;
  };
  users.groups.steam = { };
  environment.global-persistence.user.users = [ "steam" ];
  home-manager.users.steam = {
    passthrough.systemConfig = config;
    home.global-persistence = {
      enable = true;
      home = gameHome;
    };
    home.global-persistence.directories = [
      ".steam"
      ".local/share/Steam"
      "Steam"
    ];
  };
  nix.settings.allowed-users = [ "steam" ];
}
