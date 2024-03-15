{ config, pkgs, ... }:
{
  programs.tg-send = {
    enable = true;
    tokenFile = config.sops.secrets."telegram-bot/push".path;
    extraOptions = [
      "--chat-id"
      "148111617"
    ];
  };
  users.groups.tg-send.gid = config.ids.gids.tg-send;
  sops.secrets."telegram-bot/push" = {
    mode = "440";
    group = config.users.groups.tg-send.name;
    sopsFile = config.sops-file.get "common.yaml";
  };
}
