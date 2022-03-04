{ pkgs, config, ... }:

{
  programs.telegram-send = {
    enable = true;
    configFile = config.sops.secrets."telegram-bot/push".path;
  };

  sops.secrets."telegram-bot/push" = {
    mode = "440";
    group = config.users.groups.wheel.name;
    sopsFile = config.sops.secretsDir + /common.yaml;
  };
}
