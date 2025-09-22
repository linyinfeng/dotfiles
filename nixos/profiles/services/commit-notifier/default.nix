{ config, ... }:
{
  services.commit-notifier = {
    enable = true;
    cron = "0 * * * * *";
    adminChatId = "-1001796151421";
    tokenFiles = {
      telegramBot = config.sops.secrets."telegram-bot/commit-notifier".path;
      github = config.sops.secrets."nano/github-token".path;
    };
  };
  sops.secrets."telegram-bot/commit-notifier" = {
    sopsFile = config.sops-file.host;
    restartUnits = [ "commit-notifier.service" ];
  };
  sops.secrets."nano/github-token" = {
    sopsFile = config.sops-file.get "common.yaml";
    restartUnits = [ "commit-notifier.service" ];
  };
}
