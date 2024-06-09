{ config, ... }:
{
  services.ace-bot = {
    enable = true;
    managerChatId = "148111617";
    tokenFile = config.sops.secrets."telegram-bot/ace-bot/token".path;
  };
  nix.settings.allowed-users = [ "ace-bot" ];
  sops.secrets."telegram-bot/ace-bot/token" = {
    sopsFile = config.sops-file.host;
  };
}
