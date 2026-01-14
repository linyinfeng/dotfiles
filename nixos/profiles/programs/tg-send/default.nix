{ config, ... }:
{
  programs.tg-send = {
    enable = true;
    tokenFile = config.sops.secrets."telegram_bot_push".path;
    extraOptions = [
      "--chat-id"
      "148111617"
    ];
  };
  users.groups.tg-send.gid = config.ids.gids.tg-send;
  sops.secrets."telegram_bot_push" = {
    predefined.enable = true;
    mode = "440";
    group = config.users.groups.tg-send.name;
  };
}
