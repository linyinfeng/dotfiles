{ config, pkgs, ... }:

{
  programs.telegram-send = {
    enable = true;
    configFile = config.sops.secrets."telegram-bot/push".path;
  };
  users.groups.telegram-send.gid = config.ids.gids.telegram-send;
  sops.secrets."telegram-bot/push" = {
    mode = "440";
    group = config.users.groups.telegram-send.name;
    sopsFile = config.sops.getSopsFile "common.yaml";
  };
}
