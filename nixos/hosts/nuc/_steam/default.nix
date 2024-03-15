{
  suites,
  config,
  pkgs,
  ...
}:
let
  gameHome = "/home/steam";
in
{
  imports = suites.games ++ [ ./palworld ];
  programs.steam.hidpi = {
    enable = true;
    scale = "2";
  };

  programs.steam.enable = true;

  # don't starve togather
  users.users.steam = {
    uid = config.ids.uids.steam;
    isSystemUser = true;
    createHome = true;
    home = gameHome;
    group = "steam";
    # for debug
    shell = pkgs.bash;
  };
  users.groups.steam = {
    gid = config.ids.gids.steam;
  };
  environment.global-persistence.user.users = [ "steam" ];
  home-manager.users.steam = {
    home.global-persistence = {
      enable = true;
      home = gameHome;
    };
    home.global-persistence.directories = [ "Steam" ];
    home.packages = with pkgs; [
      steamcmd
      steam-run
    ];
  };
  nix.settings.allowed-users = [ "steam" ];
}
