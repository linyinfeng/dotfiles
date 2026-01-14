{ config, ... }:
{
  services.commit-notifier = {
    enable = true;
    cron = "0 * * * * *";
    adminChatId = "-1001796151421";
    tokenFiles = {
      telegramBot = config.sops.secrets."telegram_bot_commit_notifier".path;
      github = config.sops.secrets."github_token_nano".path;
    };
  };
  systemd.services.commit-notifier.serviceConfig.LimitNOFILE = 65535;
  sops.secrets."telegram_bot_commit_notifier" = {
    predefined.enable = true;
    restartUnits = [ "commit-notifier.service" ];
  };
  sops.secrets."github_token_nano" = {
    predefined.enable = true;
    restartUnits = [ "commit-notifier.service" ];
  };
}
